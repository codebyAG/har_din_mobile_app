import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/content_entities.dart';
import 'app_review_service.dart';
import 'event_queue.dart';
import 'image_cache_service.dart';

/// §2 — the share path is priority one: no compositing, no watermark in
/// v1, the file shared/downloaded is exactly the `display_url` file (or,
/// for bundled/offline content with no API design, the bundled asset
/// itself — same real share sheet, no dead end either way).
/// Events fire AFTER the share sheet / gallery write, never blocking it.
class ShareService {
  ShareService._();

  static const MethodChannel _channel = MethodChannel('har_din/whatsapp_share');

  static Future<ShareResultStatus> shareDesign(Design design) async {
    final file = await ImageCacheService.instance.getSingleFile(design.displayUrl);
    final result = await _share(file);
    if (result == ShareResultStatus.success) {
      await EventQueue.instance.record(HarDinEventType.shareComplete, designId: design.id);
      unawaited(AppReviewService.maybePromptAfterShare());
    }
    return result;
  }

  /// Returns true on success. Throws nothing — permission/storage
  /// failures are caught and reported back as `false` so the caller can
  /// show one snackbar instead of an uncaught error.
  static Future<bool> downloadDesign(Design design) async {
    try {
      final file = await ImageCacheService.instance.getSingleFile(design.displayUrl);
      final ok = await _download(file);
      if (ok) {
        await EventQueue.instance.record(HarDinEventType.downloadComplete, designId: design.id);
        unawaited(AppReviewService.maybePromptAfterShare());
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  static Future<ShareResultStatus> shareAsset(String assetPath, {String? id}) async {
    final file = await _fileFromAsset(assetPath);
    final result = await _share(file);
    if (result == ShareResultStatus.success) {
      await EventQueue.instance.record(HarDinEventType.shareComplete, designId: id);
      unawaited(AppReviewService.maybePromptAfterShare());
    }
    return result;
  }

  static Future<bool> downloadAsset(String assetPath, {String? id}) async {
    try {
      final file = await _fileFromAsset(assetPath);
      final ok = await _download(file);
      if (ok) {
        await EventQueue.instance.record(HarDinEventType.downloadComplete, designId: id);
        unawaited(AppReviewService.maybePromptAfterShare());
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Shares any local image file (e.g. a locally rendered quote/text
  /// status — see QuoteMakerScreen) through the same real share sheet,
  /// with the same event + review-prompt wiring as a catalogue design.
  /// [eventId] is what gets attached to the `share_complete` event —
  /// pass something stable if this file represents a real thing, or
  /// leave it null for one-off local creations with no catalogue id.
  static Future<ShareResultStatus> shareLocalFile(File file, {String? eventId}) async {
    final result = await _share(file);
    if (result == ShareResultStatus.success) {
      await EventQueue.instance.record(HarDinEventType.shareComplete, designId: eventId);
      unawaited(AppReviewService.maybePromptAfterShare());
    }
    return result;
  }

  static Future<bool> downloadLocalFile(File file, {String? eventId}) async {
    try {
      final ok = await _download(file);
      if (ok) {
        await EventQueue.instance.record(HarDinEventType.downloadComplete, designId: eventId);
        unawaited(AppReviewService.maybePromptAfterShare());
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Android only — skips the OS "choose an app" sheet and hands the
  /// file straight to WhatsApp, landing on WhatsApp's own forward screen
  /// (Status is one of the picks there; Meta doesn't expose a way to
  /// pre-select it from outside their app). Falls back to the normal
  /// share sheet — returns `false`, doesn't throw — if WhatsApp isn't
  /// installed or the OS refuses the intent for any reason.
  static Future<bool> shareToWhatsAppDirect(File file, {String? eventId}) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('shareToWhatsApp', {'path': file.path}) ?? false;
      if (ok) {
        await EventQueue.instance.record(HarDinEventType.shareComplete, designId: eventId);
        unawaited(AppReviewService.maybePromptAfterShare());
      }
      return ok;
    } on PlatformException {
      return false;
    }
  }

  static Future<ShareResultStatus> _share(File file) async {
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'हर दिन — Har Din, Kuch Share Karo'),
    );
    return result.status;
  }

  static Future<bool> _download(File file) async {
    final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
    if (!hasAccess) return false;
    await Gal.putImage(file.path, album: 'Har Din');
    return true;
  }

  static Future<File> _fileFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    return file;
  }
}
