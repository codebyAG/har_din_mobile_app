import 'package:flutter/material.dart';

import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festival_image.dart';
import '../widgets/gradient_tile.dart';
import '../widgets/secondary_button.dart';
import '../widgets/whatsapp_button.dart';

class PreviewShareScreen extends StatelessWidget {
  final Festival festival;
  final List<Color> gradient;
  final bool useFestivalImage;
  final String name;
  final String message;

  const PreviewShareScreen({
    super.key,
    required this.festival,
    required this.gradient,
    this.useFestivalImage = false,
    required this.name,
    required this.message,
  });

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
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: useFestivalImage
                            ? FestivalImage(festival: festival, iconSize: 64)
                            : GradientTile(
                                colors: gradient,
                                icon: festival.icon,
                                iconSize: 64,
                              ),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (name.isNotEmpty)
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.screenTitle(color: Colors.white),
                              ),
                            if (message.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                message,
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
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('WhatsApp पर शेयर किया गया')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'डाउनलोड करें',
                      icon: AppIcons.download,
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('डाउनलोड हो रहा है...')),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SecondaryButton(
                      label: 'और विकल्प',
                      icon: AppIcons.more,
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('शेयर विकल्प (demo)')),
                      ),
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
