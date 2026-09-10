import 'package:flutter/material.dart';

class HomeCategory {
  final String id;
  final String hindiLabel;
  final String englishLabel;
  final IconData icon;
  final List<Color> gradient;

  /// When built from a real `categories[]` entry: its `name`, already in
  /// the selected language — shown as-is instead of picking hindi/english.
  final String? apiName;

  /// Real `categories[].icon_url` — network, takes priority over the
  /// bundled asset when set.
  final String? iconUrl;

  const HomeCategory({
    required this.id,
    required this.hindiLabel,
    required this.englishLabel,
    required this.icon,
    required this.gradient,
    this.apiName,
    this.iconUrl,
  });

  /// Drop a matching image at this path (e.g. assets/categories_icons/love.png)
  /// and it renders automatically — falls back to a gradient tile until then.
  String get assetPath => 'assets/categories_icons/$id.png';
}
