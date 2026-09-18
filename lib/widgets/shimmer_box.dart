import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

/// Wraps skeleton content in the shimmer sweep. Plain grey, everywhere —
/// the standard loading look, used identically across every screen.
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF2F2F2),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Drop-in `placeholder:` for any `CachedNetworkImage` — fills whatever
/// box the image is given (explicit width/height, `Expanded`,
/// `Positioned.fill`, ...) with the shimmer sweep instead of a blank gap
/// while the real image downloads.
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(child: ColoredBox(color: Colors.white));
  }
}

/// Shows [skeleton] until the content is actually ready, then crossfades
/// into [child]. Pass [loading] wherever a real loading flag exists
/// (`ContentViewModel.isLoading`, etc.) so the shimmer reflects real data
/// loading rather than a guess; omit it and this falls back to a short
/// fixed beat, for screens with no real loading signal of their own.
class ShimmerReveal extends StatefulWidget {
  final Widget skeleton;
  final Widget child;
  final Duration delay;
  final bool? loading;

  const ShimmerReveal({
    super.key,
    required this.skeleton,
    required this.child,
    this.delay = const Duration(milliseconds: 650),
    this.loading,
  });

  @override
  State<ShimmerReveal> createState() => _ShimmerRevealState();
}

class _ShimmerRevealState extends State<ShimmerReveal> {
  bool _timerReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.loading == null) {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _timerReady = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.loading != null ? !widget.loading! : _timerReady;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: ready
          ? KeyedSubtree(key: const ValueKey('content'), child: widget.child)
          : KeyedSubtree(
              key: const ValueKey('skeleton'),
              child: AppShimmer(child: widget.skeleton),
            ),
    );
  }
}
