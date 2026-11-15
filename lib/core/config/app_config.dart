/// Runtime configuration for the mobile app.
///
/// The API base URL is injected at compile time via
/// `--dart-define=API_BASE_URL=https://your-server.example`.
/// The default uses the shared public HTTPS backend.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://joinus.akashdreamer.uk',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String appVersion = '1.0.0';

  /// Converts the HTTP base URL to its WebSocket equivalent and appends the
  /// realtime endpoint with the supplied token in the query string.
  static String realtimeUrl(String token) {
    return realtimeUri(apiBaseUrl, token).toString();
  }

  static Uri realtimeUri(String base, String token) {
    final uri = Uri.parse(base);
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Use a valid HTTP or HTTPS server address.');
    }
    return uri.replace(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/realtime',
      queryParameters: {'token': token},
    );
  }
}
