import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistence abstraction for the session (JWT + email).
///
/// Split into an interface so tests can inject an [InMemoryTokenStore]
/// instead of hitting the platform Keychain/Keystore.
abstract class TokenStore {
  Future<void> save(String token, String email);

  Future<String?> getToken();

  Future<String?> getEmail();

  Future<void> clear();
}

/// Default store backed by [FlutterSecureStorage]:
/// Android Keystore (EncryptedSharedPreferences) / iOS Keychain.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'tm_token';
  static const _emailKey = 'tm_email';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(String token, String email) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
  }

  @override
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  @override
  Future<String?> getEmail() => _storage.read(key: _emailKey);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }
}

/// In-memory store used by tests (and usable for previews).
class InMemoryTokenStore implements TokenStore {
  String? token;
  String? email;

  @override
  Future<void> save(String token, String email) async {
    this.token = token;
    this.email = email;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<String?> getEmail() async => email;

  @override
  Future<void> clear() async {
    token = null;
    email = null;
  }
}