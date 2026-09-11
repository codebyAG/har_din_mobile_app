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
import '../widgets/religion_filter_chip.dart';
import 'preview_share_screen.dart';

/// My Creations — designs the user downloaded or favorited, read from
/// local storage only (§5); never sent to the server.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  static const _tabs = ['डाउनलोडेड', 'कस्टमाइज़्ड', 'फेवरेट'];
  String _selectedTab = 'डाउनलोडेड';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SavedDesignsController>();
    // कस्टमाइज़्ड — always empty, "coming soon" in v1: no editor exists
    // yet to have customized anything into (§5).
    final records = switch (_selectedTab) {
      'फेवरेट' => controller.favorites,
      'कस्टमाइज़्ड' => const [],
      _ => controller.downloaded,
    };

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('मेरी क्रिएशन्स', style: AppTextStyles.screenTitle()),
                      Text('My Creations', style: AppTextStyles.secondary()),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    itemCount: _tabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final tab = _tabs[i];
                      return ReligionFilterChip(
                        label: tab,
                        selected: tab == _selectedTab,
                        onTap: () => setState(() => _selectedTab = tab),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: records.isEmpty
                      ? _EmptyState(tab: _selectedTab)
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
                            childAspectRatio: 0.82,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: record.thumbnailUrl,
                    cacheManager: ImageCacheService.instance,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const GradientTile(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      icon: AppIcons.celebration,
                      iconSize: 30,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorited ? AppIcons.heartSolid : AppIcons.heartOutline,
                          size: 15,
                          color: isFavorited ? AppColors.like : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    '${record.savedAt.day}/${record.savedAt.month}/${record.savedAt.year}',
                    style: AppTextStyles.secondary(),
                  ),
                  const Spacer(),
                  const Icon(AppIcons.share, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String tab;

  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.lightAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.heartOutline, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'यहाँ अभी कुछ नहीं है',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              switch (tab) {
                'फेवरेट' => 'दिल के निशान पर टैप करके स्टेटस को फेवरेट बनाएं।',
                'कस्टमाइज़्ड' => 'कस्टमाइज़ फीचर जल्द आ रहा है।',
                _ => 'यहाँ आपके डाउनलोड किए स्टेटस दिखेंगे।',
              },
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary(),
            ),
          ],
        ),
      ),
    );
  }
}
