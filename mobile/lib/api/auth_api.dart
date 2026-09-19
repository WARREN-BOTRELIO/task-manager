import '../models/auth_response.dart';
import 'api_client.dart';

class Credentials {
  const Credentials({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Communication layer for the auth endpoints:
///   - `POST /api/auth/login`
///   - `POST /api/auth/register`
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthResponse> login(Credentials credentials) async {
    final json = await _client.postJson('/api/auth/login', body: credentials.toJson());
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> register(Credentials credentials) async {
    final json = await _client.postJson('/api/auth/register', body: credentials.toJson());
    return AuthResponse.fromJson(json);
  }
}