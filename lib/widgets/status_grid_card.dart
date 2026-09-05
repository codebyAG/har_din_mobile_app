import 'package:flutter/material.dart';

import '../models/status_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'free_badge.dart';
import 'gradient_tile.dart';

class StatusGridCard extends StatelessWidget {
  final StatusItem status;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final double width;

  const StatusGridCard({
    super.key,
    required this.status,
    this.isLiked = false,
    this.onTap,
    this.onLike,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
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
        child: AspectRatio(
          aspectRatio: 0.85,
          child: Stack(
            fit: StackFit.expand,
            children: [
              status.imageAsset == null
                  ? GradientTile(colors: status.gradient, icon: status.icon, iconSize: 30)
                  : Image.asset(
                      status.imageAsset!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => GradientTile(
                        colors: status.gradient,
                        icon: status.icon,
                        iconSize: 30,
                      ),
                    ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              if (status.isFree)
                const Positioned(top: 8, left: 8, child: FreeBadge()),
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.secondary(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? AppColors.like : Colors.white,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${status.likeCount}',
                            style: AppTextStyles.secondary(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
