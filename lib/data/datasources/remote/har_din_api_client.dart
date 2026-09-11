import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/api_exceptions.dart';
import '../../../domain/entities/content_entities.dart';

/// The only three endpoints this app is allowed to call (§3). Never add
/// a search endpoint, pagination, or per-category endpoint here — the
/// data is already on the device, per the integration guide.
///
/// Every call funnels through the single [_request] method, which owns
/// timeout handling, status-code → [ApiException] mapping, and request/
/// response logging (via Dio's [LogInterceptor], debug builds only).
class HarDinApiClient {
  HarDinApiClient() : _dio = _sharedDio;

  final Dio _dio;

  static final Dio _sharedDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
    ..interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        logPrint: (obj) {
          if (kDebugMode) developer.log(obj.toString(), name: 'HarDinApi');
        },
      ),
    );

  Future<VersionResponse> fetchVersion(String lang) => _request(
    method: 'GET',
    path: '/v1/version',
    queryParameters: {'lang': lang},
    timeout: const Duration(seconds: 10),
    parse: (data) => VersionResponse.fromJson(data as Map<String, dynamic>),
  );

  Future<ContentPayload> fetchContent(String lang) => _request(
    method: 'GET',
    path: '/v1/content',
    queryParameters: {'lang': lang},
    timeout: const Duration(seconds: 20),
    parse: (data) => ContentPayload.fromJson(data as Map<String, dynamic>),
  );

  /// Fire-and-forget by design (§8) — callers must never let a failure
  /// here surface to the user or block anything.
  Future<void> sendEvents(
    String deviceId,
    List<Map<String, dynamic>> events,
  ) async {
    if (events.isEmpty) return;
    await _request(
      method: 'POST',
      path: '/v1/events',
      data: {'device_id': deviceId, 'events': events},
      timeout: const Duration(seconds: 10),
      parse: (_) {},
    );
  }

  /// The single call-site for every request this client makes.
  Future<T> _request<T>({
    required String method,
    required String path,
    required Duration timeout,
    required T Function(dynamic data) parse,
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        queryParameters: queryParameters,
        data: data,
        options: Options(
          method: method,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
      return parse(response.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) throw ApiNotFoundException();
      if (status == 429) throw ApiRateLimitedException();
      throw ApiException(
        status != null ? 'HTTP $status' : e.message ?? 'network error',
      );
    }
  }
}
