import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/religion_filter_chip.dart';
import '../widgets/status_grid_card.dart';
import 'customize_screen.dart';

class StatusGalleryScreen extends StatefulWidget {
  const StatusGalleryScreen({super.key});

  @override
  State<StatusGalleryScreen> createState() => _StatusGalleryScreenState();
}

class _StatusGalleryScreenState extends State<StatusGalleryScreen> {
  static const _tabs = ['ट्रेंडिंग', 'लोकप्रिय', 'वीडियो', 'कोट्स'];
  String _selectedTab = 'ट्रेंडिंग';
  final Set<String> _liked = {};

  @override
  Widget build(BuildContext context) {
    final statuses = MockData.trendingStatuses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('स्टेटस गैलरी'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  for (final tab in _tabs) ...[
                    ReligionFilterChip(
                      label: tab,
                      selected: tab == _selectedTab,
                      onTap: () => setState(() => _selectedTab = tab),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
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
                        builder: (_) => CustomizeScreen(
                          festival: MockData.festivals.firstWhere(
                            (f) => status.id.startsWith(f.id),
                            orElse: () => MockData.festivals.first,
                          ),
                        ),
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
