import 'package:flutter/material.dart';

/// A `designs[]` entry adapted for StatusGridCard — see DesignMapper.
/// [gradient]/[icon] are only the fallback shown while [imageUrl] loads
/// or if it 404s; the real content is always the network thumbnail.
class StatusItem {
  final String id;
  final List<Color> gradient;
  final IconData icon;
  final String imageUrl;

  const StatusItem({
    required this.id,
    required this.gradient,
    required this.icon,
    required this.imageUrl,
  });
}
