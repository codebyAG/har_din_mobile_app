import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/home_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_grid_card.dart';
import 'customize_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final HomeCategory category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final Set<String> _liked = {};

  @override
  Widget build(BuildContext context) {
    final statuses = MockData.trendingStatuses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.category.hindiLabel} स्टेटस'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('जल्द आ रहा है')),
            ),
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.sectionGap,
          ),
          itemCount: statuses.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.cardGap,
            crossAxisSpacing: AppSpacing.cardGap,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, i) {
            final status = statuses[i];
            return StatusGridCard(
              status: status,
              width: double.infinity,
              isLiked: _liked.contains(status.id),
              onLike: () => setState(() {
                if (!_liked.add(status.id)) _liked.remove(status.id);
              }),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomizeScreen(festival: MockData.festivals.first),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
