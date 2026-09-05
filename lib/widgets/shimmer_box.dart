import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// A single shimmering placeholder shape — a rounded rect by default.
/// Compose several into a skeleton that mirrors the real content's layout.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  const ShimmerBox.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = const BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Wraps skeleton content in the shimmer sweep. Base/highlight are tuned
/// to the app's warm cream palette rather than the library's cool grey
/// default, so the loading state still feels on-brand.
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.lightAccent,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Shows [skeleton] for a short beat, then crossfades into [child] — used
/// on every screen so first paint always feels intentional rather than
/// content just popping in.
class ShimmerReveal extends StatefulWidget {
  final Widget skeleton;
  final Widget child;
  final Duration delay;

  const ShimmerReveal({
    super.key,
    required this.skeleton,
    required this.child,
    this.delay = const Duration(milliseconds: 650),
  });

  @override
  State<ShimmerReveal> createState() => _ShimmerRevealState();
}

class _ShimmerRevealState extends State<ShimmerReveal> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _ready
          ? KeyedSubtree(key: const ValueKey('content'), child: widget.child)
          : KeyedSubtree(
              key: const ValueKey('skeleton'),
              child: AppShimmer(child: widget.skeleton),
            ),
    );
  }
}
