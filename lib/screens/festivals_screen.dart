import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/religion_filters.dart';
import '../core/utils/occasion_mapper.dart';
import '../models/festival.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festival_list_tile.dart';
import '../widgets/festive_glow.dart';
import '../widgets/religion_filter_chip.dart';
import '../widgets/shimmer_box.dart';
import 'status_gallery_screen.dart';

/// Reads live `occasions[]` from [ContentViewModel] — no mock fallback;
/// an empty state is shown until the API has content (§4's cache means
/// this only ever happens on a first, offline-from-birth install).
class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  String _selectedReligion = 'सभी';

  @override
  Widget build(BuildContext context) {
    final payload = context.watch<ContentViewModel>().payload;
    final occasions = payload?.occasions ?? const [];

    final allFestivals = occasions.map(OccasionMapper.fromOccasion).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    final festivals = _selectedReligion == 'सभी'
        ? allFestivals
        : allFestivals.where((f) => f.religion == _selectedReligion).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned(
            top: -30,
            right: -30,
            child: FestiveGlow(size: 200),
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
                  child: Text('सभी त्योहार', style: AppTextStyles.screenTitle()),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    itemCount: religionFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final religion = religionFilters[i];
                      return ReligionFilterChip(
                        label: religion,
                        selected: religion == _selectedReligion,
                        onTap: () => setState(() => _selectedReligion = religion),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ShimmerReveal(
                    skeleton: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        0,
                        AppSpacing.screenPadding,
                        AppSpacing.sectionGap,
                      ),
                      itemCount: 6,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => const ShimmerBox(
                        height: 80,
                        width: double.infinity,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    child: festivals.isEmpty
                        ? Center(
                            child: Text(
                              occasions.isEmpty
                                  ? 'त्योहार लोड हो रहे हैं...'
                                  : 'इस श्रेणी में अभी कोई त्योहार नहीं है',
                              style: AppTextStyles.secondary(),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenPadding,
                              0,
                              AppSpacing.screenPadding,
                              AppSpacing.sectionGap,
                            ),
                            itemCount: festivals.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) {
                              final Festival festival = festivals[i];
                              return FestivalListTile(
                                festival: festival,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StatusGalleryScreen(festival: festival),
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
      // Floating "+" removed — it opened Customize, disabled in v1 (§5).
    );
  }
}
