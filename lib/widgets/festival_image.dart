import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/services/image_cache_service.dart';
import '../models/festival.dart';
import 'gradient_tile.dart';

/// Renders a festival's real photo when available — network `image_url`
/// first (real occasions), then the bundled asset (mock festivals) —
/// falling back to the gradient + icon placeholder tile otherwise.
class FestivalImage extends StatelessWidget {
  final Festival festival;
  final double iconSize;
  final BorderRadius? borderRadius;

  const FestivalImage({
    super.key,
    required this.festival,
    this.iconSize = 32,
    this.borderRadius,
  });

  Widget _fallback() => GradientTile(
        colors: festival.gradient,
        icon: festival.icon,
        iconSize: iconSize,
        borderRadius: borderRadius,
      );

  @override
  Widget build(BuildContext context) {
    final url = festival.imageUrl;
    if (url != null) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: url,
          cacheManager: ImageCacheService.instance,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorWidget: (context, url, error) => _fallback(),
        ),
      );
    }

    final asset = festival.imageAsset;
    if (asset == null) return _fallback();

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      ),
    );
  }
}
