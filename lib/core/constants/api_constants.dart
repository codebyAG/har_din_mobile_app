class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api-hardin.vocadose.com';
  static const Duration minVersionRecheckInterval = Duration(minutes: 30);

  /// Digits in the OTP texted by MSG91. APP-CHANGES-02 says 6, but the live
  /// server sent (and verified) a 4-digit code on 2026-10-08, and the
  /// contract accepts 4–8. Change this one number if the SMS template does.
  static const int otpLength = 4;
}
