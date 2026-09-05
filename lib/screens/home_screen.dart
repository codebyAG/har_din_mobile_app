import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/promo_banner.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../widgets/category_grid_tile.dart';
import '../widgets/festive_glow.dart';
import '../widgets/promo_banner_carousel.dart';
import '../widgets/shimmer_box.dart';
import 'category_detail_screen.dart';
import 'customize_screen.dart';
import 'feed_screen.dart';
import 'status_gallery_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          const Positioned(
            top: -40,
            right: -40,
            child: FestiveGlow(size: 260),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('मेनू जल्द आ रहा है')),
                        ),
                        icon: const Icon(AppIcons.menu, size: 20, color: AppColors.textPrimary),
                      ),
                      Expanded(
                        child: Image.asset(
                          'assets/horizontal_app_logo_transparent.png',
                          height: 34,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('कोई नई सूचना नहीं')),
                            ),
                            icon: const Icon(
                              AppIcons.bell,
                              size: 19,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.like,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.lightAccent,
                        child: Icon(AppIcons.account, size: 15, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ShimmerReveal(
                    skeleton: _HomeSkeleton(),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          sliver: SliverToBoxAdapter(
                            child: PromoBannerCarousel(
                              banners: MockData.promoBanners,
                              onTap: (banner) => _onBannerTap(context, banner),
                            ),
                          ),
                        ),
                        const SliverPadding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          sliver: SliverToBoxAdapter(
                            child: Image(
                              image: AssetImage(
                                'assets/categories_heading_home_screen_transparent.png',
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            0,
                            AppSpacing.screenPadding,
                            AppSpacing.sectionGap,
                          ),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final category = MockData.homeCategories[i];
                                return CategoryGridTile(
                                  category: category,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CategoryDetailScreen(category: category),
                                    ),
                                  ),
                                );
                              },
                              childCount: MockData.homeCategories.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onBannerTap(BuildContext context, PromoBanner banner) {
    switch (banner.id) {
      case 'diwali':
        final diwali = MockData.festivals.firstWhere(
          (f) => f.id == 'diwali',
          orElse: () => MockData.festivals.first,
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StatusGalleryScreen(festival: diwali)),
        );
        break;
      case 'customize':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomizeScreen(festival: MockData.festivals.first),
          ),
        );
        break;
      case 'quote':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FeedScreen()),
        );
        break;
      case 'whatsapp':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StatusGalleryScreen()),
        );
        break;
    }
  }
}

class _HomeSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        children: [
          const ShimmerBox(height: 64, width: double.infinity),
          const SizedBox(height: AppSpacing.xl),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, i) => const ShimmerBox(
              height: double.infinity,
              width: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
