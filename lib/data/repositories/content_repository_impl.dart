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
class ContentRepositoryImpl implements ContentRepository {
  final HarDinApiClient _api;
  final LocalStore _store;

  ContentPayload? _memoryCache;
  bool _hydratedFromDisk = false;

  ContentRepositoryImpl({required HarDinApiClient api, required LocalStore store})
      : _api = api,
        _store = store;

  @override
  Future<ContentLoadResult> loadContent(String lang, {bool forceLanguageSwitch = false}) async {
    if (!_hydratedFromDisk) {
      _memoryCache = await _store.readContent();
      _hydratedFromDisk = true;
    }

    if (!forceLanguageSwitch) {
      final lastCheck = await _store.getLastVersionCheck();
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck) < ApiConstants.minVersionRecheckInterval) {
        // render from local storage, stop — the common "cheap open" path
        return ContentLoadResult(payload: _memoryCache, languageMissing: false);
      }
    }

    return _checkVersionAndMaybeFetch(lang);
  }

  Future<ContentLoadResult> _checkVersionAndMaybeFetch(String lang) async {
    try {
      final version = await _api.fetchVersion(lang);
      await _store.setLastVersionCheck(DateTime.now());

      final storedVersion = await _store.getStoredVersion();
      if (storedVersion != null && storedVersion == version.content && _memoryCache != null) {
        return ContentLoadResult(payload: _memoryCache, languageMissing: false);
      }

      final fresh = await _api.fetchContent(lang);
      await _store.writeContent(fresh);
      await _store.setStoredVersion(fresh.version);
      _memoryCache = fresh;
      return ContentLoadResult(payload: _memoryCache, languageMissing: false);
    } on ApiNotFoundException {
      // §10 — language no longer exists server-side.
      return ContentLoadResult(payload: _memoryCache, languageMissing: true);
    } on ApiRateLimitedException {
      // §10 — back off silently, keep whatever is cached.
      return ContentLoadResult(payload: _memoryCache, languageMissing: false);
    } catch (_) {
      // §10 — timeout / no network / anything else: keep the old payload
      // and old version. Never partially apply, never surface an error.
      return ContentLoadResult(payload: _memoryCache, languageMissing: false);
    }
  }
}
