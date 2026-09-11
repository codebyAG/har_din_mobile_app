import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/services/event_queue.dart';
import '../core/services/image_cache_service.dart';
import '../core/services/share_service.dart';
import '../domain/entities/content_entities.dart';
import '../presentation/providers/saved_designs_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../widgets/gradient_tile.dart';
import '../widgets/secondary_button.dart';
import '../widgets/whatsapp_button.dart';

/// §2 — the share path v1 measures. The real `display_url` file, shared
/// through the real platform share sheet, or saved to the real gallery.
/// No compositing, no watermark, no demo toasts.
class PreviewShareScreen extends StatefulWidget {
  final Design design;

  const PreviewShareScreen({super.key, required this.design});

  @override
  State<PreviewShareScreen> createState() => _PreviewShareScreenState();
}

class _PreviewShareScreenState extends State<PreviewShareScreen> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    EventQueue.instance.record(HarDinEventType.designView, designId: widget.design.id);
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await ShareService.shareDesign(widget.design);
      if (status == ShareResultStatus.success) _snack('शेयर किया गया');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await ShareService.downloadDesign(widget.design);
      if (ok && mounted) {
        await context.read<SavedDesignsController>().recordDownload(widget.design);
      }
      _snack(ok ? 'गैलरी में सेव हो गया' : 'डाउनलोड नहीं हो पाया, दोबारा कोशिश करें');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: CachedNetworkImage(
                    imageUrl: widget.design.displayUrl,
                    cacheManager: ImageCacheService.instance,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (context, url, error) => const GradientTile(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      icon: AppIcons.celebration,
                      iconSize: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              WhatsAppButton(onPressed: _busy ? null : _share),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'डाउनलोड करें',
                      icon: AppIcons.download,
                      onPressed: _busy ? null : _download,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SecondaryButton(
                      label: 'और विकल्प',
                      icon: AppIcons.more,
                      onPressed: _busy ? null : _share,
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
