import 'parent_user.dart';

/// Raw login response `{ token, parent }` (not enveloped).
class LoginResponse {
  const LoginResponse({required this.token, required this.parent});

  final String token;
  final ParentUser parent;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? '',
      parent: ParentUser.fromJson(
        (json['parent'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
