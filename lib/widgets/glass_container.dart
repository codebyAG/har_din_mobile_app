import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Frosted-glass surface — blurred backdrop + translucent tint. Use for
/// anything meant to float over content: nav bars, sheets, floating
/// headers. Clips to [borderRadius] so the blur doesn't bleed past edges.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final Color tint;
  final double tintOpacity;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.blur = 18,
    this.tint = Colors.white,
    this.tintOpacity = 0.65,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: tint.withValues(alpha: tintOpacity),
            borderRadius: borderRadius,
            border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Same effect, tuned for the app's warm cream tone rather than plain white.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: borderRadius,
      tint: AppColors.card,
      tintOpacity: 0.55,
      child: Padding(padding: padding, child: child),
    );
  }
}
