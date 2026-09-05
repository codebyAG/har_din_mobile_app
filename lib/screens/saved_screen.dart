import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festive_glow.dart';
import '../widgets/festival_image.dart';
import '../widgets/religion_filter_chip.dart';
import '../widgets/shimmer_box.dart';
import 'preview_share_screen.dart';

/// My Creations — statuses the user has downloaded, customized, or
/// favourited. Backed by mock data today; the tab structure and per-item
/// actions are the real, functional shape a backend would slot into later.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _MyCreation {
  final Festival festival;
  final String date;
  final int likeCount;

  const _MyCreation({required this.festival, required this.date, required this.likeCount});
}

class _SavedScreenState extends State<SavedScreen> {
  static const _tabs = ['डाउनलोडेड', 'कस्टमाइज़्ड', 'फेवरेट'];
  String _selectedTab = 'डाउनलोडेड';
  final Set<String> _favorited = {};

  List<_MyCreation> get _creations {
    final festivals = MockData.festivals.take(6).toList();
    return [
      for (final f in festivals)
        _MyCreation(festival: f, date: f.date, likeCount: 40 + f.daysLeft % 60),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final creations = _selectedTab == 'फेवरेट'
        ? _creations.where((c) => _favorited.contains(c.festival.id)).toList()
        : _creations;

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
                  child: ShimmerReveal(
                    skeleton: _CreationsSkeleton(),
                    child: creations.isEmpty
                        ? _EmptyState(tab: _selectedTab)
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenPadding,
                              0,
                              AppSpacing.screenPadding,
                              AppSpacing.sectionGap,
                            ),
                            itemCount: creations.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.cardGap,
                              crossAxisSpacing: AppSpacing.cardGap,
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (context, i) {
                              final creation = creations[i];
                              return _CreationCard(
                                creation: creation,
                                isFavorited: _favorited.contains(creation.festival.id),
                                onFavorite: () => setState(() {
                                  if (!_favorited.add(creation.festival.id)) {
                                    _favorited.remove(creation.festival.id);
                                  }
                                }),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PreviewShareScreen(
                                      festival: creation.festival,
                                      gradient: creation.festival.gradient,
                                      useFestivalImage: true,
                                      name: 'सौरभ शर्मा',
                                      message: '',
                                    ),
                                  ),
                                ),
                              );
                            },
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

class _CreationCard extends StatelessWidget {
  final _MyCreation creation;
  final bool isFavorited;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const _CreationCard({
    required this.creation,
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
                  FestivalImage(festival: creation.festival, iconSize: 30),
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
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          creation.festival.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle(color: Colors.white),
                        ),
                        Text(
                          'सौरभ शर्मा',
                          style: AppTextStyles.secondary(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
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
                  Text(creation.date, style: AppTextStyles.secondary()),
                  const Spacer(),
                  GestureDetector(
                    onTap: onFavorite,
                    child: Icon(
                      isFavorited ? AppIcons.heartSolid : AppIcons.heartOutline,
                      size: 15,
                      color: isFavorited ? AppColors.like : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
              tab == 'फेवरेट'
                  ? 'दिल के निशान पर टैप करके स्टेटस को फेवरेट बनाएं।'
                  : 'यहाँ आपके बनाए हुए स्टेटस दिखेंगे।',
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreationsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.sectionGap,
      ),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.cardGap,
        crossAxisSpacing: AppSpacing.cardGap,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, i) => const ShimmerBox(
        height: double.infinity,
        width: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}
