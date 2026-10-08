/// Exceptions the data layer can throw. Presentation code should never
/// see raw HTTP details — only these.
class ApiException implements Exception {
  final String message;

  /// The HTTP status code, when the failure came from a response rather
  /// than a network/timeout error — lets callers like EventQueue tell
  /// "malformed, drop it" (400) apart from "retry later" (network/5xx).
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}

class ApiNotFoundException extends ApiException {
  ApiNotFoundException() : super('404 — language no longer exists', statusCode: 404);
}

class ApiRateLimitedException extends ApiException {
  ApiRateLimitedException() : super('429 — rate limited', statusCode: 429);
}

class ApiBadRequestException extends ApiException {
  ApiBadRequestException(String body) : super('400 — malformed request: $body', statusCode: 400);
}

/// A failed `/v1/auth/*` call, carrying what the server said: its `error`
/// text and, on a 429, how long until the next attempt will be accepted.
/// [statusCode] is null for a network error / timeout.
class AuthApiException extends ApiException {
  final String? serverMessage;
  final int? retryAfterSec;

  AuthApiException({
    required int? statusCode,
    this.serverMessage,
    this.retryAfterSec,
  }) : super(
         'auth ${statusCode ?? 'network error'}'
         '${serverMessage != null ? ': $serverMessage' : ''}',
         statusCode: statusCode,
       );
}
