import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festival_image.dart';
import '../widgets/section_header.dart';
import '../widgets/secondary_button.dart';
import '../widgets/status_grid_card.dart';
import '../widgets/whatsapp_button.dart';
import 'customize_screen.dart';

class FestivalDetailScreen extends StatelessWidget {
  final Festival festival;

  const FestivalDetailScreen({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    final statuses = MockData.statusesForFestival(festival);

    return Scaffold(
      appBar: AppBar(title: Text(festival.name)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.sectionGap,
          ),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: AspectRatio(
                aspectRatio: 0.9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FestivalImage(festival: festival, iconSize: 72),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Happy ${festival.name}',
                            style: AppTextStyles.screenTitle(color: Colors.white)
                                .copyWith(fontSize: 26, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            festival.date,
                            style: AppTextStyles.body(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                    icon: Icons.download_outlined,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('डाउनलोड हो रहा है...')),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SecondaryButton(
                    label: 'कस्टमाइज़',
                    icon: Icons.edit_outlined,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomizeScreen(festival: festival),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const SectionHeader(title: 'और स्टेटस देखें'),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statuses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.cardGap,
                crossAxisSpacing: AppSpacing.cardGap,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, i) => StatusGridCard(
                status: statuses[i],
                width: double.infinity,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomizeScreen(festival: festival),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
