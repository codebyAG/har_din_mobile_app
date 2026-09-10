import 'package:flutter/material.dart';

import '../../domain/entities/content_entities.dart';
import '../../models/status_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';

/// Adapts a real `designs[]` entry onto the existing [StatusItem] shape
/// so StatusGridCard (built for the pre-integration mock grid) renders
/// live data unchanged. Designs are shown exactly as uploaded — no text
/// overlay to fill in, unlike the mock placeholder cards (§1).
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
      festivalName: '',
      text: '',
      gradient: palette,
      icon: AppIcons.celebration,
      likeCount: design.stats.shares,
      festivalId: design.categoryId,
      imageUrl: design.thumbnailUrl,
    );
  }
}
