import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/home_category.dart';
import '../presentation/providers/app_language_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'gradient_tile.dart';

/// Category card for the home grid — one solid pastel tile holding a
/// photo (or gradient placeholder until the real asset is dropped in)
/// plus a label in whichever language the app is currently set to.
class CategoryGridTile extends StatelessWidget {
  final HomeCategory category;
  final VoidCallback? onTap;

  const CategoryGridTile({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.lightAccent,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Image.asset(
                  category.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GradientTile(
                      colors: category.gradient,
                      icon: category.icon,
                      iconSize: 26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Consumer<AppLanguageController>(
              builder: (context, controller, _) {
                final label = controller.language == AppLanguage.hindi
                    ? category.hindiLabel
                    : category.englishLabel;
                return Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.cardTitle(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
