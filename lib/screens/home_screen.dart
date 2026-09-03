import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/category_grid_tile.dart';
import '../widgets/festival_card.dart';
import '../widgets/section_header.dart';
import 'category_detail_screen.dart';
import 'festival_detail_screen.dart';
import 'festivals_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
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
                    icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: Image.asset(
                      'assets/horizontal_app_logo_transparent.png',
                      height: 44,
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
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.like,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
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
                                builder: (_) => CategoryDetailScreen(category: category),
                              ),
                            ),
                          );
                        },
                        childCount: MockData.homeCategories.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      0,
                      AppSpacing.screenPadding,
                      AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'लोकप्रिय त्योहार',
                        actionLabel: 'सभी देखें',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FestivalsScreen()),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 230,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        itemCount: MockData.festivals.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.cardGap),
                        itemBuilder: (context, i) {
                          final festival = MockData.festivals[i];
                          return FestivalCard(
                            festival: festival,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FestivalDetailScreen(festival: festival),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sectionGap),
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
