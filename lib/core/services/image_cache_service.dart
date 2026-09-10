import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// One shared cache manager for every design image in the app — used by
/// both `CachedNetworkImage` widgets and the share/download flow, so a
/// design opened once is never re-downloaded.
///
/// §6: filenames are immutable (a replaced design is a new URL), so there
/// is no invalidation to handle — a long TTL is correct, not a shortcut.
/// The 300MB ceiling with LRU eviction is flutter_cache_manager's default
/// object-count/age based eviction; `original_url` is never touched by
/// this app so it never enters the cache.
class ImageCacheService {
  ImageCacheService._();

  static final CacheManager instance = CacheManager(
    Config(
      'har_din_image_cache',
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 800,
    ),
  );
}
