import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../data/datasources/local/local_store.dart';
import '../../data/datasources/remote/har_din_api_client.dart';

/// The five event types the API accepts. `personalizeComplete` never
/// fires in v1 — kept in the enum because it's part of the contract (§8).
enum HarDinEventType {
  appOpen('app_open'),
  designView('design_view'),
  personalizeComplete('personalize_complete'),
  shareComplete('share_complete'),
  downloadComplete('download_complete');

  final String wireName;
  const HarDinEventType(this.wireName);
}

/// Local-first analytics queue. Never calls the server synchronously
/// from a user action — events are queued and flushed in batches of
/// up to 200, on whichever comes first: ~20 queued, background, or next
/// open (§8). A failure here must never be visible to the user.
///
/// Kept as a simple infrastructure singleton (not DI-injected through
/// Provider) — it holds no UI-relevant reactive state, so nothing ever
/// watches it; it's a leaf service the same way a logger would be.
class EventQueue {
  EventQueue._();
  static final EventQueue instance = EventQueue._();

  static const int _flushThreshold = 20;
  static const int _maxBatchSize = 200;

  static const HarDinApiClient _api = HarDinApiClient();
  static const LocalStore _store = LocalStore();

  final List<Map<String, dynamic>> _pending = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _pending.addAll(await _store.readEventQueue());
    _loaded = true;
  }

  Future<void> record(HarDinEventType type, {String? designId}) async {
    await _ensureLoaded();
    _pending.add({
      'id': const Uuid().v4(),
      'design_id': designId,
      'type': type.wireName,
      'at': DateTime.now().toIso8601String(),
    });
    await _store.writeEventQueue(_pending);
    if (_pending.length >= _flushThreshold) {
      unawaited(flush());
    }
  }

  Future<void> flush() async {
    await _ensureLoaded();
    if (_pending.isEmpty) return;
    final batch = _pending.take(_maxBatchSize).toList();
    try {
      final deviceId = await _store.getOrCreateDeviceId();
      await _api.sendEvents(deviceId, batch);
      _pending.removeRange(0, batch.length);
      await _store.writeEventQueue(_pending);
    } catch (_) {
      // Fire and forget — keep the queue, retry on the next flush (§8).
    }
  }
}
