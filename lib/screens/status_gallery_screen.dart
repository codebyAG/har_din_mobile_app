import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/search_service.dart';
import '../core/services/time_band_service.dart';
import '../core/utils/design_mapper.dart';
import '../domain/entities/content_entities.dart';
import '../models/festival.dart';
import '../presentation/providers/content_view_model.dart';
import '../presentation/providers/saved_designs_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festive_glow.dart';
import '../widgets/religion_filter_chip.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/status_grid_card.dart';
import 'preview_share_screen.dart';

/// Status gallery — scoped to a single occasion when [festival] is given
/// (title becomes its name, grid is that occasion's real `designs[]`),
/// otherwise shows every design in the payload. No mock fallback — an
/// empty state is shown until the API has designs for this scope.
class StatusGalleryScreen extends StatefulWidget {
  final Festival? festival;

  const StatusGalleryScreen({super.key, this.festival});

  @override
  State<StatusGalleryScreen> createState() => _StatusGalleryScreenState();
}

class _StatusGalleryScreenState extends State<StatusGalleryScreen> {
  // प्रीमियम tab removed — no paywall exists in v1 (§5).
  static const _tabs = ['सभी', 'नए', 'लोकप्रिय'];
  String _selectedTab = 'सभी';
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
    final festival = widget.festival;
    final payload = context.watch<ContentViewModel>().payload;
    final categoryId = festival?.apiCategoryId;
    final favorites = context.watch<SavedDesignsController>();

    List<Design> designs = const [];
    if (payload != null) {
      final band = TimeBandService.currentBand(payload.timeBands);
      var pool = categoryId != null
          ? payload.designs.where((d) => d.categoryId == categoryId)
          : payload.designs;
      pool = pool.where((d) => d.matchesBand(band));
      designs = _query.isEmpty
          ? pool.toList()
          : SearchService.search(_query, pool.toList(), payload.tags);
    }

    final designById = {for (final d in designs) d.id: d};
    designs = switch (_selectedTab) {
      'नए' => (designs.toList()
        ..sort((a, b) => (b.publishedAt ?? DateTime(0)).compareTo(a.publishedAt ?? DateTime(0)))),
      'लोकप्रिय' => (designs.toList()..sort((a, b) => b.stats.shares.compareTo(a.stats.shares))),
      _ => designs,
    };
    final statuses = designs.map(DesignMapper.toStatusItem).toList();

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
            onPressed: () => _search(context),
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
                            _query.isNotEmpty
                                ? 'कोई परिणाम नहीं मिला'
                                : (payload == null
                                    ? 'लोड हो रहा है...'
                                    : 'इस श्रेणी में अभी कोई स्टेटस नहीं है'),
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
                              final design = designById[status.id]!;
                              return StatusGridCard(
                                status: status,
                                width: double.infinity,
                                isLiked: favorites.isFavorite(design.id),
                                onLike: () => favorites.toggleFavorite(design),
                                onUse: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PreviewShareScreen(design: design),
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
