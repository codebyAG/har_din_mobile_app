/// The signed-in user, as `/v1/auth/*` returns it.
class AuthUser {
  final String id;

  /// E.164, e.g. `+919876543210`.
  final String phone;
  final String? name;
  final String? language;

  /// `false` until a name has been saved — the durable version of
  /// "is this a first-run user who still owes us a name".
  final bool profileComplete;
  final DateTime? createdAt;

  const AuthUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.language,
    required this.profileComplete,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    language: json['language'] as String?,
    profileComplete: json['profile_complete'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'language': language,
    'profile_complete': profileComplete,
    'created_at': createdAt?.toIso8601String(),
  };
}

/// An access / refresh token pair. Both rotate on every refresh, so the
/// pair is always stored and replaced as one unit.
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresAt: now.add(Duration(seconds: json['expires_in'] as int)),
      refreshExpiresAt: now.add(
        Duration(seconds: json['refresh_expires_in'] as int),
      ),
    );
  }

  /// Restores tokens saved by [toStoredJson] (absolute expiry times).
  factory AuthTokens.fromStoredJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
    refreshExpiresAt: DateTime.parse(json['refresh_expires_at'] as String),
  );

  Map<String, dynamic> toStoredJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_expires_at': accessExpiresAt.toIso8601String(),
    'refresh_expires_at': refreshExpiresAt.toIso8601String(),
  };

  /// Treats a token as expired a little early so a request never leaves
  /// with one that dies in flight.
  bool get accessExpired => DateTime.now().isAfter(
    accessExpiresAt.subtract(const Duration(minutes: 1)),
  );
}

/// A user plus the tokens that prove it.
class AuthSession {
  final AuthUser user;
  final AuthTokens tokens;

  const AuthSession({required this.user, required this.tokens});

  String get name => user.name ?? '';
  String get phone => user.phone;
  bool get profileComplete => user.profileComplete;

  AuthSession copyWith({AuthUser? user, AuthTokens? tokens}) =>
      AuthSession(user: user ?? this.user, tokens: tokens ?? this.tokens);
}

/// What a successful OTP verification returns.
class VerifyResult {
  final bool isNewUser;
  final AuthSession session;

  const VerifyResult({required this.isNewUser, required this.session});
}
