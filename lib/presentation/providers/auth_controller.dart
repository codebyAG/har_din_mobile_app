import 'package:flutter/foundation.dart';

import '../../core/error/api_exceptions.dart';
import '../../data/datasources/local/local_store.dart';
import '../../data/datasources/remote/auth_api_client.dart';
import '../../domain/entities/auth_session.dart';

/// Account state. Guests are fine — the app works without an account —
/// so [session] is simply null until the user signs in.
class AuthController extends ChangeNotifier {
  /// TEMPORARY: the auth endpoints don't exist yet, so while this is true
  /// login / sign up succeed locally with whatever was typed — no network
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

  /// Creates an account. Returns null on success, otherwise a Hindi
  /// message ready to show the user.
  Future<String?> signUp({
    required String name,
    required String phone,
    required String password,
  }) => _authenticate(
    () => offlineDemoAuth
        ? _demoSession(name: name, phone: phone)
        : _api.signUp(name: name, phone: phone, password: password),
    conflictMessage: 'यह नंबर पहले से रजिस्टर है। लॉगिन करें।',
  );

  /// Same return convention as [signUp].
  Future<String?> login({required String phone, required String password}) =>
      _authenticate(
        () => offlineDemoAuth
            ? _demoSession(name: '', phone: phone)
            : _api.login(phone: phone, password: password),
        conflictMessage: 'कुछ गड़बड़ हुई। फिर कोशिश करें।',
      );

  Future<AuthSession> _demoSession({
    required String name,
    required String phone,
  }) async => AuthSession(
    token: 'demo-token',
    name: name.trim().isEmpty ? 'हर दिन यूज़र' : name.trim(),
    phone: phone.trim(),
  );

  Future<void> logout() async {
    await _store.clearSession();
    _session = null;
    notifyListeners();
  }

  Future<String?> _authenticate(
    Future<AuthSession> Function() action, {
    required String conflictMessage,
  }) async {
    try {
      final session = await action();
      await _store.writeSession(session);
      _session = session;
      notifyListeners();
      return null;
    } on ApiNotFoundException {
      return 'मोबाइल नंबर या पासवर्ड सही नहीं है।';
    } on ApiRateLimitedException {
      return 'बहुत ज़्यादा कोशिशें हो गईं। थोड़ी देर बाद फिर करें।';
    } on ApiBadRequestException {
      return 'दी गई जानकारी सही नहीं है। जाँचकर फिर कोशिश करें।';
    } on ApiException catch (e) {
      if (e.statusCode == 401) return 'मोबाइल नंबर या पासवर्ड सही नहीं है।';
      if (e.statusCode == 409) return conflictMessage;
      return 'कुछ गड़बड़ हुई। इंटरनेट जाँचकर फिर कोशिश करें।';
    } catch (_) {
      return 'कुछ गड़बड़ हुई। फिर कोशिश करें।';
    }
  }
}
