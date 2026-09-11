import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/services/image_cache_service.dart';
import '../models/home_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'gradient_tile.dart';

/// Category card for the home grid — one solid pastel tile holding the
/// category's icon (network `icon_url`, falling back to a gradient +
/// icon placeholder) plus its name, already in the selected language.
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
                child: category.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: category.iconUrl!,
                          cacheManager: ImageCacheService.instance,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => GradientTile(
                            colors: category.gradient,
                            icon: category.icon,
                            iconSize: 26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : GradientTile(
                        colors: category.gradient,
                        icon: category.icon,
                        iconSize: 26,
                        borderRadius: BorderRadius.circular(12),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.cardTitle(),
            ),
          ],
        ),
      ),
    );
  }
}
