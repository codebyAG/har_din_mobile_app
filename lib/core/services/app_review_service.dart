import 'dart:developer' as developer;

import 'package:in_app_review/in_app_review.dart';

import '../../data/datasources/local/local_store.dart';

/// In-app rating prompt — Play Store's / App Store's own native review
/// sheet, asked at most **once**, and only after the user has actually
/// completed a real share (never right after install, never after a
/// failure). Fire-and-forget: never blocks the share it rides on, never
/// surfaces an error if the OS declines to show it (both stores throttle
/// this server-side regardless of what the app asks for).
class AppReviewService {
  AppReviewService._();

  static const int _promptAfterShareCount = 3;
  static const LocalStore _store = LocalStore();

  /// Call after every successful share/download. No-ops instantly unless
  /// this is exactly the share that should trigger the one-time prompt.
  static Future<void> maybePromptAfterShare() async {
    try {
      final count = await _store.incrementShareCount();
      if (count != _promptAfterShareCount) return;
      if (await _store.hasPromptedReview()) return;

      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) return;

      await _store.setPromptedReview();
      await inAppReview.requestReview();
    } catch (e) {
      developer.log('review prompt failed: $e', name: 'AppReviewService');
    }
  }
}
