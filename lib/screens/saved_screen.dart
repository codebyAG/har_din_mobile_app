import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/image_cache_service.dart';
import '../presentation/providers/saved_designs_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festive_glow.dart';
import '../widgets/gradient_tile.dart';
import '../widgets/shimmer_box.dart';
import 'preview_share_screen.dart';

/// My Creations — designs the user downloaded or favorited, read from
/// local storage only (§5); never sent to the server.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

enum _Tab { downloaded, customized, favorites }

class _SavedScreenState extends State<SavedScreen> {
  _Tab _selected = _Tab.downloaded;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SavedDesignsController>();
    // customized — always empty, "coming soon" in v1: no editor exists
    // yet to have customized anything into (§5).
    final records = switch (_selected) {
      _Tab.favorites => controller.favorites,
      _Tab.customized => const [],
      _Tab.downloaded => controller.downloaded,
    };

    // A real Scaffold (not just a colored background) — this screen is
    // both a bottom-nav tab (embedded in RootShell's own Scaffold) and a
    // standalone pushed route (from Profile), and the InkWell ripples
    // below need a Material ancestor either way; nesting Scaffolds is
    // fine in Flutter.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned(
            top: -30,
            left: -30,
            child: FestiveGlow(alignment: Alignment.topLeft, size: 200),
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
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(AppIcons.bookmarkSolid, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('मेरी क्रिएशन्स', style: AppTextStyles.screenTitle()),
                          Text(
                            '${controller.downloaded.length + controller.favorites.length} items',
                            style: AppTextStyles.secondary(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: _SegmentedTabBar(
                    selected: _selected,
                    downloadedCount: controller.downloaded.length,
                    favoriteCount: controller.favorites.length,
                    onSelect: (tab) => setState(() => _selected = tab),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: records.isEmpty
                      ? _EmptyState(tab: _selected)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            0,
                            AppSpacing.screenPadding,
                            AppSpacing.sectionGap,
                          ),
                          itemCount: records.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AppSpacing.cardGap,
                            crossAxisSpacing: AppSpacing.cardGap,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, i) {
                            final record = records[i];
                            return _CreationCard(
                              record: record,
                              isFavorited: controller.isFavorite(record.id),
                              onFavorite: () => controller.toggleFavorite(record.toDesign()),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PreviewShareScreen(design: record.toDesign()),
                                ),
                              ),
                            );
                          },
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

class _SegmentedTabBar extends StatelessWidget {
  final _Tab selected;
  final int downloadedCount;
  final int favoriteCount;
  final ValueChanged<_Tab> onSelect;

  const _SegmentedTabBar({
    required this.selected,
    required this.downloadedCount,
    required this.favoriteCount,
    required this.onSelect,
  });

  static const _tabs = [
    (tab: _Tab.downloaded, label: 'डाउनलोडेड'),
    (tab: _Tab.customized, label: 'कस्टमाइज़्ड'),
    (tab: _Tab.favorites, label: 'फेवरेट'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = _tabs.indexWhere((t) => t.tab == selected);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightAccent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / _tabs.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment(-1 + (index * 2 / (_tabs.length - 1)), 0),
                child: Container(
                  width: segmentWidth,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final entry in _tabs)
                    SizedBox(
                      width: segmentWidth,
                      height: 36,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () => onSelect(entry.tab),
                          child: Center(
                            child: Text(
                              entry.label,
                              style: AppTextStyles.secondary(
                                color: entry.tab == selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ).copyWith(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreationCard extends StatelessWidget {
  final SavedDesignRecord record;
  final bool isFavorited;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const _CreationCard({
    required this.record,
    required this.isFavorited,
    required this.onFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.card,
        child: InkWell(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: record.thumbnailUrl,
                  cacheManager: ImageCacheService.instance,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerPlaceholder(),
                  errorWidget: (context, url, error) => const GradientTile(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    icon: AppIcons.celebration,
                    iconSize: 30,
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
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorited ? AppIcons.heartSolid : AppIcons.heartOutline,
                        size: 14,
                        color: isFavorited ? AppColors.like : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.download,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${record.savedAt.day}/${record.savedAt.month}/${record.savedAt.year}',
                        style: AppTextStyles.secondary(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w600, fontSize: 11.5),
                      ),
                      const Spacer(),
                      Icon(AppIcons.share, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _Tab tab;

  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (tab) {
      _Tab.favorites => (
          AppIcons.heartOutline,
          'दिल के निशान पर टैप करके स्टेटस को फेवरेट बनाएं।',
        ),
      _Tab.customized => (AppIcons.edit, 'कस्टमाइज़ फीचर जल्द आ रहा है।'),
      _Tab.downloaded => (AppIcons.download, 'यहाँ आपके डाउनलोड किए स्टेटस दिखेंगे।'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.35),
                    AppColors.primary.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'यहाँ अभी कुछ नहीं है',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.secondary()),
          ],
        ),
      ),
    );
  }
}
