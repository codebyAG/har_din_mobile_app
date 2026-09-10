import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/time_band_service.dart';
import '../core/utils/design_mapper.dart';
import '../data/mock_data.dart';
import '../domain/entities/content_entities.dart';
import '../models/festival.dart';
import '../models/home_category.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_grid_card.dart';
import 'preview_share_screen.dart';

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
    final payload = context.watch<ContentViewModel>().payload;

    List<Design> designs = const [];
    if (widget.category.apiName != null && payload != null) {
      final band = TimeBandService.currentBand(payload.timeBands);
      designs = payload.designs
          .where((d) => d.categoryId == widget.category.id)
          .where((d) => d.matchesBand(band))
          .toList();
    }

    final usingReal = designs.isNotEmpty;
    final statuses = usingReal ? designs.map(DesignMapper.toStatusItem).toList() : MockData.trendingStatuses;
    final designById = {for (final d in designs) d.id: d};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.category.hindiLabel} स्टेटस'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('जल्द आ रहा है')),
            ),
            icon: const Icon(AppIcons.search, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: statuses.isEmpty
            ? Center(
                child: Text(
                  'इस श्रेणी में अभी कोई स्टेटस नहीं है',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : GridView.builder(
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
                  final design = designById[status.id];
                  return StatusGridCard(
                    status: status,
                    width: double.infinity,
                    isLiked: _liked.contains(status.id),
                    onLike: () => setState(() {
                      if (!_liked.add(status.id)) _liked.remove(status.id);
                    }),
                    onTap: () {
                      // design_view fires once, from
                      // PreviewShareScreen.initState — not here too.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PreviewShareScreen(
                            festival: design != null
                                ? Festival(
                                    id: design.categoryId,
                                    name: '',
                                    date: '',
                                    religion: '',
                                    daysLeft: 0,
                                    gradient: status.gradient,
                                    icon: status.icon,
                                  )
                                : MockData.festivals.firstWhere(
                                    (f) => f.id == status.festivalId,
                                    orElse: () => MockData.festivals.first,
                                  ),
                            gradient: status.gradient,
                            useFestivalImage: design == null,
                            name: '',
                            message: '',
                            design: design,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
