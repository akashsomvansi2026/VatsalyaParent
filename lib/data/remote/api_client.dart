import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../models/api_response.dart';

/// Typed HTTP client for the Vrajrani Tech Solution API.
///
/// - Attaches the parent JWT as `Authorization: Bearer` when available.
/// - Converts transport/server failures into user-friendly [AppException]s.
/// - On a 401 while a token was attached, invokes [onUnauthorized] so the
///   session can be cleared (matching portal auto-logout on expired session).
class ApiClient {
  ApiClient({
    required this.tokenProvider,
    required this.onUnauthorized,
    this.sessionRevision,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConfig.apiBaseUrl,
               connectTimeout: AppConfig.connectTimeout,
               receiveTimeout: AppConfig.receiveTimeout,
               headers: const {'Content-Type': 'application/json'},
             ),
           );

  final Future<String?> Function() tokenProvider;
  final void Function() onUnauthorized;
  final Dio _dio;
  final int Function()? sessionRevision;
  String? _installedAppVersion;
  void setInstalledAppVersion(String version) => _installedAppVersion = version;

  /// Public update metadata never carries the parent's credentials or changes session state.
  Future<Map<String, dynamic>> getPublicObject(
    String url, {
    required Map<String, dynamic> query,
  }) async {
    final response = await _dio
        .get<Object?>(
          url,
          queryParameters: query,
          options: Options(
            headers: {'Authorization': null},
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            followRedirects: false,
          ),
        )
        .timeout(const Duration(seconds: 12));
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid update response');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getObject(String path) async {
    final options = await _authOptions('GET');
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: options,
      );
      await _ensureSession(options);
      return response.data ?? {};
    } on DioException catch (error) {
      throw _mapDioError(error, options);
    }
  }

  Future<Map<String, dynamic>> sendObject(
    String path,
    Object? data, {
    String method = 'POST',
  }) async {
    final options = await _authOptions(method);
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        options: options,
      );
      await _ensureSession(options);
      return response.data ?? {};
    } on DioException catch (error) {
      throw _mapDioError(error, options);
    }
  }

  Future<void> _ensureSession(Options options) async {
    if (options.extra?['revision'] != sessionRevision?.call()) {
      throw const AppException('Account changed. Please retry.');
    }
    final sent = options.headers?['Authorization'];
    if (sent != null && sent != 'Bearer ${await tokenProvider()}') {
      throw const AppException('Account changed. Please retry.');
    }
  }

  Future<Options> _authOptions(String method) async {
    final revision = sessionRevision?.call();
    final token = await tokenProvider();
    if (revision != sessionRevision?.call()) {
      throw const AppException('Account changed. Please retry.');
    }
    return Options(
      method: method,
      extra: {'revision': revision},
      headers: {
        'X-App-Version': ?_installedAppVersion,
        if (_installedAppVersion != null) 'X-App-Platform': 'android',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  /// Enveloped POST returning the parsed envelope.
  Future<ApiResponse<T>> postEnveloped<T>(
    String path,
    Object? data, {
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    final options = await _authOptions('POST');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: options,
      );
      await _ensureSession(options);
      return ApiResponse.fromJson(
        response.data ?? const {},
        dataParser: dataParser,
      );
    } on DioException catch (error) {
      throw _mapDioError(error, options);
    }
  }

  /// Enveloped POST returning only the envelope (success confirmation).
  Future<ApiResponse<void>> postConfirm(String path, Object? data) async {
    final options = await _authOptions('POST');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: options,
      );
      await _ensureSession(options);
      return ApiResponse<void>.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw _mapDioError(error, options);
    }
  }

  /// Raw POST returning a plain map (used by login).
  Future<Map<String, dynamic>> postRaw(String path, Object? data) async {
    final options = await _authOptions('POST');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: options,
      );
      await _ensureSession(options);
      return response.data ?? const {};
    } on DioException catch (error) {
      throw _mapDioError(error, options);
    }
  }

  /// GET returning a raw list (parent listing endpoints are non-enveloped).
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final options = await _authOptions('GET');
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: query,
        options: options,
      );
      await _ensureSession(options);
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (error) {
      throw _mapDioError(error, options);
    }
  }

  /// DELETE (returns 200 enveloped or a raw body depending on endpoint).
  Future<void> delete(String path) async {
    final options = await _authOptions('DELETE');
    try {
      await _dio.delete<dynamic>(path, options: options);
    } on DioException catch (error) {
      throw _mapDioError(error, options);
    }
  }

  AppException _mapDioError(DioException error, Options options) {
    final hadToken =
        (options.headers?['Authorization'] as String?)?.isNotEmpty ?? false;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AppException(
          'Connection timed out. Please check your network and try again.',
          isNetwork: true,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
        return const AppException(
          'Network error. Check your connection and try again.',
          isNetwork: true,
        );
      case DioExceptionType.cancel:
        return const AppException('Request was cancelled.');
      case DioExceptionType.badResponse:
        break;
      case DioExceptionType.unknown:
        return const AppException('Something went wrong. Please try again.');
    }

    final response = error.response;
    final status = response?.statusCode ?? 0;

    if (status == 401 &&
        hadToken &&
        options.extra?['revision'] == sessionRevision?.call()) {
      onUnauthorized();
      return const AppException(
        'Session expired. Please sign in again.',
        statusCode: 401,
        isUnauthorized: true,
      );
    }

    final message = _extractMessage(response?.data);
    return AppException(
      message ?? 'Server error ($status). Please try again.',
      statusCode: status,
      isUnauthorized: status == 401,
    );
  }

  static String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}
