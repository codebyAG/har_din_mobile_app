import 'package:flutter/material.dart';

/// Stands in for real festival/status photography until actual assets
/// exist — a soft gradient with a symbolic icon and subtle decoration.
class GradientTile extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  final BorderRadius? borderRadius;
  final double iconSize;

  const GradientTile({
    super.key,
    required this.colors,
    required this.icon,
    this.borderRadius,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: -16,
              child: Icon(
                icon,
                size: iconSize * 2.2,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Center(
              child: Icon(
                icon,
                size: iconSize,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
