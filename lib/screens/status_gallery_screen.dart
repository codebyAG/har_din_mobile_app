import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/search_service.dart';
import '../core/services/time_band_service.dart';
import '../core/utils/design_mapper.dart';
import '../data/mock_data.dart';
import '../domain/entities/content_entities.dart';
import '../models/festival.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festive_glow.dart';
import '../widgets/religion_filter_chip.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/status_grid_card.dart';
import 'preview_share_screen.dart';

/// Status gallery — scoped to a single festival/occasion when [festival]
/// is given (title becomes its name, statuses are that occasion's real
/// designs when available), otherwise shows the general trending grid.
///
/// Reads live `designs[]` from [ContentViewModel] when [festival] carries
/// an [Festival.apiCategoryId] (built from a real occasion — see
/// OccasionMapper); falls back to the bundled mock grid otherwise, so a
/// first open with no signal, or content with no live designs yet, is
/// never blank (§4).
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
  final Set<String> _liked = {};
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

  void _openPreview(BuildContext context, {
    required Festival festival,
    required List<Color> gradient,
    Design? design,
    bool useFestivalImage = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewShareScreen(
          festival: festival,
          gradient: gradient,
          useFestivalImage: useFestivalImage,
          name: '',
          message: '',
          design: design,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final festival = widget.festival;
    final payload = context.watch<ContentViewModel>().payload;
    final categoryId = festival?.apiCategoryId;

    // Real path: this occasion has a live category and the payload has
    // designs for it. Falls back to mock the moment either is false.
    List<Design> realDesigns = [];
    if (payload != null) {
      final band = TimeBandService.currentBand(payload.timeBands);
      var pool = categoryId != null
          ? payload.designs.where((d) => d.categoryId == categoryId)
          : payload.designs;
      pool = pool.where((d) => d.matchesBand(band));
      realDesigns = _query.isEmpty
          ? pool.toList()
          : SearchService.search(_query, pool.toList(), payload.tags);
    }

    final usingRealData = realDesigns.isNotEmpty || (payload != null && _query.isNotEmpty);
    final designById = {for (final d in realDesigns) d.id: d};

    realDesigns = switch (_selectedTab) {
      'नए' => (realDesigns.toList()
        ..sort((a, b) => (b.publishedAt ?? DateTime(0)).compareTo(a.publishedAt ?? DateTime(0)))),
      'लोकप्रिय' => (realDesigns.toList()
        ..sort((a, b) => b.stats.shares.compareTo(a.stats.shares))),
      _ => realDesigns,
    };

    final mockStatuses = _query.isNotEmpty
        ? const []
        : (festival != null ? MockData.statusesForFestival(festival) : MockData.trendingStatuses);
    final statuses = usingRealData
        ? realDesigns.map(DesignMapper.toStatusItem).toList()
        : switch (_selectedTab) {
            'लोकप्रिय' => (mockStatuses.toList()
              ..sort((a, b) => b.likeCount.compareTo(a.likeCount))),
            _ => mockStatuses,
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
                                : 'इस श्रेणी में अभी कोई स्टेटस नहीं है',
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
                              final design = designById[status.id];
                              final statusFestival = design != null
                                  ? (festival ??
                                      Festival(
                                        id: design.categoryId,
                                        name: '',
                                        date: '',
                                        religion: '',
                                        daysLeft: 0,
                                        gradient: status.gradient,
                                        icon: status.icon,
                                      ))
                                  : MockData.festivals.firstWhere(
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
                                onUse: () {
                                  // design_view fires once, from
                                  // PreviewShareScreen.initState — not
                                  // here too, or every open double-counts.
                                  _openPreview(
                                    context,
                                    festival: statusFestival,
                                    gradient: status.gradient,
                                    design: design,
                                    useFestivalImage: design == null,
                                  );
                                },
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
