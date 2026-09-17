import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/services/share_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/secondary_button.dart';
import '../widgets/whatsapp_button.dart';

const _backgrounds = [
  [AppColors.secondary, AppColors.primary],
  [AppColors.primary, AppColors.primaryDark],
  [Color(0xFF2E9B55), Color(0xFF1F6E3C)],
  [Color(0xFF3A2418), Color(0xFF75665D)],
  [Color(0xFFE53935), Color(0xFFF4B942)],
  [Color(0xFF6FA8E8), Color(0xFF3D6FC2)],
];

/// Local-only text status — no editor backend, no AI, nothing sent
/// anywhere: type a line, pick a background, and the rendered card is
/// captured straight off-screen as a real PNG (`RepaintBoundary`) and
/// handed to the same real share/download pipeline every other design
/// in the app uses.
class QuoteMakerScreen extends StatefulWidget {
  const QuoteMakerScreen({super.key});

  @override
  State<QuoteMakerScreen> createState() => _QuoteMakerScreenState();
}

class _QuoteMakerScreenState extends State<QuoteMakerScreen> {
  final _controller = TextEditingController();
  final _boundaryKey = GlobalKey();
  int _backgroundIndex = 0;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<File?> _captureCard() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/har_din_quote_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    return file;
  }

  Future<void> _shareToWhatsApp() async {
    if (_controller.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await _captureCard();
      if (file == null) return;
      if (Platform.isAndroid) {
        final ok = await ShareService.shareToWhatsAppDirect(file);
        if (ok) {
          _snack('WhatsApp पर भेजा गया');
          return;
        }
      }
      final status = await ShareService.shareLocalFile(file);
      if (status == ShareResultStatus.success) _snack('शेयर किया गया');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    if (_controller.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await _captureCard();
      if (file == null) return;
      final ok = await ShareService.downloadLocalFile(file);
      _snack(ok ? 'गैलरी में सेव हो गया' : 'डाउनलोड नहीं हो पाया, दोबारा कोशिश करें');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('टेक्स्ट स्टेटस बनाएं')),
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
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _backgrounds[_backgroundIndex],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        hasText ? _controller.text : 'यहाँ आपका संदेश दिखेगा',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenTitle(color: Colors.white).copyWith(
                          fontSize: 24,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                maxLines: 3,
                maxLength: 140,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'अपना संदेश यहाँ लिखें...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('बैकग्राउंड चुनें', style: AppTextStyles.secondary()),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _backgrounds.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final selected = i == _backgroundIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _backgroundIndex = i),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _backgrounds[i],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.textPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(AppIcons.free, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              WhatsAppButton(onPressed: (_busy || !hasText) ? null : _shareToWhatsApp),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'डाउनलोड करें',
                icon: AppIcons.download,
                onPressed: (_busy || !hasText) ? null : _download,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
