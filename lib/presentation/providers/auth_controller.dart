import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/error/api_exceptions.dart';
import '../../data/datasources/local/local_store.dart';
import '../../data/datasources/local/secure_session_store.dart';
import '../../data/datasources/remote/auth_api_client.dart';
import '../../domain/entities/auth_session.dart';

export '../../data/datasources/remote/auth_api_client.dart'
    show OtpChannel, OtpSent;

enum AuthFailureKind {
  /// 400 — the number / name the server was sent isn't valid.
  invalidInput,

  /// 401 on verify — wrong or expired code.
  wrongCode,

  /// 429 — too soon or too many; [AuthFailure.retryAfterSec] says how long.
  rateLimited,

  /// 503 — the SMS provider failed. Never shown as a wrong code, or the
  /// user retypes a correct OTP until they are locked out.
  providerDown,

  /// No connection / timeout.
  network,

  /// The session is gone (refresh rejected) — the user must sign in again.
  signedOut,

  other,
}

/// What the UI needs to react to a failed auth call: a [kind] to branch
/// on and a ready-to-show Hindi [message].
class AuthFailure implements Exception {
  final AuthFailureKind kind;
  final String message;
  final int? retryAfterSec;

  const AuthFailure(this.kind, this.message, {this.retryAfterSec});

  @override
  String toString() => 'AuthFailure($kind): $message';
}

enum _Step { send, verify, profile, other }

/// Account state. Guests are fine — the app works without an account —
/// so [session] is simply null until the user signs in.
///
/// Tokens live in secure storage ([SecureSessionStore]). Refresh is
/// single-flight: concurrent 401s share one refresh call, because the
/// refresh token rotates and a second concurrent refresh would replay a
/// spent token and sign the user out.
class AuthController extends ChangeNotifier {
  AuthController({
    AuthApiClient? api,
    SecureSessionStore store = const SecureSessionStore(),
    LocalStore localStore = const LocalStore(),
  }) : _api = api ?? AuthApiClient(),
       _store = store,
       _localStore = localStore {
    _restore();
  }

  final AuthApiClient _api;
  final SecureSessionStore _store;
  final LocalStore _localStore;

  AuthSession? _session;
  AuthSession? get session => _session;
  bool get isLoggedIn => _session != null;

  /// True when a signed-in user still owes us a name (they dismissed the
  /// first-run popup) — ask again later instead of losing it forever.
  bool get needsName => _session != null && !_session!.profileComplete;

  /// Set when the server rejected the refresh token and the user was
  /// signed out without asking. The UI sends them back to the phone
  /// screen, then calls [acknowledgeForcedLogout].
  bool _forcedLogout = false;
  bool get forcedLogout => _forcedLogout;

  void acknowledgeForcedLogout() {
    if (!_forcedLogout) return;
    _forcedLogout = false;
  }

  Future<void> _restore() async {
    _session = await _store.read();
    notifyListeners();
    if (_session != null) {
      // Best effort: pick up the latest name / profile_complete.
      unawaited(refreshProfile().catchError((_) {}));
    }
  }

  // --- sign in -----------------------------------------------------------

  /// Texts a code to [phone] (ten digits, no country code). Throws
  /// [AuthFailure].
  Future<OtpSent> sendOtp(String phone) =>
      _call(() => _api.sendOtp(phone), _Step.send);

  /// Re-delivers the same code, by text or by voice call. Throws
  /// [AuthFailure].
  Future<OtpSent> resendOtp(
    String phone, {
    OtpChannel channel = OtpChannel.text,
  }) => _call(() => _api.resendOtp(phone, channel: channel), _Step.send);

  /// Verifies the code and signs in — the server creates the account if
  /// the number is new. Returns `is_new_user`. Throws [AuthFailure].
  Future<bool> verifyOtp(String phone, String otp) async {
    final deviceId = await _localStore.getOrCreateDeviceId();
    final result = await _call(
      () => _api.verifyOtp(phone: phone, otp: otp, deviceId: deviceId),
      _Step.verify,
    );
    await _setSession(result.session);
    return result.isNewUser;
  }

  /// Saves the name from the first-run popup (or a later edit). Throws
  /// [AuthFailure].
  Future<void> saveName(String name) async {
    final user = await _authed(
      (token) => _api.updateProfile(token, name: name.trim()),
      _Step.profile,
    );
    await _setSession(_session!.copyWith(user: user));
  }

  Future<void> refreshProfile() async {
    final user = await _authed((token) => _api.me(token), _Step.other);
    if (_session != null) await _setSession(_session!.copyWith(user: user));
  }

  // --- sign out ----------------------------------------------------------

  /// Signs out this device. Local tokens are always cleared, even if the
  /// server call fails — logout is idempotent server-side.
  Future<void> logout() async {
    final refreshToken = _session?.tokens.refreshToken;
    await _clearLocal();
    if (refreshToken != null) {
      try {
        await _api.logout(refreshToken);
      } catch (_) {
        // Already signed out locally; nothing the user can act on.
      }
    }
  }

  /// Signs out every device (`DELETE /v1/auth/me`). Throws [AuthFailure]
  /// if the server call fails, and then keeps the local session.
  Future<void> logoutEverywhere() async {
    await _authed((token) => _api.deleteAccountSessions(token), _Step.other);
    await _clearLocal();
  }

  /// Saves the app language on the account (`PATCH /v1/auth/me`) when
  /// signed in and it differs from what the server has. Best effort and
  /// silent: a failure here must never get in the user's way.
  Future<void> syncLanguage(String code) async {
    final current = _session;
    if (current == null || current.user.language == code) return;
    try {
      final user = await _authed(
        (token) => _api.updateProfile(token, language: code),
        _Step.profile,
      );
      if (_session != null) await _setSession(_session!.copyWith(user: user));
    } on AuthFailure {
      // Try again next time the language changes or the app opens.
    }
  }

  // --- internals ---------------------------------------------------------

  Future<void> _setSession(AuthSession session) async {
    _session = session;
    await _store.write(session);
    notifyListeners();
  }

  Future<void> _clearLocal() async {
    _session = null;
    await _store.clear();
    notifyListeners();
  }

  Future<void>? _refreshing;

  /// One refresh at a time; everyone who asks while it runs awaits the
  /// same one.
  Future<void> _refreshOnce() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<void> _doRefresh() async {
    final current = _session;
    if (current == null) throw _signedOut();
    try {
      final fresh = await _api.refresh(current.tokens.refreshToken);
      // Persist the new pair before anything else uses it — the old one
      // stopped working the moment this returned.
      await _setSession(fresh);
    } on AuthApiException catch (e) {
      if (e.statusCode == 401) {
        // Spent / revoked / expired refresh token: signed out for real.
        _forcedLogout = true;
        await _clearLocal();
        throw _signedOut();
      }
      throw _map(e, _Step.other);
    }
  }

  AuthFailure _signedOut() => const AuthFailure(
    AuthFailureKind.signedOut,
    'आपका सेशन खत्म हो गया है। फिर से लॉगिन करें।',
  );

  /// Runs an authenticated call: refresh first if the access token is
  /// (nearly) expired; on a 401, refresh once and retry once.
  Future<T> _authed<T>(
    Future<T> Function(String accessToken) call,
    _Step step,
  ) async {
    if (_session == null) throw _signedOut();
    if (_session!.tokens.accessExpired) await _refreshOnce();
    try {
      return await call(_session!.tokens.accessToken);
    } on AuthApiException catch (e) {
      if (e.statusCode != 401) throw _map(e, step);
      await _refreshOnce();
      try {
        return await call(_session!.tokens.accessToken);
      } on AuthApiException catch (e2) {
        throw _map(e2, step);
      }
    }
  }

  Future<T> _call<T>(Future<T> Function() action, _Step step) async {
    try {
      return await action();
    } on AuthApiException catch (e) {
      throw _map(e, step);
    }
  }

  AuthFailure _map(AuthApiException e, _Step step) {
    final status = e.statusCode;
    if (status == null) {
      return const AuthFailure(
        AuthFailureKind.network,
        'इंटरनेट जाँचकर फिर कोशिश करें।',
      );
    }
    switch (status) {
      case 400:
        return AuthFailure(
          AuthFailureKind.invalidInput,
          step == _Step.profile
              ? 'नाम सही नहीं है। दोबारा लिखें।'
              : 'सही 10 अंकों का मोबाइल नंबर डालें।',
        );
      case 401:
        return step == _Step.verify
            ? const AuthFailure(
                AuthFailureKind.wrongCode,
                'OTP गलत है या expire हो गया है।',
              )
            : _signedOut();
      case 429:
        return AuthFailure(
          AuthFailureKind.rateLimited,
          'बहुत ज़्यादा कोशिशें हो गईं। '
          '${_waitText(e.retryAfterSec)} बाद फिर कोशिश करें।',
          retryAfterSec: e.retryAfterSec,
        );
      case 503:
        return AuthFailure(
          AuthFailureKind.providerDown,
          step == _Step.verify
              ? 'अभी वेरीफाई नहीं हो सका। थोड़ी देर बाद फिर कोशिश करें।'
              : 'कोड भेजा नहीं जा सका। थोड़ी देर बाद फिर कोशिश करें।',
        );
      default:
        return const AuthFailure(
          AuthFailureKind.other,
          'कुछ गड़बड़ हुई। फिर कोशिश करें।',
        );
    }
  }

  static String _waitText(int? seconds) {
    if (seconds == null || seconds <= 0) return 'थोड़ी देर';
    if (seconds < 60) return '$seconds सेकंड';
    return '${(seconds / 60).ceil()} मिनट';
  }
}
