/// Exceptions the data layer can throw. Presentation code should never
/// see raw HTTP details — only these.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class ApiNotFoundException extends ApiException {
  ApiNotFoundException() : super('404 — language no longer exists');
}

class ApiRateLimitedException extends ApiException {
  ApiRateLimitedException() : super('429 — rate limited');
}
