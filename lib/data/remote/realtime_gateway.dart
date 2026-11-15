import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../local/token_storage.dart';

/// A decoded realtime frame from `/api/realtime`.
class RealtimeEvent {
  const RealtimeEvent({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;

  int? get childId => data['childId'] is int ? data['childId'] as int : null;

  static RealtimeEvent? fromMessage(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      final type = decoded['type'];
      if (type is! String || type.isEmpty) return null;
      final body = decoded['data'];
      return RealtimeEvent(
        type: type,
        data: body is Map<String, dynamic> ? body : decoded,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Owns the WebSocket connection to the portal's realtime feed.
///
/// Reconnects with exponential backoff (500ms * 2^n, capped like the portal),
/// emits parsed [RealtimeEvent]s on a broadcast stream, and sends periodic
/// `ping` frames so the server returns `pong` keepalives.
class RealtimeGateway {
  RealtimeGateway(
    this._tokenStorage, {
    Uri Function(String token)? uriForToken,
    this.receiveTimeout = const Duration(seconds: 45),
    this.connectTimeout = const Duration(seconds: 15),
  }) : _uriForToken =
           uriForToken ?? ((token) => Uri.parse(AppConfig.realtimeUrl(token)));

  final Uri Function(String) _uriForToken;
  final Duration receiveTimeout, connectTimeout;

  static const Duration _pingInterval = Duration(seconds: 25);

  final TokenStorage _tokenStorage;

  final _controller = StreamController<RealtimeEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _receiveTimer;
  int _reconnectAttempts = 0;
  int _epoch = 0;
  bool _connected = false;
  bool _disposed = false;
  bool _shouldReconnect = false;

  /// Newest event stream. Safe to listen from multiple places.
  Stream<RealtimeEvent> get stream => _controller.stream;

  bool get isConnected => _connected;

  /// Connects (or reconnects) using the stored parent JWT.
  Future<void> connect() async {
    final epoch = ++_epoch;
    String? token;
    try {
      token = await _tokenStorage.readToken();
    } catch (_) {
      return;
    }
    if (_disposed || epoch != _epoch) return;
    if (token == null || token.isEmpty) {
      disconnect();
      return;
    }
    _reconnectTimer?.cancel();
    _shouldReconnect = true;
    _open(token);
  }

  void _open(String token) {
    _teardownSocket();

    final channel = WebSocketChannel.connect(_uriForToken(token));
    _channel = channel;
    unawaited(
      channel.ready
          .timeout(connectTimeout)
          .then(
            (_) {
              if (identical(_channel, channel)) {
                _connected = true;
                _armReceiveTimeout();
              }
            },
            onError: (_) {
              if (identical(_channel, channel)) _onDisconnect();
            },
          ),
    );

    _socketSubscription = channel.stream.listen(
      (message) {
        if (identical(_channel, channel)) _onData(message);
      },
      onError: (_) {
        if (identical(_channel, channel)) _onDisconnect();
      },
      onDone: () {
        if (identical(_channel, channel)) _onDisconnect();
      },
      cancelOnError: true,
    );

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (isConnected) {
        try {
          channel.sink.add('ping');
        } catch (_) {
          _onDisconnect();
        }
      }
    });
  }

  void _onData(dynamic message) {
    if (message is! String) return;
    final event = RealtimeEvent.fromMessage(message);
    if (event != null && !_controller.isClosed) {
      _reconnectAttempts = 0;
      _armReceiveTimeout();
      _controller.add(event);
    }
  }

  void _armReceiveTimeout() {
    _receiveTimer?.cancel();
    _receiveTimer = Timer(receiveTimeout, _onDisconnect);
  }

  void _onDisconnect() {
    _teardownSocket();
    if (!_shouldReconnect || _disposed) return;

    final delayMs = (500 * (1 << _reconnectAttempts)).clamp(500, 64000);
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(0, 7);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      final epoch = _epoch;
      _tokenStorage.readToken().then(
        (token) {
          if (token != null &&
              token.isNotEmpty &&
              _shouldReconnect &&
              !_disposed &&
              epoch == _epoch) {
            _open(token);
          }
        },
        onError: (_) {
          if (_shouldReconnect && !_disposed && epoch == _epoch) {
            _onDisconnect();
          }
        },
      );
    });
  }

  void _teardownSocket() {
    _connected = false;
    _receiveTimer?.cancel();
    _receiveTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        channel.sink.close();
      } catch (_) {
        // Ignore: socket already gone.
      }
    }
  }

  /// Stops reconnecting and closes the socket (e.g. on logout).
  void disconnect() {
    _epoch++;
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _teardownSocket();
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }
}
