import 'package:flutter/material.dart';

import '../models/feed_post.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'gradient_tile.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  const PostCard({
    super.key,
    required this.post,
    this.isLiked = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.lightAccent,
                child: Text(
                  post.authorName.characters.first,
                  style: AppTextStyles.cardTitle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: AppTextStyles.cardTitle()),
                    Text(post.timeAgo, style: AppTextStyles.secondary()),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.card,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (sheetContext) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(AppIcons.bookmarkOutline),
                          title: const Text('सेव करें'),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            onSave?.call();
                          },
                        ),
                        ListTile(
                          leading: const Icon(AppIcons.report),
                          title: const Text('रिपोर्ट करें'),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('रिपोर्ट भेज दी गई')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                icon: const Icon(AppIcons.more, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  post.imageAsset == null
                      ? GradientTile(colors: post.gradient, icon: AppIcons.quote)
                      : Image.asset(
                          post.imageAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => GradientTile(
                            colors: post.gradient,
                            icon: AppIcons.quote,
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
                            Colors.black.withValues(alpha: 0.45),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Text(
                      post.text,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? AppIcons.heartSolid : AppIcons.heartOutline,
                      size: 20,
                      color: isLiked ? AppColors.like : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${post.likeCount + (isLiked ? 1 : 0)}',
                      style: AppTextStyles.secondary(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              GestureDetector(
                onTap: onComment,
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.comment,
                      size: 19,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${post.comments.length}', style: AppTextStyles.secondary()),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              GestureDetector(
                onTap: onShare,
                child: const Icon(
                  AppIcons.share,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSave,
                child: const Icon(
                  AppIcons.bookmarkOutline,
                  size: 21,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (post.comments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            for (final comment in post.comments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.lightAccent,
                      child: Text(
                        comment.author.characters.first,
                        style: AppTextStyles.secondary(color: AppColors.primary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.author,
                                style: AppTextStyles.secondary()
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(comment.timeAgo, style: AppTextStyles.secondary()),
                            ],
                          ),
                          Text(comment.text, style: AppTextStyles.body()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
