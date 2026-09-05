import 'package:flutter/material.dart';

class StatusItem {
  final String id;
  final String festivalName;
  final String text;
  final List<Color> gradient;
  final IconData icon;
  final int likeCount;
  final bool isFree;

  /// Id of the Festival this status belongs to, so tapping it opens the
  /// matching customize flow instead of an unrelated one.
  final String? festivalId;

  /// Real photo, e.g. assets/festivals/diwali.png — falls back to the
  /// gradient + icon tile when null or missing.
  final String? imageAsset;

  const StatusItem({
    required this.id,
    required this.festivalName,
    required this.text,
    required this.gradient,
    required this.icon,
    required this.likeCount,
    this.isFree = true,
    this.festivalId,
    this.imageAsset,
  });
}
