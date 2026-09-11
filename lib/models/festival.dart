import 'package:flutter/material.dart';

/// An occasion (`occasions[]`) adapted for the pre-integration UI widgets
/// (FestivalListTile, FestivalImage) — see OccasionMapper.
class Festival {
  final String id;
  final String name;
  final String date;
  final String religion;
  final int daysLeft;
  final List<Color> gradient;
  final IconData icon;

  /// `occasions[].image_url` — network, falls back to the gradient +
  /// icon tile when null.
  final String? imageUrl;

  /// The API `categories[].id` this occasion opens.
  final String? apiCategoryId;

  const Festival({
    required this.id,
    required this.name,
    required this.date,
    required this.religion,
    required this.daysLeft,
    required this.gradient,
    required this.icon,
    this.imageUrl,
    this.apiCategoryId,
  });
}
