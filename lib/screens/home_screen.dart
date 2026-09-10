import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/time_band_service.dart';
import '../core/utils/occasion_mapper.dart';
import '../data/mock_data.dart';
import '../domain/entities/content_entities.dart';
import '../models/festival.dart';
import '../models/home_category.dart';
import '../models/promo_banner.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/category_grid_tile.dart';
import '../widgets/festive_glow.dart';
import '../widgets/promo_banner_carousel.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_box.dart';
import 'category_detail_screen.dart';
import 'status_gallery_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _categoryPalette = [
    [Color(0xFF75665D), Color(0xFFF4B942)],
    [AppColors.secondary, AppColors.primary],
    [Color(0xFFE53935), Color(0xFFF4B942)],
    [Color(0xFF2E9B55), Color(0xFFF4B942)],
    [AppColors.primary, AppColors.primaryDark],
  ];

  List<PromoBanner> _banners(ContentPayload? payload) {
    if (payload == null || payload.banners.isEmpty) return MockData.promoBanners;
    final sorted = payload.banners.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.map((b) => PromoBanner(id: b.id, imageUrl: b.imageUrl)).toList();
  }

  List<HomeCategory> _categories(ContentPayload? payload) {
    if (payload == null || payload.categories.isEmpty) return MockData.homeCategories;
    final top = payload.categories.where((c) => c.parentId == null).toList();
    final order = payload.home.categoryOrder;
    top.sort((a, b) {
      final ai = order.indexOf(a.id);
      final bi = order.indexOf(b.id);
      if (ai != -1 || bi != -1) {
        return (ai == -1 ? 1 << 30 : ai).compareTo(bi == -1 ? 1 << 30 : bi);
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    if (top.isEmpty) return MockData.homeCategories;
    return [
      for (var i = 0; i < top.length; i++)
        HomeCategory(
          id: top[i].id,
          hindiLabel: top[i].name,
          englishLabel: top[i].name,
          apiName: top[i].name,
          iconUrl: top[i].iconUrl,
          icon: AppIcons.celebration,
          gradient: _categoryPalette[i % _categoryPalette.length],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContentViewModel>();
    final payload = viewModel.payload;

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
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(AppIcons.menu, size: 20, color: AppColors.textPrimary),
                      ),
                      Expanded(
                        child: Image.asset(
                          'assets/horizontal_app_logo_transparent.png',
                          height: 34,
                        ),
                      ),
                      // Notification bell removed — push is post-v1 (§5).
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
                              banners: _banners(payload),
                              onTap: (banner) => _onBannerTap(context, banner, payload),
                            ),
                          ),
                        ),
                        if (payload != null && payload.occasions.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _OccasionsSection(occasions: payload.occasions),
                          ),
                        if (payload != null)
                          SliverToBoxAdapter(
                            child: _TimeBandSection(payload: payload),
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
                          sliver: Builder(builder: (context) {
                            final categories = _categories(payload);
                            return SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                childAspectRatio: 0.72,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final category = categories[i];
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
                                childCount: categories.length,
                              ),
                            );
                          }),
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

  void _onBannerTap(BuildContext context, PromoBanner banner, ContentPayload? payload) {
    if (payload != null && payload.banners.isNotEmpty) {
      final apiBanner = payload.banners.firstWhere(
        (b) => b.id == banner.id,
        orElse: () => payload.banners.first,
      );
      if (apiBanner.target == 'category' && apiBanner.targetRef.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StatusGalleryScreen(
              festival: Festival(
                id: apiBanner.targetRef,
                name: '',
                date: '',
                religion: '',
                daysLeft: 0,
                gradient: const [AppColors.primary, AppColors.primaryDark],
                icon: AppIcons.celebration,
                apiCategoryId: apiBanner.targetRef,
              ),
            ),
          ),
        );
      }
      return;
    }

    // Mock fallback banners — only Diwali/WhatsApp still lead anywhere;
    // Customize and Feed are unreachable in v1 (§5).
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
      case 'whatsapp':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StatusGalleryScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('यह फीचर जल्द आ रहा है')),
        );
    }
  }
}

class _OccasionsSection extends StatelessWidget {
  final List<Occasion> occasions;

  const _OccasionsSection({required this.occasions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = occasions.toList()
      ..sort((a, b) => a.daysUntil(now).compareTo(b.daysUntil(now)));
    final relevant = upcoming.where((o) => o.daysUntil(now) >= 0).take(6).toList();
    if (relevant.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: SectionHeader(
              title: relevant.first.daysUntil(now) == 0 ? 'आज' : 'आने वाले त्योहार',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              itemCount: relevant.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final occasion = relevant[i];
                final days = occasion.daysUntil(now);
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StatusGalleryScreen(
                        festival: OccasionMapper.fromOccasion(occasion, now: now),
                      ),
                    ),
                  ),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.lightAccent,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          occasion.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          days == 0 ? 'आज है' : '$days दिन बाकी',
                          style: AppTextStyles.secondary(color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBandSection extends StatelessWidget {
  final ContentPayload payload;

  const _TimeBandSection({required this.payload});

  @override
  Widget build(BuildContext context) {
    final band = TimeBandService.currentBand(payload.timeBands);
    final ids = payload.home.timeBandCategories[band] ?? const <String>[];
    final matched = payload.categories.where((c) => ids.contains(c.id)).toList();
    if (matched.isEmpty) return const SizedBox.shrink();

    const heading = {
      'morning': 'सुप्रभात के लिए',
      'afternoon': 'दोपहर के लिए',
      'evening': 'शाम के लिए',
      'night': 'शुभ रात्रि के लिए',
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: SectionHeader(title: heading[band] ?? 'अभी के लिए'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              itemCount: matched.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final category = matched[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(
                        category: HomeCategory(
                          id: category.id,
                          hindiLabel: category.name,
                          englishLabel: category.name,
                          apiName: category.name,
                          iconUrl: category.iconUrl,
                          icon: AppIcons.celebration,
                          gradient: const [AppColors.secondary, AppColors.primary],
                        ),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(category.name, style: AppTextStyles.secondary()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
