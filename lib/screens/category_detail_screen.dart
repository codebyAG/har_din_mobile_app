import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/search_service.dart';
import '../core/services/time_band_service.dart';
import '../core/utils/design_mapper.dart';
import '../domain/entities/content_entities.dart';
import '../models/home_category.dart';
import '../presentation/providers/content_view_model.dart';
import '../presentation/providers/saved_designs_controller.dart';
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
  String _query = '';

  Future<void> _search(BuildContext context) async {
    final controller = TextEditingController(text: _query);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(hintText: 'जैसे "deepavali", "gm"...'),
                onSubmitted: (v) => Navigator.of(sheetContext).pop(v),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(sheetContext).pop(controller.text),
              icon: const Icon(AppIcons.search, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _query = result.trim());
  }

  @override
  Widget build(BuildContext context) {
    final payload = context.watch<ContentViewModel>().payload;
    final favorites = context.watch<SavedDesignsController>();

    List<Design> designs = const [];
    if (payload != null) {
      final band = TimeBandService.currentBand(payload.timeBands);
      designs = payload.designs
          .where((d) => d.categoryId == widget.category.id)
          .where((d) => d.matchesBand(band))
          .toList();
      if (_query.isNotEmpty) {
        designs = SearchService.search(_query, designs, payload.tags);
      }
    }

    final statuses = designs.map(DesignMapper.toStatusItem).toList();
    final designById = {for (final d in designs) d.id: d};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.category.name} स्टेटस'),
        actions: [
          IconButton(
            onPressed: () => _search(context),
            icon: const Icon(AppIcons.search, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: statuses.isEmpty
            ? Center(
                child: Text(
                  _query.isNotEmpty
                      ? 'कोई परिणाम नहीं मिला'
                      : (payload == null
                          ? 'लोड हो रहा है...'
                          : 'इस श्रेणी में अभी कोई स्टेटस नहीं है'),
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
                  final design = designById[status.id]!;
                  return StatusGridCard(
                    status: status,
                    width: double.infinity,
                    isLiked: favorites.isFavorite(design.id),
                    onLike: () => favorites.toggleFavorite(design),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PreviewShareScreen(design: design),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
