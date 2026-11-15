import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// Uses a separate client so APK requests never inherit account credentials.
class ApkUpdater {
  ApkUpdater({Dio? dio, MethodChannel? channel})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 45),
              followRedirects: false,
            ),
          ),
      _channel = channel ?? const MethodChannel('vatsalya/app_update');

  final Dio _dio;
  final MethodChannel _channel;
  CancelToken? _cancel;
  String? _readyUrl;

  Future<void> download(Uri uri, void Function(int, int) progress) async {
    if (_readyUrl == uri.toString()) return;
    _readyUrl = null;
    final token = CancelToken();
    _cancel = token;
    try {
      final path = await _channel.invokeMethod<String>('prepare');
      if (path == null) throw StateError('No update directory');
      await _dio.download(
        uri.toString(),
        path,
        cancelToken: token,
        deleteOnError: true,
        options: Options(followRedirects: false),
        onReceiveProgress: (received, total) {
          if (received > 300 * 1024 * 1024 || total > 300 * 1024 * 1024) {
            token.cancel('Update exceeds 300 MB');
          } else {
            progress(received, total);
          }
        },
      );
      await _channel.invokeMethod<void>('validate');
      _readyUrl = uri.toString();
    } finally {
      _cancel = null;
    }
  }

  /// Returns false when Android's install-source Settings screen was opened.
  Future<bool> install() async =>
      await _channel.invokeMethod<bool>('install') ?? false;

  void cancel() => _cancel?.cancel('Cancelled');
}
