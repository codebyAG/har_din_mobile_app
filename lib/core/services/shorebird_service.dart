import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Over-the-air Dart patches via Shorebird, checked once per app open.
///
/// Silent by design: a patch is downloaded in the background and applies
/// on the next cold start — no restart prompt, no blocking UI. When the
/// app wasn't built with `shorebird release` (debug runs, a plain
/// `flutter build`), [ShorebirdUpdater.checkForUpdate] reports
/// `unavailable` and this does nothing, so it is always safe to call.
///
/// Never throws and never surfaces an error — same "fail toward what
/// already works" posture as the content cache and [AppUpdateService].
class ShorebirdService {
  ShorebirdService._();

  static final ShorebirdUpdater _updater = ShorebirdUpdater();

  static Future<void> checkAndDownloadPatch(BuildContext context) async {
    try {
      if (!_updater.isAvailable) return;

      final status = await _updater.checkForUpdate();
      if (status != UpdateStatus.outdated) return;

      await _updater.update();
      developer.log(
        'patch downloaded, applies on next launch',
        name: 'ShorebirdService',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('नया अपडेट तैयार है — ऐप दोबारा खोलने पर लागू होगा'),
        ),
      );
    } on UpdateException catch (e) {
      developer.log('patch update failed: $e', name: 'ShorebirdService');
    } catch (e) {
      developer.log('patch check failed: $e', name: 'ShorebirdService');
    }
  }
}
