import '../entities/content_entities.dart';

/// Result of a load attempt — the payload the app should render, plus
/// whether the selected language turned out to be gone server-side
/// (§10). Never a thrown exception: the caching contract's whole point
/// is "fail toward the cached copy, always".
class ContentLoadResult {
  final ContentPayload? payload;
  final bool languageMissing;

  const ContentLoadResult({required this.payload, required this.languageMissing});
}

/// Domain-layer contract. The presentation layer depends only on this —
/// never on `ApiClient` or `LocalStore` directly. `ContentRepositoryImpl`
/// (data layer) is the only class allowed to know an HTTP call exists.
abstract class ContentRepository {
  /// Implements the full caching contract (§4): reads the on-disk cache
  /// first, then checks the version endpoint (throttled to once per 30
  /// minutes unless [forceLanguageSwitch]), and only fetches the full
  /// payload when the version actually changed.
  Future<ContentLoadResult> loadContent(String lang, {bool forceLanguageSwitch = false});
}
