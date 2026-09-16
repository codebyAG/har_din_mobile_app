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
    final labelStyle = AppTextStyles.cardTitle().copyWith(fontSize: 13, height: 1.2);

    return Material(
      color: AppColors.lightAccent,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
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
                              memCacheWidth: 160,
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
                // Fixed two-line budget (from the label style's own line
                // height) instead of letting the Text size itself freely
                // — guarantees room for a wrapped name so it never gets
                // clipped against the grid row below it.
                SizedBox(
                  height: labelStyle.fontSize! * labelStyle.height! * 2,
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
