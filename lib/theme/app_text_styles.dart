import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Bilingual type scale: Inter for Latin text, Noto Sans Devanagari as the
/// fallback so Hindi copy renders correctly wherever it appears mixed in.
/// Both are bundled as local assets (see pubspec.yaml) — no runtime font
/// download, so the app works fully offline.
class AppTextStyles {
  AppTextStyles._();

  static const String _primaryFont = 'Inter';
  static const List<String> _devanagariFallback = ['Noto Sans Devanagari'];

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
  }) {
    return TextStyle(
      fontFamily: _primaryFont,
      fontFamilyFallback: _devanagariFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle screenTitle({Color color = AppColors.textPrimary}) =>
      _base(size: 20, weight: FontWeight.w600, color: color);

  static TextStyle sectionHeading({Color color = AppColors.textPrimary}) =>
      _base(size: 18, weight: FontWeight.w600, color: color);

  static TextStyle cardTitle({Color color = AppColors.textPrimary}) =>
      _base(size: 16, weight: FontWeight.w600, color: color);

  static TextStyle body({Color color = AppColors.textPrimary}) =>
      _base(size: 14, weight: FontWeight.w400, color: color);

  static TextStyle secondary({Color color = AppColors.textSecondary}) =>
      _base(size: 13, weight: FontWeight.w400, color: color);

  static TextStyle button({Color color = Colors.white}) =>
      _base(size: 15, weight: FontWeight.w600, color: color);

  static TextStyle bottomNav({Color color = AppColors.textSecondary}) =>
      _base(size: 12, weight: FontWeight.w500, color: color);
}
