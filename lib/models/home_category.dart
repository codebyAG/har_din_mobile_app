import 'package:flutter/material.dart';

class HomeCategory {
  final String id;
  final String hindiLabel;
  final String englishLabel;
  final IconData icon;
  final List<Color> gradient;

  const HomeCategory({
    required this.id,
    required this.hindiLabel,
    required this.englishLabel,
    required this.icon,
    required this.gradient,
  });

  /// Drop a matching image at this path (e.g. assets/categories/love.png)
  /// and it renders automatically — falls back to a gradient tile until then.
  String get assetPath => 'assets/categories/$id.png';
}
