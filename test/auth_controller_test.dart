import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:har_din_mobile_app/core/error/api_exceptions.dart';
import 'package:har_din_mobile_app/core/utils/phone_utils.dart';
import 'package:har_din_mobile_app/data/datasources/remote/auth_api_client.dart';
import 'package:har_din_mobile_app/domain/entities/auth_session.dart';
import 'package:har_din_mobile_app/presentation/providers/auth_controller.dart';

AuthUser _user({String? name, bool complete = false}) => AuthUser(
  id: 'u1',
  phone: '+919876543210',
  name: name,
  language: null,
  profileComplete: complete,
  createdAt: DateTime(2026, 10, 7),
);

AuthTokens _tokens(String access, String refresh) => AuthTokens(
  accessToken: access,
  refreshToken: refresh,
  accessExpiresAt: DateTime.now().add(const Duration(days: 1)),
  refreshExpiresAt: DateTime.now().add(const Duration(days: 180)),
);

/// Scriptable stand-in for the network layer.
class FakeAuthApi extends AuthApiClient {
  int refreshCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  bool deleteFails = false;
  String? serverLanguage;
  String validAccess = 'access-1';
  String currentRefresh = 'refresh-1';
  bool refreshRejected = false;
  AuthApiException? verifyError;

  @override
  Future<OtpSent> sendOtp(String phone) async => const OtpSent(30);

  @override
  Future<VerifyResult> verifyOtp({
    required String phone,
    required String otp,
    String? deviceId,
  }) async {
    if (verifyError != null) throw verifyError!;
    return VerifyResult(
      isNewUser: true,
      session: AuthSession(
        user: _user(),
        tokens: _tokens(validAccess, currentRefresh),
      ),
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    refreshCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (refreshRejected || refreshToken != currentRefresh) {
      throw AuthApiException(statusCode: 401, serverMessage: 'spent');
    }
    validAccess = 'access-${refreshCalls + 1}';
    currentRefresh = 'refresh-${refreshCalls + 1}';
    return AuthSession(
      user: _user(),
      tokens: _tokens(validAccess, currentRefresh),
    );
  }

  @override
  Future<AuthUser> updateProfile(
    String accessToken, {
    String? name,
    String? language,
  }) async {
    updateCalls++;
    if (accessToken != validAccess) {
      throw AuthApiException(statusCode: 401, serverMessage: 'expired');
    }
    if (language != null) serverLanguage = language;
    return AuthUser(
      id: 'u1',
      phone: '+919876543210',
      name: name ?? 'Lakshya',
      language: language ?? serverLanguage,
      profileComplete: true,
      createdAt: DateTime(2026, 10, 7),
    );
  }

  @override
  Future<void> deleteAccountSessions(String accessToken) async {
    deleteCalls++;
    if (deleteFails) throw AuthApiException(statusCode: 503);
  }
}

class _NetworkDownOnRefresh extends FakeAuthApi {
  @override
  Future<AuthSession> refresh(String refreshToken) async {
    throw AuthApiException(statusCode: null);
  }
}

class _LogoutFails extends FakeAuthApi {
  @override
  Future<void> logout(String refreshToken) async {
    throw AuthApiException(statusCode: null);
  }
}

Future<AuthController> _signedIn(FakeAuthApi api) async {
  final auth = AuthController(api: api);
  await auth.verifyOtp('9876543210', '123456');
  return auth;
}

Matcher _failure(AuthFailureKind kind) =>
    isA<AuthFailure>().having((f) => f.kind, 'kind', kind);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('verify signs in, stores the session and reports is_new_user', () async {
    final api = FakeAuthApi();
    final auth = AuthController(api: api);
    expect(auth.isLoggedIn, isFalse);

    final isNew = await auth.verifyOtp('9876543210', '123456');

    expect(isNew, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.needsName, isTrue); // profile_complete is false

    // Survives a restart: a new controller restores it from secure storage.
    final restored = AuthController(api: api);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(restored.isLoggedIn, isTrue);
  });

  test(
    'wrong code, provider outage and lockout are different failures',
    () async {
      final api = FakeAuthApi();
      final auth = AuthController(api: api);

      api.verifyError = AuthApiException(statusCode: 401);
      await expectLater(
        auth.verifyOtp('9876543210', '000000'),
        throwsA(_failure(AuthFailureKind.wrongCode)),
      );

      // A 503 must never read as a wrong code, or the user retypes a correct
      // OTP until they are locked out.
      api.verifyError = AuthApiException(statusCode: 503);
      await expectLater(
        auth.verifyOtp('9876543210', '123456'),
        throwsA(_failure(AuthFailureKind.providerDown)),
      );

      api.verifyError = AuthApiException(statusCode: 429, retryAfterSec: 900);
      await expectLater(
        auth.verifyOtp('9876543210', '000000'),
        throwsA(
          isA<AuthFailure>()
              .having((f) => f.kind, 'kind', AuthFailureKind.rateLimited)
              .having((f) => f.retryAfterSec, 'retryAfterSec', 900),
        ),
      );
      expect(auth.isLoggedIn, isFalse);
    },
  );

  test('a 401 refreshes once, retries, and keeps the new pair', () async {
    final api = FakeAuthApi();
    final auth = await _signedIn(api);

    api.validAccess = 'rotated-elsewhere'; // server no longer accepts ours
    await auth.saveName('Lakshya');

    expect(api.refreshCalls, 1);
    expect(api.updateCalls, 2); // the 401, then the retry
    expect(auth.session!.name, 'Lakshya');
    expect(auth.needsName, isFalse);
    expect(auth.session!.tokens.refreshToken, api.currentRefresh);
  });

  test('concurrent 401s share ONE refresh (single-flight)', () async {
    final api = FakeAuthApi();
    final auth = await _signedIn(api);
    api.validAccess = 'rotated-elsewhere';

    await Future.wait([
      auth.saveName('A'),
      auth.saveName('B'),
      auth.saveName('C'),
    ]);

    // Three refreshes would replay a spent refresh token and sign the user
    // out.
    expect(api.refreshCalls, 1);
    expect(auth.isLoggedIn, isTrue);
  });

  test('a rejected refresh token signs the user out and flags it', () async {
    final api = FakeAuthApi();
    final auth = await _signedIn(api);
    api.validAccess = 'rotated-elsewhere';
    api.refreshRejected = true;

    await expectLater(
      auth.saveName('Lakshya'),
      throwsA(_failure(AuthFailureKind.signedOut)),
    );

    expect(auth.isLoggedIn, isFalse);
    expect(auth.forcedLogout, isTrue);
    auth.acknowledgeForcedLogout();
    expect(auth.forcedLogout, isFalse);
  });

  test('a network error during refresh keeps the user signed in', () async {
    final api = _NetworkDownOnRefresh();
    final auth = await _signedIn(api);
    api.validAccess = 'rotated-elsewhere';

    await expectLater(
      auth.saveName('Lakshya'),
      throwsA(_failure(AuthFailureKind.network)),
    );
    expect(auth.isLoggedIn, isTrue);
    expect(auth.forcedLogout, isFalse);
  });

  test('logout clears local state even if the server call fails', () async {
    final auth = await _signedIn(_LogoutFails());
    await auth.logout();
    expect(auth.isLoggedIn, isFalse);
    expect(auth.forcedLogout, isFalse); // the user asked for it
  });

  test(
    'language is saved on the account once, and only when it differs',
    () async {
      final api = FakeAuthApi();
      final auth = await _signedIn(api);

      await auth.syncLanguage('mr');
      expect(api.serverLanguage, 'mr');
      expect(auth.session!.user.language, 'mr');

      final calls = api.updateCalls;
      await auth.syncLanguage('mr'); // already in step: no request
      expect(api.updateCalls, calls);
    },
  );

  test(
    'language sync is silent when signed out or when the call fails',
    () async {
      final api = FakeAuthApi();
      final signedOut = AuthController(api: api);
      await signedOut.syncLanguage('hi');
      expect(api.updateCalls, 0);

      final auth = await _signedIn(api);
      api.validAccess = 'rotated-elsewhere';
      api.refreshRejected = true;
      await auth.syncLanguage('hi'); // must not throw
      expect(auth.isLoggedIn, isFalse);
    },
  );

  test('sign out everywhere clears the session; a failure keeps it', () async {
    final api = FakeAuthApi();
    final auth = await _signedIn(api);

    api.deleteFails = true;
    await expectLater(
      auth.logoutEverywhere(),
      throwsA(_failure(AuthFailureKind.providerDown)),
    );
    expect(auth.isLoggedIn, isTrue); // still signed in: the server never agreed

    api.deleteFails = false;
    await auth.logoutEverywhere();
    expect(api.deleteCalls, 2);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.forcedLogout, isFalse);
  });

  group('phone cleanup', () {
    test('pasted forms all become ten digits', () {
      for (final raw in [
        '9876543210',
        '+91 98765-43210',
        '+919876543210',
        '09876543210',
        '91 9876543210',
        ' (98765) 43210 ',
      ]) {
        expect(normalizeIndianPhone(raw), '9876543210', reason: raw);
      }
    });

    test('typing stays untouched and is capped at ten', () {
      expect(normalizeIndianPhone('98765'), '98765');
      expect(normalizeIndianPhone('98765432101234'), '9876543210');
    });
  });
}
