import 'package:flutter/material.dart';

import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'festival_image.dart';

class FestivalListTile extends StatelessWidget {
  final Festival festival;
  final VoidCallback? onTap;

  const FestivalListTile({super.key, required this.festival, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: FestivalImage(
                  festival: festival,
                  iconSize: 22,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    festival.name,
                    style: AppTextStyles.cardTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(festival.date, style: AppTextStyles.secondary()),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${festival.daysLeft} दिन बाकी',
                    style: AppTextStyles.secondary(color: AppColors.primary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
