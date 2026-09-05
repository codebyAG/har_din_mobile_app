import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A soft, blurred glow tucked behind a screen's header — the "20% festive
/// decoration" the brand calls for, kept subtle enough that it reads as
/// premium ambience rather than clutter. Place at the top of a Stack.
class FestiveGlow extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const FestiveGlow({
    super.key,
    this.alignment = Alignment.topRight,
    this.size = 220,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
