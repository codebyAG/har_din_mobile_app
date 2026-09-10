import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/error/api_exceptions.dart';
import '../../../domain/entities/content_entities.dart';

/// The only three endpoints this app is allowed to call (§3). Never add
/// a search endpoint, pagination, or per-category endpoint here — the
/// data is already on the device, per the integration guide.
class HarDinApiClient {
  const HarDinApiClient();

  Future<VersionResponse> fetchVersion(String lang) async {
    final res = await http
        .get(Uri.parse('${ApiConstants.baseUrl}/v1/version?lang=$lang'))
        .timeout(const Duration(seconds: 10));
    _throwOnError(res);
    return VersionResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ContentPayload> fetchContent(String lang) async {
    final res = await http
        .get(Uri.parse('${ApiConstants.baseUrl}/v1/content?lang=$lang'))
        .timeout(const Duration(seconds: 20));
    _throwOnError(res);
    return ContentPayload.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Fire-and-forget by design (§8) — callers must never let a failure
  /// here surface to the user or block anything.
  Future<void> sendEvents(String deviceId, List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return;
    await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/v1/events'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'device_id': deviceId, 'events': events}),
        )
        .timeout(const Duration(seconds: 10));
  }

  void _throwOnError(http.Response res) {
    if (res.statusCode == 404) throw ApiNotFoundException();
    if (res.statusCode == 429) throw ApiRateLimitedException();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}');
    }
  }
}
