import '../../core/errors/app_exception.dart';
import '../local/token_storage.dart';
import '../models/login_response.dart';
import '../remote/api_client.dart';
import '../remote/api_endpoints.dart';

/// Authentication boundary for the parent mobile app.
///
/// Mirrors the portal's login: trim + lowercase the email, POST to
/// `/api/auth/login`, and persist the returned JWT securely.
class AuthRepository {
  AuthRepository({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<LoginResponse> login(String email, String password) async {
    final json = await apiClient.postRaw(ApiEndpoints.login, {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    if (json.isEmpty) {
      throw const AppException('Login failed. Please try again.');
    }
    final response = LoginResponse.fromJson(json);
    if (response.token.isEmpty) {
      throw const AppException(
        'Invalid email or password',
        statusCode: 401,
        isUnauthorized: true,
      );
    }
    await tokenStorage.writeToken(response.token);
    return response;
  }

  Future<String?> restoreToken() => tokenStorage.readToken();

  Future<void> clearSession() => tokenStorage.clear();
}
