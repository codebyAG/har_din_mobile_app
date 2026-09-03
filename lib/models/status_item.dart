import 'package:flutter/material.dart';

class StatusItem {
  final String id;
  final String festivalName;
  final String text;
  final List<Color> gradient;
  final IconData icon;
  final int likeCount;
  final bool isFree;

  const StatusItem({
    required this.id,
    required this.festivalName,
    required this.text,
    required this.gradient,
    required this.icon,
    required this.likeCount,
    this.isFree = true,
  });
}
