import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/content_entities.dart';

/// Everything the caching contract (§4) needs to remember between app
/// opens: selected language, the last-known content version, when we
/// last checked, the device id for analytics, and the payload itself.
class LocalStore {
  const LocalStore();

  static const _kLanguage = 'har_din.language';
  static const _kStoredVersion = 'har_din.stored_version';
  static const _kLastVersionCheck = 'har_din.last_version_check';
  static const _kDeviceId = 'har_din.device_id';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<File> _contentFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/har_din_content.json');
  }

  Future<File> _eventQueueFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/har_din_event_queue.json');
  }

  Future<File> _savedDesignsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/har_din_saved_designs.json');
  }

  // --- language ---

  Future<String?> getLanguage() async => (await _prefs).getString(_kLanguage);

  Future<void> setLanguage(String code) async => (await _prefs).setString(_kLanguage, code);

  // --- version / cache bookkeeping ---

  Future<int?> getStoredVersion() async => (await _prefs).getInt(_kStoredVersion);

  Future<void> setStoredVersion(int version) async =>
      (await _prefs).setInt(_kStoredVersion, version);

  Future<DateTime?> getLastVersionCheck() async {
    final millis = (await _prefs).getInt(_kLastVersionCheck);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastVersionCheck(DateTime time) async =>
      (await _prefs).setInt(_kLastVersionCheck, time.millisecondsSinceEpoch);

  // --- device id (analytics batching only — not an account) ---

  Future<String> getOrCreateDeviceId() async {
    final prefs = await _prefs;
    final existing = prefs.getString(_kDeviceId);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await prefs.setString(_kDeviceId, id);
    return id;
  }

  // --- content payload ---

  Future<ContentPayload?> readContent() async {
    try {
      final file = await _contentFile();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      return ContentPayload.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt cache — treat as empty so the app re-fetches instead of crashing.
      return null;
    }
  }

  Future<void> writeContent(ContentPayload payload) async {
    final file = await _contentFile();
    await file.writeAsString(jsonEncode(payload.toJson()));
  }

  // --- analytics event queue ---

  Future<List<Map<String, dynamic>>> readEventQueue() async {
    try {
      final file = await _eventQueueFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeEventQueue(List<Map<String, dynamic>> events) async {
    final file = await _eventQueueFile();
    await file.writeAsString(jsonEncode(events));
  }

  // --- My Creations: downloaded/favorited designs, local only (§5) ---
  // Stored as one JSON object with "downloads" and "favorites" arrays of
  // {id, categoryId, thumbnailUrl, displayUrl, savedAt} records — never
  // sent to the server, purely on-device.

  Future<Map<String, List<Map<String, dynamic>>>> _readSavedDesigns() async {
    try {
      final file = await _savedDesignsFile();
      if (!await file.exists()) return {'downloads': [], 'favorites': []};
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return {
        'downloads': (raw['downloads'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
        'favorites': (raw['favorites'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      };
    } catch (_) {
      return {'downloads': [], 'favorites': []};
    }
  }

  Future<void> _writeSavedDesigns(Map<String, List<Map<String, dynamic>>> data) async {
    final file = await _savedDesignsFile();
    await file.writeAsString(jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>> getDownloadedDesigns() async =>
      (await _readSavedDesigns())['downloads']!;

  Future<List<Map<String, dynamic>>> getFavoriteDesigns() async =>
      (await _readSavedDesigns())['favorites']!;

  Future<void> addDownloadedDesign(Map<String, dynamic> record) async {
    final data = await _readSavedDesigns();
    data['downloads']!.removeWhere((r) => r['id'] == record['id']);
    data['downloads']!.insert(0, record);
    await _writeSavedDesigns(data);
  }

  /// Returns the new favorited state (true = now favorited).
  Future<bool> toggleFavoriteDesign(Map<String, dynamic> record) async {
    final data = await _readSavedDesigns();
    final existed = data['favorites']!.any((r) => r['id'] == record['id']);
    if (existed) {
      data['favorites']!.removeWhere((r) => r['id'] == record['id']);
    } else {
      data['favorites']!.insert(0, record);
    }
    await _writeSavedDesigns(data);
    return !existed;
  }
}
