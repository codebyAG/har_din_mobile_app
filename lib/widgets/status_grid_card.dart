import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/services/image_cache_service.dart';
import '../models/status_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'gradient_tile.dart';

class StatusGridCard extends StatelessWidget {
  final StatusItem status;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onUse;
  final double width;

  const StatusGridCard({
    super.key,
    required this.status,
    this.isLiked = false,
    this.onTap,
    this.onLike,
    this.onUse,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final showActions = onUse != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: status.imageUrl,
                    cacheManager: ImageCacheService.instance,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (context, url, error) => GradientTile(
                      colors: status.gradient,
                      icon: status.icon,
                      iconSize: 30,
                    ),
                  ),
                  if (onLike != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onLike,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked ? AppIcons.heartSolid : AppIcons.heartOutline,
                            size: 15,
                            color: isLiked ? AppColors.like : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showActions)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: _ActionPill(
                  label: 'USE',
                  color: AppColors.success,
                  onTap: onUse,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionPill({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.secondary(color: Colors.white)
              .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ),
    );
  }
}
