import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app update, once per app open. Android uses Play Core's real
/// In-App Update API (the app must actually be installed from Play
/// Store for it to find anything — it fails silently everywhere else,
/// e.g. a sideloaded debug build). iOS has no equivalent OS API, so it
/// compares the installed version against the App Store's own iTunes
/// Lookup response — real data from Apple, never a guessed App Store id
/// or URL — and only prompts if that lookup actually returns a newer
/// version.
///
/// Never blocks app startup and never surfaces an error to the user —
/// same "fail toward what already works" posture as the content cache.
class AppUpdateService {
  AppUpdateService._();

  static Future<void> checkAndPrompt(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        await _checkAndroid(context);
      } else if (Platform.isIOS) {
        await _checkIOS(context);
      }
    } catch (e) {
      developer.log('update check failed: $e', name: 'AppUpdateService');
    }
  }

  static Future<void> _checkAndroid(BuildContext context) async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

    if (info.flexibleUpdateAllowed) {
      // Downloads in the background; the user keeps using the app and
      // is only asked to restart once it's actually ready.
      await InAppUpdate.startFlexibleUpdate();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(days: 1),
          content: const Text('नया अपडेट डाउनलोड हो गया है'),
          action: SnackBarAction(
            label: 'रीस्टार्ट करें',
            onPressed: () => InAppUpdate.completeFlexibleUpdate(),
          ),
        ),
      );
    } else if (info.immediateUpdateAllowed) {
      // Play Store itself has decided this update can't wait (e.g. the
      // publisher marked it as a required update) — hands off to the
      // full-screen native flow.
      await InAppUpdate.performImmediateUpdate();
    }
  }

  static Future<void> _checkIOS(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final dio = Dio();
    final res = await dio.get<Map<String, dynamic>>(
      'https://itunes.apple.com/lookup',
      queryParameters: {'bundleId': packageInfo.packageName},
      options: Options(sendTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8)),
    );
    final results = res.data?['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return; // not on the App Store yet

    final entry = results.first as Map<String, dynamic>;
    final storeVersion = entry['version'] as String?;
    final storeUrl = entry['trackViewUrl'] as String?;
    if (storeVersion == null || storeUrl == null) return;
    if (!_isNewer(storeVersion, packageInfo.version)) return;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('नया अपडेट उपलब्ध है'),
        content: const Text('हर दिन का नया वर्ज़न App Store पर उपलब्ध है।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('बाद में'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final uri = Uri.parse(storeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('अभी अपडेट करें'),
          ),
        ],
      ),
    );
  }

  /// Simple dotted-version comparison (`1.2.10` > `1.2.9`) — good enough
  /// for the standard `major.minor.patch` scheme both stores use.
  static bool _isNewer(String remote, String local) {
    final r = remote.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final l = local.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (var i = 0; i < r.length || i < l.length; i++) {
      final rv = i < r.length ? r[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (rv != lv) return rv > lv;
    }
    return false;
  }
}
