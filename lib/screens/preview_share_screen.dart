import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/services/event_queue.dart';
import '../core/services/image_cache_service.dart';
import '../core/services/share_service.dart';
import '../domain/entities/content_entities.dart';
import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festival_image.dart';
import '../widgets/gradient_tile.dart';
import '../widgets/secondary_button.dart';
import '../widgets/whatsapp_button.dart';

/// §2 — the share path v1 measures. Real file, real share sheet, real
/// gallery write:
/// - [design] present: shares/downloads the real `display_url` file.
/// - [design] null but the festival/status carries a bundled asset:
///   shares/downloads that asset directly (still a real file export).
/// - Neither: nothing to export — no compositing/watermark in v1 (§2),
///   so the action is disabled rather than faking success.
class PreviewShareScreen extends StatefulWidget {
  final Festival festival;
  final List<Color> gradient;
  final bool useFestivalImage;
  final String name;
  final String message;
  final Design? design;

  const PreviewShareScreen({
    super.key,
    required this.festival,
    required this.gradient,
    this.useFestivalImage = false,
    required this.name,
    required this.message,
    this.design,
  });

  @override
  State<PreviewShareScreen> createState() => _PreviewShareScreenState();
}

class _PreviewShareScreenState extends State<PreviewShareScreen> {
  bool _busy = false;

  String? get _shareableAsset =>
      widget.useFestivalImage ? widget.festival.imageAsset : null;

  bool get _canExport => widget.design != null || _shareableAsset != null;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    final design = widget.design;
    if (design != null) {
      EventQueue.instance.record(HarDinEventType.designView, designId: design.id);
    }
  }

  Future<void> _share() async {
    if (_busy || !_canExport) return;
    setState(() => _busy = true);
    try {
      final design = widget.design;
      final status = design != null
          ? await ShareService.shareDesign(design)
          : await ShareService.shareAsset(_shareableAsset!, id: widget.festival.id);
      if (status == ShareResultStatus.success) {
        _snack('शेयर किया गया');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    if (_busy || !_canExport) return;
    setState(() => _busy = true);
    try {
      final design = widget.design;
      final ok = design != null
          ? await ShareService.downloadDesign(design)
          : await ShareService.downloadAsset(_shareableAsset!, id: widget.festival.id);
      _snack(ok ? 'गैलरी में सेव हो गया' : 'डाउनलोड नहीं हो पाया, दोबारा कोशिश करें');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = widget.design;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Preview')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.sectionGap,
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: design != null
                            ? CachedNetworkImage(
                                imageUrl: design.displayUrl,
                                cacheManager: ImageCacheService.instance,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => GradientTile(
                                  colors: widget.gradient,
                                  icon: widget.festival.icon,
                                  iconSize: 64,
                                ),
                              )
                            : widget.useFestivalImage
                                ? FestivalImage(festival: widget.festival, iconSize: 64)
                                : GradientTile(
                                    colors: widget.gradient,
                                    icon: widget.festival.icon,
                                    iconSize: 64,
                                  ),
                      ),
                      if (design == null)
                        Positioned(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: AppSpacing.lg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.name.isNotEmpty)
                                Text(
                                  widget.name,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.screenTitle(color: Colors.white),
                                ),
                              if (widget.message.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  widget.message,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              WhatsAppButton(
                onPressed: _busy || !_canExport ? null : _share,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'डाउनलोड करें',
                      icon: AppIcons.download,
                      onPressed: _busy || !_canExport ? null : _download,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SecondaryButton(
                      label: 'और विकल्प',
                      icon: AppIcons.more,
                      onPressed: _busy || !_canExport ? null : _share,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
