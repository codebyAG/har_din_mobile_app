import 'package:flutter/foundation.dart';

enum AppLanguage { hindi, english }

/// App-wide language switch. Widgets showing bilingual content read this
/// via `context.watch<AppLanguageController>()` and pick ONE label —
/// never show both languages stacked. Registered as a
/// `ChangeNotifierProvider` in main.dart.
///
/// Note: this is the *display* language toggle for content that only
/// exists bundled bilingually (mock category labels). Once a screen is
/// wired to the real API, its language instead comes from `?lang=`
/// (see the language-select screen) — the two will be unified when the
/// remaining mock-data screens are migrated.
class AppLanguageController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.hindi;
  AppLanguage get language => _language;

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }
}
