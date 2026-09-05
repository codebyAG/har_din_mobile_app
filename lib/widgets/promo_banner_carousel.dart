import 'dart:async';

import 'package:flutter/material.dart';

import '../models/promo_banner.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PromoBannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  final ValueChanged<PromoBanner> onTap;

  const PromoBannerCarousel({super.key, required this.banners, required this.onTap});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  static const double _aspectRatio = 1080 / 480;

  late final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients || widget.banners.length <= 1) return;
      final next = (_page + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute height from the width the banner actually renders at
        // (full width minus its own horizontal padding), not the outer
        // sliver width — otherwise BoxFit.cover crops into a mismatched
        // box instead of showing the image at its true proportions.
        final cardWidth = constraints.maxWidth - AppSpacing.screenPadding * 2;
        final cardHeight = cardWidth / _aspectRatio;

        return Column(
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final banner = widget.banners[i];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    child: GestureDetector(
                      onTap: () => widget.onTap(banner),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        child: Image.asset(
                          banner.imageAsset,
                          width: cardWidth,
                          height: cardHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
