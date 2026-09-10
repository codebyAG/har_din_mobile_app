import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/content_entities.dart';
import 'event_queue.dart';
import 'image_cache_service.dart';

/// §2 — the share path is priority one: no compositing, no watermark in
/// v1, the file shared/downloaded is exactly the `display_url` file.
/// Events fire AFTER the share sheet / gallery write, never blocking it.
class ShareService {
  ShareService._();

  static Future<ShareResultStatus> shareDesign(Design design) async {
    final file = await ImageCacheService.instance.getSingleFile(design.displayUrl);
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'हर दिन — Har Din, Kuch Share Karo'),
    );
    if (result.status == ShareResultStatus.success) {
      // Fire after the share sheet completed — never blocks it (§2, §8).
      await EventQueue.instance.record(HarDinEventType.shareComplete, designId: design.id);
    }
    return result.status;
  }

  /// Returns true on success. Throws nothing — permission/storage
  /// failures are caught and reported back as `false` so the caller can
  /// show one snackbar instead of an uncaught error.
  static Future<bool> downloadDesign(Design design) async {
    try {
      final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
      if (!hasAccess) return false;
      final file = await ImageCacheService.instance.getSingleFile(design.displayUrl);
      await Gal.putImage(file.path, album: 'Har Din');
      await EventQueue.instance.record(HarDinEventType.downloadComplete, designId: design.id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
