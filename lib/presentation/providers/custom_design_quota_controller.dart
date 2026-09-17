import 'package:flutter/foundation.dart';

import '../../data/datasources/local/local_store.dart';

/// Daily quota for the voice "अपना कस्टम डिज़ाइन बनाएं" flow — 1 free
/// design a day; the paid tier (up to 10/day) isn't wired to a real
/// payment yet, so it's surfaced as a disabled "coming soon" upsell
/// rather than faked open (no dummy unlocks in this app).
///
/// Local-only, per-device — there are no accounts in v1 (§5).
class CustomDesignQuotaController extends ChangeNotifier {
  static const int freeLimitPerDay = 1;

  final LocalStore _store;

  CustomDesignQuotaController({LocalStore store = const LocalStore()}) : _store = store {
    _hydrate();
  }

  int _usedToday = 0;
  int get usedToday => _usedToday;

  bool _hydrated = false;
  bool get hydrated => _hydrated;

  int get remainingToday => (freeLimitPerDay - _usedToday).clamp(0, freeLimitPerDay);
  bool get canUseToday => _usedToday < freeLimitPerDay;

  Future<void> _hydrate() async {
    _usedToday = await _store.getCustomDesignUsesToday();
    _hydrated = true;
    notifyListeners();
  }

  /// Call once a design has actually been picked/handed to the user —
  /// not just for opening the mic or running a search.
  Future<void> recordUse() async {
    await _store.recordCustomDesignUse();
    _usedToday = await _store.getCustomDesignUsesToday();
    notifyListeners();
  }
}
