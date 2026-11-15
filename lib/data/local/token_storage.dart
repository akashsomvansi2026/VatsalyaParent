import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for the parent JWT.
///
/// Uses Android Keystore-backed encryption via `flutter_secure_storage`
/// instead of `localStorage` used by the web portal.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'vg_parent_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<bool> readTermsAccepted() async =>
      await _storage.read(key: 'vg_terms_accepted_v1') == 'true';

  Future<void> writeTermsAccepted() =>
      _storage.write(key: 'vg_terms_accepted_v1', value: 'true');

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
