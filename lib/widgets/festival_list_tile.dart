import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/festival.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'festival_image.dart';

class FestivalListTile extends StatelessWidget {
  final Festival festival;
  final VoidCallback? onTap;

  const FestivalListTile({super.key, required this.festival, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ContentViewModel>().t;
    final soon = festival.daysLeft <= 3;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: FestivalImage(
                          festival: festival,
                          iconSize: 32,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    if (soon)
                      Positioned(
                        top: -6,
                        left: -6,
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7A70), AppColors.like],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.like.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            AppIcons.celebration,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
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
                      const SizedBox(height: 3),
                      Text(festival.date, style: AppTextStyles.secondary()),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: soon
                                ? const [Color(0xFFFF7A70), AppColors.like]
                                : const [AppColors.secondary, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          t('festival.days_left', {'n': '${festival.daysLeft}'}),
                          style: AppTextStyles.secondary(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.lightAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(AppIcons.chevronRight, size: 13, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
