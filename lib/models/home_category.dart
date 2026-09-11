import 'package:flutter/material.dart';

/// A top-level `categories[]` entry for the home grid. [name] is already
/// in the selected language (the server localizes it), so it's shown as
/// it is; [iconUrl] (network) falls back to a gradient + icon tile when
/// null or broken.
class HomeCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<Color> gradient;
  final String? iconUrl;

  const HomeCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradient,
    this.iconUrl,
  });
}
