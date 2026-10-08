import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/api_exceptions.dart';
import '../../../domain/entities/auth_session.dart';

/// Result of `otp/send` and `otp/resend`: the code is on its way, and a
/// resend will be accepted after [retryAfterSec] seconds.
class OtpSent {
  final int retryAfterSec;
  const OtpSent(this.retryAfterSec);
}

/// How a resend is delivered.
enum OtpChannel { text, voice }

/// Phone + OTP auth, per APP-CHANGES-02 §2 (live contract:
/// `https://api-hardin.vocadose.com/docs`). MSG91 generates, delivers and
/// verifies the code — the backend, and this client, never see it again.
///
/// Deliberately its **own** Dio, separate from [HarDinApiClient]: the
/// content / version / languages / events endpoints must never carry an
/// `Authorization` header (it would make them uncacheable at the edge).
/// Only `/v1/auth/me` gets a bearer token, passed per call.
///
/// Every failure surfaces as an [AuthApiException] with the status code,
/// the server's `error` text and (on 429) `retry_after_sec`.
class AuthApiClient {
  AuthApiClient() : _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  final Dio _dio;

  static const _timeout = Duration(seconds: 15);

  Future<OtpSent> sendOtp(String phone) async {
    final data = await _request('POST', '/v1/auth/otp/send', {'phone': phone});
    return OtpSent((data as Map<String, dynamic>)['retry_after_sec'] as int);
  }

  Future<OtpSent> resendOtp(
    String phone, {
    OtpChannel channel = OtpChannel.text,
  }) async {
    final data = await _request('POST', '/v1/auth/otp/resend', {
      'phone': phone,
      'channel': channel.name,
    });
    return OtpSent((data as Map<String, dynamic>)['retry_after_sec'] as int);
  }

  Future<VerifyResult> verifyOtp({
    required String phone,
    required String otp,
    String? deviceId,
  }) async {
    final data =
        await _request('POST', '/v1/auth/otp/verify', {
              'phone': phone,
              'otp': otp,
              'device_id': ?deviceId,
            })
            as Map<String, dynamic>;
    return VerifyResult(
      isNewUser: data['is_new_user'] as bool,
      session: AuthSession(
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>),
      ),
    );
  }

  /// Rotates the pair. The old refresh token (and access token) stop
  /// working the instant this returns, so the caller must persist the
  /// result before making another request.
  Future<AuthSession> refresh(String refreshToken) async {
    final data =
        await _request('POST', '/v1/auth/refresh', {
              'refresh_token': refreshToken,
            })
            as Map<String, dynamic>;
    return AuthSession(
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>),
    );
  }

  /// Signs out this device. Idempotent on the server (204 even for an
  /// unknown token).
  Future<void> logout(String refreshToken) =>
      _request('POST', '/v1/auth/logout', {'refresh_token': refreshToken});

  Future<AuthUser> me(String accessToken) async => AuthUser.fromJson(
    await _request('GET', '/v1/auth/me', null, accessToken: accessToken)
        as Map<String, dynamic>,
  );

  /// Both fields are optional, but sending neither is a 400.
  Future<AuthUser> updateProfile(
    String accessToken, {
    String? name,
    String? language,
  }) async => AuthUser.fromJson(
    await _request('PATCH', '/v1/auth/me', {
          'name': ?name,
          'language': ?language,
        }, accessToken: accessToken)
        as Map<String, dynamic>,
  );

  /// Signs out every device and deletes the session server-side.
  Future<void> deleteAccountSessions(String accessToken) =>
      _request('DELETE', '/v1/auth/me', null, accessToken: accessToken);

  Future<dynamic> _request(
    String method,
    String path,
    Map<String, dynamic>? body, {
    String? accessToken,
  }) async {
    try {
      final res = await _dio.request<dynamic>(
        path,
        data: body,
        options: Options(
          method: method,
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
          headers: accessToken == null
              ? null
              : {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return res.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw AuthApiException(
        statusCode: e.response?.statusCode,
        serverMessage: data is Map ? data['error'] as String? : null,
        retryAfterSec: data is Map ? data['retry_after_sec'] as int? : null,
      );
    }
  }
}
