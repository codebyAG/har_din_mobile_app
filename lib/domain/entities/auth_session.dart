/// A logged-in account: the bearer token the API issued plus the
/// profile fields the app shows.
class AuthSession {
  final String token;
  final String name;
  final String phone;

  const AuthSession({
    required this.token,
    required this.name,
    required this.phone,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    return AuthSession(
      token: json['token'] as String,
      name: user['name'] as String? ?? '',
      phone: user['phone'] as String? ?? '',
    );
  }
}
