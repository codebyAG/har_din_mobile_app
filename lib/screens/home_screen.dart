import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/category_chip.dart';
import '../widgets/festival_card.dart';
import '../widgets/quote_card.dart';
import '../widgets/section_header.dart';
import 'category_detail_screen.dart';
import 'feed_screen.dart';
import 'festival_detail_screen.dart';
import 'festivals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';
  bool _quoteLiked = false;

  void _onCategoryTap(String categoryId) {
    setState(() => _selectedCategory = categoryId);
    if (categoryId == 'all') return;
    final match = MockData.homeCategories.where((c) => c.id == categoryId);
    if (match.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: match.first)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = MockData.festivals;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.sectionGap,
          ),
          children: [
            Row(
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
                    height: 40,
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
            const SizedBox(height: AppSpacing.sm),
            TextField(
              decoration: InputDecoration(
                hintText: 'खोजें कुछ खास...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) {
                  final category = MockData.categories[i];
                  return CategoryChip(
                    category: category,
                    selected: category.id == _selectedCategory,
                    onTap: () => _onCategoryTap(category.id),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            SectionHeader(
              title: 'आज का विचार',
              actionLabel: 'और देखें',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FeedScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            QuoteCard(
              quote: MockData.todaysQuote,
              author: MockData.todaysQuoteAuthor,
              likeCount: 98,
              isLiked: _quoteLiked,
              onLike: () => setState(() => _quoteLiked = !_quoteLiked),
              onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('शेयर विकल्प (demo)')),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            SectionHeader(
              title: 'त्योहार आने वाले',
              actionLabel: 'और देखें',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FestivalsScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.cardGap),
                itemBuilder: (context, i) {
                  final festival = upcoming[i];
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
          ],
        ),
      ),
    );
  }
}
