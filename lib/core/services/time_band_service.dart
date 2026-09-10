import '../../domain/entities/content_entities.dart';

/// Computes the current time-of-day band from the server-supplied
/// boundaries. The server never filters by time — it ships the bands,
/// the device reads its own clock (§7).
class TimeBandService {
  TimeBandService._();

  static String currentBand(Map<String, TimeBandRange> bands, {DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    for (final entry in bands.entries) {
      if (entry.value.contains(hour)) return entry.key;
    }
    return 'always';
  }
}
