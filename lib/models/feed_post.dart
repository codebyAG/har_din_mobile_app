import 'package:flutter/material.dart';

class FeedComment {
  final String author;
  final String timeAgo;
  final String text;

  const FeedComment({required this.author, required this.timeAgo, required this.text});
}

class FeedPost {
  final String id;
  final String authorName;
  final String timeAgo;
  final String text;
  final List<Color> gradient;
  final String? imageAsset;
  final int likeCount;
  final List<FeedComment> comments;

  const FeedPost({
    required this.id,
    required this.authorName,
    required this.timeAgo,
    required this.text,
    required this.gradient,
    this.imageAsset,
    required this.likeCount,
    this.comments = const [],
  });
}
