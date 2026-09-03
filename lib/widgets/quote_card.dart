import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class QuoteCard extends StatelessWidget {
  final String quote;
  final String author;
  final int likeCount;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.author,
    this.likeCount = 0,
    this.isLiked = false,
    this.onLike,
    this.onShare,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightAccent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: AppColors.primary, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(quote, style: AppTextStyles.body()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '- $author',
            style: AppTextStyles.secondary().copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isLiked ? AppColors.like : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('$likeCount', style: AppTextStyles.secondary()),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              GestureDetector(
                onTap: onShare,
                child: const Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSave,
                child: const Icon(
                  Icons.bookmark_border,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
