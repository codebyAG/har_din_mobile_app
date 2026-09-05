import 'package:flutter/material.dart';

import '../models/status_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'free_badge.dart';
import 'gradient_tile.dart';

class StatusGridCard extends StatelessWidget {
  final StatusItem status;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onUse;
  final VoidCallback? onCustomize;
  final double width;

  const StatusGridCard({
    super.key,
    required this.status,
    this.isLiked = false,
    this.onTap,
    this.onLike,
    this.onUse,
    this.onCustomize,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final showActions = onUse != null || onCustomize != null;

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
                  Positioned(
                    top: 8,
                    left: 8,
                    child: status.isFree
                        ? const FreeBadge()
                        : const _PremiumBadge(),
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
                  Positioned(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Text(
                      status.text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            if (showActions)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionPill(
                        label: 'USE',
                        color: AppColors.success,
                        onTap: onUse,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _ActionPill(
                        label: 'CUSTOMIZE',
                        color: AppColors.primary,
                        onTap: onCustomize,
                      ),
                    ),
                  ],
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

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.premium, size: 10, color: AppColors.textPrimary),
          const SizedBox(width: 3),
          Text(
            'PREMIUM',
            style: AppTextStyles.secondary(color: AppColors.textPrimary).copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
