import 'package:flutter/foundation.dart';

import '../../core/error/api_exceptions.dart';
import '../../data/datasources/local/local_store.dart';
import '../../data/datasources/remote/auth_api_client.dart';
import '../../domain/entities/auth_session.dart';

/// Account state. Guests are fine — the app works without an account —
/// so [session] is simply null until the user signs in.
class AuthController extends ChangeNotifier {
  /// TEMPORARY: the auth endpoints don't exist yet, so while this is true
  /// the OTP step succeeds locally with whatever was typed — no network
  /// call, no validation. Set to false once the backend is ready.
  static const bool offlineDemoAuth = true;

  AuthController({AuthApiClient? api, LocalStore store = const LocalStore()})
    : _api = api ?? AuthApiClient(),
      _store = store {
    _restore();
  }

  final AuthApiClient _api;
  final LocalStore _store;

  AuthSession? _session;
  AuthSession? get session => _session;
  bool get isLoggedIn => _session != null;

  Future<void> _restore() async {
    _session = await _store.readSession();
    notifyListeners();
  }

  /// Step 1 of the single auth screen: texts an OTP and learns whether
  /// the number already has an account (existing -> login, new -> sign
  /// up). Returns `(exists, null)` on success, `(null, message)` on
  /// failure. In demo mode every number is treated as new.
  Future<({bool? exists, String? error})> sendOtp(String phone) async {
    if (offlineDemoAuth) return (exists: false, error: null);
    try {
      return (exists: await _api.sendOtp(phone), error: null);
    } on ApiRateLimitedException {
      return (exists: null, error: _rateLimited);
    } on ApiBadRequestException {
      return (exists: null, error: 'मोबाइल नंबर सही नहीं है।');
    } catch (_) {
      return (exists: null, error: _generic);
    }
  }

  /// Step 2: verifies the OTP (the server creates the account if the
  /// number is new) and stores the session. Returns null on success, otherwise a Hindi
  /// message ready to show the user.
  Future<String?> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final session = offlineDemoAuth
          ? AuthSession(
              token: 'demo-token',
              name: 'हर दिन यूज़र',
              phone: phone.trim(),
            )
          : await _api.verifyOtp(phone: phone, otp: otp);
      await _store.writeSession(session);
      _session = session;
      notifyListeners();
      return null;
    } on ApiRateLimitedException {
      return _rateLimited;
    } on ApiBadRequestException {
      return 'OTP सही नहीं है। दोबारा जाँचें।';
    } catch (_) {
      return _generic;
    }
  }

  Future<void> logout() async {
    await _store.clearSession();
    _session = null;
    notifyListeners();
  }

  static const _rateLimited =
      'बहुत ज़्यादा कोशिशें हो गईं। थोड़ी देर बाद फिर करें।';
  static const _generic = 'कुछ गड़बड़ हुई। इंटरनेट जाँचकर फिर कोशिश करें।';
}
