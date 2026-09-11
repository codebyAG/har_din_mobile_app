import 'package:flutter/material.dart';

import '../../domain/entities/content_entities.dart';
import '../../models/status_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';

/// Adapts a real `designs[]` entry onto the existing [StatusItem] shape
/// so StatusGridCard renders live data.
class DesignMapper {
  DesignMapper._();

  static const _palette = [
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.secondary, AppColors.primary],
    [Color(0xFF2E9B55), Color(0xFFF4B942)],
    [Color(0xFFE53935), Color(0xFFF4B942)],
  ];

  static StatusItem toStatusItem(Design design) {
    final palette = _palette[design.id.hashCode.abs() % _palette.length];
    return StatusItem(
      id: design.id,
      gradient: palette,
      icon: AppIcons.celebration,
      imageUrl: design.thumbnailUrl,
    );
  }
}
