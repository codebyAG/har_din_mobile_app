import 'package:flutter/foundation.dart';

import '../../data/datasources/local/local_store.dart';

/// Display-language enum for bilingual mock/bundled content (category
/// labels etc.) — a simplified view over [AppLanguageController.code],
/// kept only so widgets built before the real API existed keep compiling.
enum AppLanguage { hindi, english }

/// The single source of truth for which language the app runs in. Its
/// `code` (`hi`/`en`/`mr`) is exactly the `?lang=` the API contract (§3)
/// asks for, and — once chosen on the language-select screen — is
/// persisted and reused "forever" (§5), never re-prompted.
///
/// Registered as a `ChangeNotifierProvider` in main.dart. Widgets read it
/// with `context.watch<AppLanguageController>()`/`Consumer`, never via a
/// singleton — this is a Provider migration away from that pattern.
class AppLanguageController extends ChangeNotifier {
  final LocalStore _store;

  AppLanguageController({LocalStore store = const LocalStore()}) : _store = store {
    _hydrate();
  }

  String _code = 'hi';
  String get code => _code;

  bool _hydrated = false;
  bool get hydrated => _hydrated;

  /// Bilingual mock content only ever had Hindi/English copy — Marathi
  /// users see the Hindi labels for that content until it's migrated to
  /// the real API, where `mr` is already a first-class language.
  AppLanguage get language => _code == 'en' ? AppLanguage.english : AppLanguage.hindi;

  Future<void> _hydrate() async {
    final stored = await _store.getLanguage();
    if (stored != null) _code = stored;
    _hydrated = true;
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (_code == code) return;
    _code = code;
    await _store.setLanguage(code);
    notifyListeners();
  }

  /// Back-compat setter for the old bilingual display toggle in Settings.
  Future<void> setLanguage(AppLanguage language) =>
      setLanguageCode(language == AppLanguage.english ? 'en' : 'hi');
}
