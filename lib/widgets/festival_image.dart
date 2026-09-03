import 'package:flutter/material.dart';

import '../models/festival.dart';
import 'gradient_tile.dart';

/// Renders a festival's real photo when available, falling back to the
/// gradient + icon placeholder tile otherwise.
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

  @override
  Widget build(BuildContext context) {
    final asset = festival.imageAsset;
    if (asset == null) {
      return GradientTile(
        colors: festival.gradient,
        icon: festival.icon,
        iconSize: iconSize,
        borderRadius: borderRadius,
      );
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => GradientTile(
          colors: festival.gradient,
          icon: festival.icon,
          iconSize: iconSize,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
