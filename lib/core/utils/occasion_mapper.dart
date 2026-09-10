import 'package:flutter/material.dart';

import '../../domain/entities/content_entities.dart';
import '../../models/festival.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';

/// Adapts a real `occasions[]` entry onto the existing [Festival] shape so
/// screens/widgets built for the pre-integration UI (FestivalListTile,
/// FestivalImage, StatusGalleryScreen) work unchanged against live data.
class OccasionMapper {
  OccasionMapper._();

  static const _religionByCommunity = {
    'hindu': 'हिंदू',
    'muslim': 'मुस्लिम',
    'sikh': 'सिख',
    'christian': 'ईसाई',
    'jain': 'जैन',
    'buddhist': 'बौद्ध',
    'national': 'राष्ट्रीय',
  };

  static const _palette = [
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.secondary, AppColors.primary],
    [Color(0xFF2E9B55), Color(0xFFF4B942)],
    [Color(0xFFE53935), Color(0xFFF4B942)],
    [Color(0xFFD94300), Color(0xFFF4B942)],
    [Color(0xFF3A2418), Color(0xFF75665D)],
  ];

  static Festival fromOccasion(Occasion o, {DateTime? now}) {
    final palette = _palette[o.id.hashCode.abs() % _palette.length];
    return Festival(
      id: o.id,
      name: o.name,
      date: _formatDate(o.date),
      religion: _religionByCommunity[o.community] ?? 'अन्य',
      daysLeft: o.daysUntil(now ?? DateTime.now()),
      gradient: palette,
      icon: AppIcons.celebration,
      imageUrl: o.imageUrl,
      apiCategoryId: o.categoryId,
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
