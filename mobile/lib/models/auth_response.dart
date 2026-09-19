/// Mirror of the backend `AuthResponse` record returned by
/// `/api/auth/register` and `/api/auth/login`.
class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.email,
  });

  final String token;
  final String tokenType;
  final int expiresIn;
  final String email;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        expiresIn: json['expiresIn'] as int? ?? 0,
        email: json['email'] as String,
      );
}