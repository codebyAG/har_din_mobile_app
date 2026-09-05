import 'package:flutter/foundation.dart';

enum AppLanguage { hindi, english }

/// App-wide language switch. Widgets showing bilingual content should
/// pick ONE label based on this instead of showing both languages
/// stacked — the Settings language picker updates it live.
class AppLanguageController extends ValueNotifier<AppLanguage> {
  AppLanguageController._() : super(AppLanguage.hindi);

  static final AppLanguageController instance = AppLanguageController._();
}
