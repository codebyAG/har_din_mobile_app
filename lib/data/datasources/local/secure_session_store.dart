import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../domain/entities/auth_session.dart';

/// Keeps the 180-day refresh token and the signed-in user in the
/// platform secure store (Android Keystore / iOS Keychain) — not
/// `SharedPreferences`, which is plain text on disk.
///
/// The tokens and the user are written together as one value, so a
/// refresh can never leave a new access token paired with an old
/// refresh token.
class SecureSessionStore {
  const SecureSessionStore();

  static const _key = 'har_din.auth_session';
  static const _storage = FlutterSecureStorage();

  Future<AuthSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromStoredJson(
          json['tokens'] as Map<String, dynamic>,
        ),
      );
    } catch (_) {
      // Corrupt or unreadable (e.g. keystore reset) — treat as signed out.
      await clear();
      return null;
    }
  }

  Future<void> write(AuthSession session) => _storage.write(
    key: _key,
    value: jsonEncode({
      'user': session.user.toJson(),
      'tokens': session.tokens.toStoredJson(),
    }),
  );

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing useful to do — the in-memory session is dropped anyway.
    }
  }
}
