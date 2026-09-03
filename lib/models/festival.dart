import 'package:flutter/material.dart';

class Festival {
  final String id;
  final String name;
  final String date;
  final String religion;
  final int daysLeft;
  final List<Color> gradient;
  final IconData icon;

  /// Real photo, e.g. assets/festivals/diwali.png — falls back to the
  /// gradient + icon tile when null or missing.
  final String? imageAsset;

  const Festival({
    required this.id,
    required this.name,
    required this.date,
    required this.religion,
    required this.daysLeft,
    required this.gradient,
    required this.icon,
    this.imageAsset,
  });
}
