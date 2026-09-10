import 'package:flutter/material.dart';

class Festival {
  final String id;
  final String name;
  final String date;
  final String religion;
  final int daysLeft;
  final List<Color> gradient;
  final IconData icon;

  /// Real photo, e.g. assets/festival_icons/diwali.png — falls back to the
  /// gradient + icon tile when null or missing.
  final String? imageAsset;

  /// Network photo (from `occasions[].image_url`) — takes priority over
  /// [imageAsset] when set. Null for every mock/bundled festival.
  final String? imageUrl;

  /// The API `categories[].id` this occasion opens, when this Festival was
  /// built from a real `occasions[]` entry — null for mock/bundled ones,
  /// which fall back to demo statuses instead of a real design lookup.
  final String? apiCategoryId;

  const Festival({
    required this.id,
    required this.name,
    required this.date,
    required this.religion,
    required this.daysLeft,
    required this.gradient,
    required this.icon,
    this.imageAsset,
    this.imageUrl,
    this.apiCategoryId,
  });
}
