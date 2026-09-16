import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/image_cache_service.dart';
import '../core/services/time_band_service.dart';
import '../core/utils/occasion_mapper.dart';
import '../domain/entities/content_entities.dart';
import '../models/festival.dart';
import '../models/home_category.dart';
import '../models/promo_banner.dart';
import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/category_grid_tile.dart';
import '../widgets/festive_glow.dart';
import '../widgets/gradient_tile.dart';
import '../widgets/promo_banner_carousel.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_box.dart';
import 'category_detail_screen.dart';
import 'preview_share_screen.dart';
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

  List<PromoBanner> _banners(ContentPayload payload) {
    final sorted = payload.banners.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.map((b) => PromoBanner(id: b.id, imageUrl: b.imageUrl)).toList();
  }

  List<HomeCategory> _categories(ContentPayload payload) {
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
    return [
      for (var i = 0; i < top.length; i++)
        HomeCategory(
          id: top[i].id,
          name: top[i].name,
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
                  child: payload == null
                      ? _LoadingOrError(
                          isLoading: viewModel.isLoading,
                          loadFailedText: viewModel.t('home.load_failed'),
                          retryText: viewModel.t('common.retry'),
                          onRetry: () => viewModel.load(
                            context.read<AppLanguageController>().code,
                          ),
                        )
                      : ShimmerReveal(
                          skeleton: _HomeSkeleton(),
                          child: _HomeContent(
                            payload: payload,
                            banners: _banners(payload),
                            categories: _categories(payload),
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
}

class _LoadingOrError extends StatelessWidget {
  final bool isLoading;
  final String loadFailedText;
  final String retryText;
  final VoidCallback onRetry;

  const _LoadingOrError({
    required this.isLoading,
    required this.loadFailedText,
    required this.retryText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loadFailedText, textAlign: TextAlign.center, style: AppTextStyles.secondary()),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                retryText,
                style: AppTextStyles.body(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final ContentPayload payload;
  final List<PromoBanner> banners;
  final List<HomeCategory> categories;

  const _HomeContent({
    required this.payload,
    required this.banners,
    required this.categories,
  });

  void _onBannerTap(BuildContext context, PromoBanner banner) {
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
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<ContentViewModel>().t('common.coming_soon'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ContentViewModel>().t;
    return CustomScrollView(
      slivers: [
        if (banners.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: PromoBannerCarousel(
                banners: banners,
                onTap: (banner) => _onBannerTap(context, banner),
              ),
            ),
          ),
        if (payload.occasions.isNotEmpty)
          SliverToBoxAdapter(
            child: _OccasionsSection(occasions: payload.occasions),
          ),
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
        if (categories.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(t('home.no_categories'), style: AppTextStyles.secondary()),
              ),
            ),
          )
        else
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
                childAspectRatio: 0.66,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final category = categories[i];
                  return CategoryGridTile(
                    category: category,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(category: category),
                      ),
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _OccasionsSection extends StatelessWidget {
  final List<Occasion> occasions;

  const _OccasionsSection({required this.occasions});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ContentViewModel>().t;
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
              title: relevant.first.daysUntil(now) == 0
                  ? t('home.today')
                  : t('home.upcoming_festivals'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              itemCount: relevant.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final occasion = relevant[i];
                final days = occasion.daysUntil(now);
                final festival = OccasionMapper.fromOccasion(occasion, now: now);
                final urgent = days <= 2;

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StatusGalleryScreen(festival: festival),
                    ),
                  ),
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: festival.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: festival.gradient.last.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          right: -18,
                          bottom: -18,
                          child: Icon(
                            festival.icon,
                            size: 92,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: urgent
                                    ? const [Color(0xFFFF7A70), AppColors.like]
                                    : const [AppColors.secondary, AppColors.primary],
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: (urgent ? AppColors.like : AppColors.primary)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              days == 0 ? t('festival.today') : t('festival.days_left', {'n': '$days'}),
                              style: AppTextStyles.secondary(color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w700, fontSize: 10.5),
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppSpacing.sm,
                          right: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: Text(
                            occasion.name,
                            maxLines: 2,
                            style: AppTextStyles.cardTitle(color: Colors.white).copyWith(
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
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

/// APP-CHANGES-01 §1 — the band section renders its designs inline
/// (thumbnail strip, tap → Preview & Share directly), not a chip that
/// leads to a second screen. §6 — if the matched categories have no
/// designs for the current band, fall back to `home.carousel_category_id`
/// rather than rendering an empty section.
class _TimeBandSection extends StatelessWidget {
  final ContentPayload payload;

  const _TimeBandSection({required this.payload});

  List<Design> _designsFor(String band) {
    final ids = payload.home.timeBandCategories[band] ?? const <String>[];
    var pool = payload.designs
        .where((d) => ids.contains(d.categoryId) && d.matchesBand(band))
        .toList();

    if (pool.isEmpty && payload.home.carouselCategoryId != null) {
      pool = payload.designs
          .where((d) => d.categoryId == payload.home.carouselCategoryId && d.matchesBand(band))
          .toList();
    }

    pool.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return pool;
  }

  static const _bandStyle = {
    'morning': (icon: AppIcons.sun, gradient: [AppColors.secondary, AppColors.primary]),
    'afternoon': (
      icon: AppIcons.goodDay,
      gradient: [Color(0xFF6FA8E8), Color(0xFF3D6FC2)],
    ),
    'evening': (
      icon: AppIcons.goodDay,
      gradient: [Color(0xFFFF8A3D), AppColors.primaryDark],
    ),
    'night': (icon: AppIcons.moon, gradient: [Color(0xFF3A2418), Color(0xFF6E6153)]),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ContentViewModel>().t;
    final band = TimeBandService.currentBand(payload.timeBands);
    final designs = _designsFor(band);
    if (designs.isEmpty) return const SizedBox.shrink();

    final headingKey = switch (band) {
      'morning' => 'home.band.morning',
      'afternoon' => 'home.band.afternoon',
      'evening' => 'home.band.evening',
      'night' => 'home.band.night',
      _ => 'home.band.default',
    };
    final style = _bandStyle[band] ??
        (icon: AppIcons.celebration, gradient: [AppColors.secondary, AppColors.primary]);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: style.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: style.gradient.last.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(style.icon, size: 15, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(t(headingKey), style: AppTextStyles.sectionHeading()),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 152,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              itemCount: designs.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final design = designs[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PreviewShareScreen(design: design)),
                  ),
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: design.thumbnailUrl,
                          cacheManager: ImageCacheService.instance,
                          fit: BoxFit.cover,
                          memCacheWidth: 220,
                          errorWidget: (context, url, error) => GradientTile(
                            colors: style.gradient,
                            icon: style.icon,
                            iconSize: 24,
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: style.gradient),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(AppIcons.share, size: 11, color: Colors.white),
                          ),
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
              childAspectRatio: 0.66,
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
