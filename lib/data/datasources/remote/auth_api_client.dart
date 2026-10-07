import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/api_exceptions.dart';
import '../../../domain/entities/auth_session.dart';

/// Phone-number + OTP auth against api-hardin. One flow for everyone:
/// the backend decides whether the number is an existing account (log in)
/// or a new one (sign up).
///
/// ASSUMED CONTRACT — the backend docs (HAR-DIN-INTEGRATION.md) define no
/// auth endpoints yet, so these paths and bodies are a proposal. Change
/// them here, in one place, once the real API exists:
///
///   POST /v1/auth/otp/send    {phone}
///        -> 200 {exists: bool}   OTP is texted either way; `exists` says
///                                whether this number already has an account
///   POST /v1/auth/otp/verify  {phone, otp}
///        -> 200 {token, user: {name, phone}}
///                                creates the account if the number is new
///
/// 400 = bad number/OTP, 429 = too many attempts.
class AuthApiClient {
  AuthApiClient() : _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  final Dio _dio;

  /// Texts an OTP to [phone]. Returns whether the number already has an
  /// account.
  Future<bool> sendOtp(String phone) async {
    final data = await _post('/v1/auth/otp/send', {'phone': phone});
    return (data as Map<String, dynamic>)['exists'] as bool;
  }

  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final data = await _post('/v1/auth/otp/verify', {
      'phone': phone,
      'otp': otp,
    });
    return AuthSession.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return res.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) throw ApiNotFoundException();
      if (status == 429) throw ApiRateLimitedException();
      if (status == 400) throw ApiBadRequestException('${e.response?.data}');
      throw ApiException(
        status != null ? 'HTTP $status' : e.message ?? 'network error',
        statusCode: status,
      );
    }
  }
}
