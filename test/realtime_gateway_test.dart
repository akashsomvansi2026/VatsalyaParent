import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/data/local/token_storage.dart';
import 'package:vrajrani_tech_solution/data/remote/realtime_gateway.dart';

class MemoryToken extends TokenStorage {
  String? token = 'test-parent-token';
  @override
  Future<String?> readToken() async => token;
}

Future<void> until(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 4));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(ready(), isTrue);
}

void main() {
  test(
    'silent socket times out, reconnects with frames, and stays stopped after disconnect',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <WebSocket>[];
      final timers = <Timer>[];
      final tokens = MemoryToken();
      final events = <RealtimeEvent>[];
      final gateway = RealtimeGateway(
        tokens,
        uriForToken: (_) =>
            Uri.parse('ws://127.0.0.1:${server.port}/api/realtime'),
        receiveTimeout: const Duration(milliseconds: 150),
      );
      final subscription = gateway.stream.listen(events.add);
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        sockets.add(socket);
        socket.listen((_) {});
        if (sockets.length > 1) {
          socket.add('{"type":"child_updated","data":{"childId":1}}');
          timers.add(
            Timer.periodic(const Duration(milliseconds: 25), (_) {
              if (socket.readyState == WebSocket.open) {
                socket.add('{"type":"pong"}');
              }
            }),
          );
        }
      });
      addTearDown(() async {
        gateway.dispose();
        for (final timer in timers) {
          timer.cancel();
        }
        for (final socket in sockets) {
          await socket.close();
        }
        await subscription.cancel();
        await server.close(force: true);
      });
      await gateway.connect();
      await until(() => sockets.length == 1 && gateway.isConnected);
      await until(() => !gateway.isConnected);
      await until(
        () =>
            sockets.length >= 2 && events.any((e) => e.type == 'child_updated'),
      );
      expect(gateway.isConnected, isTrue);
      gateway.disconnect();
      final count = sockets.length;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(gateway.isConnected, isFalse);
      expect(sockets.length, count);
    },
  );
  test(
    'stalled handshake times out; clearing the token stops reconnect',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = <HttpRequest>[];
      final tokens = MemoryToken();
      final gateway = RealtimeGateway(
        tokens,
        uriForToken: (_) =>
            Uri.parse('ws://127.0.0.1:${server.port}/api/realtime'),
        connectTimeout: const Duration(milliseconds: 80),
      );
      server.listen(requests.add);
      addTearDown(() async {
        gateway.dispose();
        for (final request in requests) {
          await request.response.close();
        }
        await server.close(force: true);
      });
      await gateway.connect();
      await until(() => requests.isNotEmpty);
      tokens.token = null;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(gateway.isConnected, isFalse);
      expect(requests, hasLength(1));
    },
  );
}
