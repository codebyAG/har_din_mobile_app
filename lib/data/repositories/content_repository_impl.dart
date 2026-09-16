import '../../core/constants/api_constants.dart';
import '../../core/error/api_exceptions.dart';
import '../../domain/entities/content_entities.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/local/local_store.dart';
import '../datasources/remote/har_din_api_client.dart';

/// Implements HAR-DIN-INTEGRATION.md §4 exactly: a version check at most
/// every 30 minutes, a full content fetch only when the version actually
/// changed, and "fail toward the cached copy, always" (§10) — a stale
/// library is a working app, an error dialog is not.
///
/// Everything below is keyed **per language** (APP-CHANGES-01 §3): two
/// languages can share a version number, so a single global "did the
/// version change" check would let a language switch silently reuse the
/// previous language's cached payload.
class ContentRepositoryImpl implements ContentRepository {
  final HarDinApiClient _api;
  final LocalStore _store;

  final Map<String, ContentPayload> _memoryCache = {};
  final Set<String> _hydratedLangs = {};

  ContentRepositoryImpl({required HarDinApiClient api, required LocalStore store})
      : _api = api,
        _store = store;

  @override
  Future<ContentLoadResult> loadContent(String lang, {bool forceLanguageSwitch = false}) async {
    if (!_hydratedLangs.contains(lang)) {
      final cached = await _store.readContent(lang);
      if (cached != null) _memoryCache[lang] = cached;
      _hydratedLangs.add(lang);
    }

    if (!forceLanguageSwitch) {
      final lastCheck = await _store.getLastVersionCheck(lang);
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck) < ApiConstants.minVersionRecheckInterval) {
        // render from local storage, stop — the common "cheap open" path
        return ContentLoadResult(payload: _memoryCache[lang], languageMissing: false);
      }
    }

    return _checkVersionAndMaybeFetch(lang);
  }

  @override
  Future<List<Language>> fetchLanguages() async {
    try {
      return await _api.fetchLanguages();
    } catch (_) {
      // §10 — fail toward nothing usable here; the caller (language
      // select) falls back to a hardcoded list rather than blocking.
      return const [];
    }
  }

  Future<ContentLoadResult> _checkVersionAndMaybeFetch(String lang) async {
    try {
      final version = await _api.fetchVersion(lang);
      await _store.setLastVersionCheck(lang, DateTime.now());

      final storedVersion = await _store.getStoredVersion(lang);
      if (storedVersion != null && storedVersion == version.content && _memoryCache[lang] != null) {
        return ContentLoadResult(payload: _memoryCache[lang], languageMissing: false);
      }

      final fresh = await _api.fetchContent(lang);
      await _store.writeContent(lang, fresh);
      await _store.setStoredVersion(lang, fresh.version);
      _memoryCache[lang] = fresh;
      return ContentLoadResult(payload: _memoryCache[lang], languageMissing: false);
    } on ApiNotFoundException {
      // §10 — language no longer exists server-side.
      return ContentLoadResult(payload: _memoryCache[lang], languageMissing: true);
    } on ApiRateLimitedException {
      // §10 — back off silently, keep whatever is cached.
      return ContentLoadResult(payload: _memoryCache[lang], languageMissing: false);
    } catch (_) {
      // §10 — timeout / no network / anything else: keep the old payload
      // and old version. Never partially apply, never surface an error.
      return ContentLoadResult(payload: _memoryCache[lang], languageMissing: false);
    }
  }
}
