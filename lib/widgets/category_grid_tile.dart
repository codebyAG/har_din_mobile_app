import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/image_cache_service.dart';
import '../models/home_category.dart';
import '../presentation/providers/app_language_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'gradient_tile.dart';

/// Category card for the home grid — one solid pastel tile holding a
/// photo (network `icon_url` for real categories, or a bundled asset /
/// gradient placeholder for mock ones) plus a label in whichever
/// language the app is currently set to.
class CategoryGridTile extends StatelessWidget {
  final HomeCategory category;
  final VoidCallback? onTap;

  const CategoryGridTile({super.key, required this.category, this.onTap});

  Widget _fallbackTile() => GradientTile(
        colors: category.gradient,
        icon: category.icon,
        iconSize: 26,
        borderRadius: BorderRadius.circular(12),
      );

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
                child: category.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: category.iconUrl!,
                          cacheManager: ImageCacheService.instance,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => _fallbackTile(),
                        ),
                      )
                    : Image.asset(
                        category.assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _fallbackTile(),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (category.apiName != null)
              Text(
                category.apiName!,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTextStyles.cardTitle(),
              )
            else
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
