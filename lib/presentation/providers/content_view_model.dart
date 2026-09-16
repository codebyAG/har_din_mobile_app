import 'package:flutter/foundation.dart';

import '../../core/localization/app_strings.dart';
import '../../domain/entities/content_entities.dart';
import '../../domain/repositories/content_repository.dart';

/// The only thing screens watch for content. Owns no HTTP/cache
/// knowledge itself — it just calls the repository interface and turns
/// the result into reactive state. Registered as a `ChangeNotifierProvider`
/// in main.dart; screens read it with `context.watch<ContentViewModel>()`,
/// never via setState.
class ContentViewModel extends ChangeNotifier {
  final ContentRepository _repository;

  ContentViewModel(this._repository);

  ContentPayload? _payload;
  ContentPayload? get payload => _payload;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _languageMissing = false;
  bool get languageMissing => _languageMissing;

  /// UI label lookup (APP-CHANGES-01 §2) — server's `strings` map for the
  /// current language, falling back to the bundled Hindi copy, never to
  /// a blank string.
  String t(String key, [Map<String, String>? args]) =>
      AppStrings.resolve(_payload?.strings, key, args);

  /// `GET /v1/languages` (§7) — for the language-select screen only.
  /// Never throws; an empty list means "fall back to the hardcoded set".
  Future<List<Language>> fetchLanguages() => _repository.fetchLanguages();

  /// Call once at startup (after language is chosen) and whenever the
  /// user explicitly changes language. Never call this on a screen
  /// change, tab switch, or pull-to-refresh of a single category.
  Future<void> load(String lang, {bool forceLanguageSwitch = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _repository.loadContent(lang, forceLanguageSwitch: forceLanguageSwitch);
      _payload = result.payload;
      _languageMissing = result.languageMissing;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
