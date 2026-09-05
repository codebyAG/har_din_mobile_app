import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festive_glow.dart';
import '../widgets/religion_filter_chip.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/status_grid_card.dart';
import 'customize_screen.dart';
import 'preview_share_screen.dart';

/// Status gallery — scoped to a single festival when [festival] is given
/// (title becomes the festival name, statuses are that festival's designs),
/// otherwise shows the general trending grid.
class StatusGalleryScreen extends StatefulWidget {
  final Festival? festival;

  const StatusGalleryScreen({super.key, this.festival});

  @override
  State<StatusGalleryScreen> createState() => _StatusGalleryScreenState();
}

class _StatusGalleryScreenState extends State<StatusGalleryScreen> {
  static const _tabs = ['सभी', 'नए', 'लोकप्रिय', 'प्रीमियम'];
  String _selectedTab = 'सभी';
  final Set<String> _liked = {};

  @override
  Widget build(BuildContext context) {
    final festival = widget.festival;
    final allStatuses = festival != null
        ? MockData.statusesForFestival(festival)
        : MockData.trendingStatuses;

    final statuses = switch (_selectedTab) {
      'प्रीमियम' => allStatuses.where((s) => !s.isFree).toList(),
      'लोकप्रिय' => (allStatuses.toList()
        ..sort((a, b) => b.likeCount.compareTo(a.likeCount))),
      _ => allStatuses,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: festival != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(festival.name, style: AppTextStyles.screenTitle()),
                  Text(festival.date, style: AppTextStyles.secondary()),
                ],
              )
            : const Text('स्टेटस गैलरी'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('जल्द आ रहा है')),
            ),
            icon: const Icon(AppIcons.search, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -30,
            right: -30,
            child: FestiveGlow(size: 200),
          ),
          SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  child: statuses.isEmpty
                      ? Center(
                          child: Text(
                            'इस श्रेणी में अभी कोई स्टेटस नहीं है',
                            style: AppTextStyles.secondary(),
                          ),
                        )
                      : ShimmerReveal(
                          skeleton: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenPadding,
                              0,
                              AppSpacing.screenPadding,
                              AppSpacing.sectionGap,
                            ),
                            itemCount: 6,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.cardGap,
                              crossAxisSpacing: AppSpacing.cardGap,
                              childAspectRatio: 0.72,
                            ),
                            itemBuilder: (context, i) => const ShimmerBox(
                              height: double.infinity,
                              width: double.infinity,
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                          ),
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenPadding,
                              0,
                              AppSpacing.screenPadding,
                              AppSpacing.sectionGap,
                            ),
                            itemCount: statuses.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.cardGap,
                              crossAxisSpacing: AppSpacing.cardGap,
                              childAspectRatio: 0.72,
                            ),
                            itemBuilder: (context, i) {
                              final status = statuses[i];
                              final statusFestival = MockData.festivals.firstWhere(
                                (f) => f.id == status.festivalId,
                                orElse: () => festival ?? MockData.festivals.first,
                              );
                              return StatusGridCard(
                                status: status,
                                width: double.infinity,
                                isLiked: _liked.contains(status.id),
                                onLike: () => setState(() {
                                  if (!_liked.add(status.id)) {
                                    _liked.remove(status.id);
                                  }
                                }),
                                onUse: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PreviewShareScreen(
                                      festival: statusFestival,
                                      gradient: status.gradient,
                                      useFestivalImage: status.imageAsset != null,
                                      name: '',
                                      message: '',
                                    ),
                                  ),
                                ),
                                onCustomize: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CustomizeScreen(festival: statusFestival),
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
