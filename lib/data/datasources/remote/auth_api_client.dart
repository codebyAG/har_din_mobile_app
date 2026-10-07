import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/api_exceptions.dart';
import '../../../domain/entities/auth_session.dart';

/// Account sign up / login against api-hardin.
///
/// ASSUMED CONTRACT — the backend docs (HAR-DIN-INTEGRATION.md) define no
/// auth endpoints yet, so these paths and bodies are a proposal. Change
/// them here, in one place, once the real API exists:
///
///   POST /v1/auth/signup {name, phone, password}
///                         -> 200 {token, user: {name, phone}}
///   POST /v1/auth/login  {phone, password}
///                         -> 200 {token, user: {name, phone}}
///
/// 400 = invalid input, 401/404 = wrong credentials, 409 = already
/// registered, 429 = too many attempts.
class AuthApiClient {
  AuthApiClient() : _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  final Dio _dio;

  Future<AuthSession> signUp({
    required String name,
    required String phone,
    required String password,
  }) => _post('/v1/auth/signup', {
    'name': name,
    'phone': phone,
    'password': password,
  });

  Future<AuthSession> login({
    required String phone,
    required String password,
  }) => _post('/v1/auth/login', {'phone': phone, 'password': password});

  Future<AuthSession> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return AuthSession.fromJson(res.data as Map<String, dynamic>);
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
