import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festival_list_tile.dart';
import '../widgets/festive_glow.dart';
import '../widgets/religion_filter_chip.dart';
import '../widgets/shimmer_box.dart';
import 'customize_screen.dart';
import 'status_gallery_screen.dart';

class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  String _selectedReligion = 'सभी';

  @override
  Widget build(BuildContext context) {
    final festivals = _selectedReligion == 'सभी'
        ? MockData.festivals
        : MockData.festivals
            .where((f) => f.religion == _selectedReligion)
            .toList();

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
                    itemCount: MockData.religionFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final religion = MockData.religionFilters[i];
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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        0,
                        AppSpacing.screenPadding,
                        AppSpacing.sectionGap,
                      ),
                      itemCount: festivals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final festival = festivals[i];
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomizeScreen(festival: festivals.first),
          ),
        ),
        child: const Icon(AppIcons.add, color: Colors.white),
      ),
    );
  }
}
