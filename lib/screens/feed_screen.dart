import 'package:flutter/material.dart';

import '../models/feed_post.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final Set<String> _liked = {};

  @override
  Widget build(BuildContext context) {
    // Feed is unreachable in v1 — no posts, no comments, no users (§5).
    // No nav route leads here; kept compiling with an empty list.
    final posts = const <FeedPost>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('फीड'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('जल्द आ रहा है')),
            ),
            icon: const Icon(AppIcons.search, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
          itemBuilder: (context, i) {
            final post = posts[i];
            return PostCard(
              post: post,
              isLiked: _liked.contains(post.id),
              onLike: () => setState(() {
                if (!_liked.add(post.id)) _liked.remove(post.id);
              }),
              onComment: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('टिप्पणियाँ जल्द आ रही हैं')),
              ),
              onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('शेयर विकल्प (demo)')),
              ),
              onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('सेव किया गया')),
              ),
            );
          },
        ),
      ),
    );
  }
}
