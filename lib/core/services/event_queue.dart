import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/error/api_exceptions.dart';
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
/// from a user action — events are queued and flushed in batches of up
/// to 200, on whichever comes first: ~20 queued, app backgrounding, or
/// the next app open (§8, APP-CHANGES-01 §4). A failure here must never
/// be visible to the user.
///
/// Kept as a simple infrastructure singleton (not DI-injected through
/// Provider) — it holds no UI-relevant reactive state, so nothing ever
/// watches it; it's a leaf service the same way a logger would be.
class EventQueue {
  EventQueue._();
  static final EventQueue instance = EventQueue._();

  static const int _flushThreshold = 20;
  static const int _maxBatchSize = 200;

  static final HarDinApiClient _api = HarDinApiClient();
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
      // UTC + 'Z' — a bare local-time string with no offset is invalid
      // per the contract and gets silently 400'd (APP-CHANGES-01 §4).
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    await _store.writeEventQueue(_pending);
    if (_pending.length >= _flushThreshold) {
      unawaited(flush());
    }
  }

  /// Sends everything queued, chunked at 200 per request, looping until
  /// the queue is drained or a retryable failure stops it. A batch the
  /// server rejects as malformed (400) is dropped, not retried — it will
  /// never succeed and would otherwise block every event behind it.
  Future<void> flush() async {
    await _ensureLoaded();
    final deviceId = await _store.getOrCreateDeviceId();

    while (_pending.isNotEmpty) {
      final batch = _pending.take(_maxBatchSize).toList();
      try {
        await _api.sendEvents(deviceId, batch);
        _pending.removeRange(0, batch.length);
        await _store.writeEventQueue(_pending);
      } on ApiBadRequestException {
        // Malformed and always will be — drop it so it can't wedge the
        // rest of the queue behind it, then keep going with what's left.
        _pending.removeRange(0, batch.length);
        await _store.writeEventQueue(_pending);
      } catch (_) {
        // Network error / 5xx — keep the whole queue, retry on the next
        // flush (§8). Stop looping; further attempts this call won't
        // succeed either.
        return;
      }
    }
  }
}
