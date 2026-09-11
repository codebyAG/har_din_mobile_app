import 'package:flutter/foundation.dart';

import '../../data/datasources/local/local_store.dart';

/// The single source of truth for which language the app runs in. Its
/// `code` (`hi`/`en`/`mr`) is exactly the `?lang=` the API contract (§3)
/// asks for, and — once chosen on the language-select screen — is
/// persisted and reused "forever" (§5), never re-prompted.
///
/// Registered as a `ChangeNotifierProvider` in main.dart. Widgets read it
/// with `context.watch<AppLanguageController>()`/`Consumer`, never via a
/// singleton.
class AppLanguageController extends ChangeNotifier {
  final LocalStore _store;

  AppLanguageController({LocalStore store = const LocalStore()}) : _store = store {
    _hydrate();
  }

  String _code = 'hi';
  String get code => _code;

  bool _hydrated = false;
  bool get hydrated => _hydrated;

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
}
