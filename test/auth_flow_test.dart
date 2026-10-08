import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:har_din_mobile_app/core/error/api_exceptions.dart';
import 'package:har_din_mobile_app/data/datasources/remote/auth_api_client.dart';
import 'package:har_din_mobile_app/domain/entities/auth_session.dart';
import 'package:har_din_mobile_app/presentation/providers/app_language_controller.dart';
import 'package:har_din_mobile_app/presentation/providers/auth_controller.dart';
import 'package:har_din_mobile_app/screens/auth_screen.dart';

AuthSession _session({String? name}) => AuthSession(
  user: AuthUser(
    id: 'u1',
    phone: '+919876543210',
    name: name,
    language: null,
    profileComplete: name != null,
    createdAt: DateTime(2026, 10, 7),
  ),
  tokens: AuthTokens(
    accessToken: 'a',
    refreshToken: 'r',
    accessExpiresAt: DateTime.now().add(const Duration(days: 1)),
    refreshExpiresAt: DateTime.now().add(const Duration(days: 180)),
  ),
);

class _Api extends AuthApiClient {
  String? sentPhone;
  String? savedName;
  String? savedLanguage;
  AuthApiException? verifyError;

  @override
  Future<OtpSent> sendOtp(String phone) async {
    sentPhone = phone;
    return const OtpSent(30);
  }

  @override
  Future<VerifyResult> verifyOtp({
    required String phone,
    required String otp,
    String? deviceId,
  }) async {
    if (verifyError != null) throw verifyError!;
    return VerifyResult(isNewUser: true, session: _session());
  }

  @override
  Future<AuthUser> updateProfile(
    String accessToken, {
    String? name,
    String? language,
  }) async {
    if (name != null) savedName = name;
    if (language != null) savedLanguage = language;
    return _session(name: name ?? 'x').user;
  }
}

Future<void> _open(WidgetTester tester, _Api api) async {
  tester.view.physicalSize = const Size(720, 1280);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(api: api)),
        ChangeNotifierProvider(create: (_) => AppLanguageController()),
      ],
      child: const MaterialApp(home: AuthScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('phone -> OTP screen with server-driven countdown', (
    tester,
  ) async {
    final api = _Api();
    await _open(tester, api);

    // A pasted +91 number is cleaned, not blocked or truncated wrongly.
    await tester.enterText(find.byType(TextField), '+91 98765-43210');
    await tester.pump();
    expect(find.text('9876543210'), findsOneWidget);

    await tester.tap(find.text('OTP भेजें'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(api.sentPhone, '9876543210');
    expect(find.text('OTP डालें'), findsOneWidget);
    // Countdown comes from retry_after_sec (30 in this fake), not a constant.
    expect(find.text('30 सेकंड में दोबारा भेजें'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('29 सेकंड में दोबारा भेजें'), findsOneWidget);

    // Let the countdown finish so no timer is left running.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('OTP दोबारा भेजें'), findsOneWidget);
  });

  testWidgets('invalid number is rejected before any network call', (
    tester,
  ) async {
    final api = _Api();
    await _open(tester, api);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('OTP भेजें'));
    await tester.pump();

    expect(find.text('10 अंकों का सही मोबाइल नंबर डालें।'), findsOneWidget);
    expect(api.sentPhone, isNull);
  });

  testWidgets('new user is asked for a name after the OTP', (tester) async {
    final api = _Api();
    await _open(tester, api);

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('OTP भेजें'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Six digits auto-verify.
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('आपका नाम क्या है?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Lakshya');
    await tester.tap(find.text('आगे बढ़ें'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(api.savedName, 'Lakshya');
    // The app language is pushed to the account right after sign-in.
    expect(api.savedLanguage, 'hi');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a provider outage is not shown as a wrong code', (tester) async {
    final api = _Api()..verifyError = AuthApiException(statusCode: 503);
    await _open(tester, api);

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('OTP भेजें'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.text('अभी वेरीफाई नहीं हो सका। थोड़ी देर बाद फिर कोशिश करें।'),
      findsOneWidget,
    );
    expect(find.text('OTP गलत है या expire हो गया है।'), findsNothing);

    await tester.pump(const Duration(seconds: 31)); // stop the countdown
  });
}
