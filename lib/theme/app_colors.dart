import 'package:flutter/material.dart';

/// Har Din brand palette — warm, festive, clean, premium, Indian.
/// Orange is reserved for important actions only; the rest of the
/// screen stays cream/white so the UI doesn't read as over-orange.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF45A0A); // Saffron Orange
  static const Color primaryDark = Color(0xFFD94300); // Deep Orange
  static const Color secondary = Color(0xFFF4B942); // Golden

  static const Color textPrimary = Color(0xFF3A2418); // Dark Brown
  static const Color textSecondary = Color(0xFF75665D); // Brown Grey

  static const Color background = Color(0xFFFBEEDA); // Warm Cream
  static const Color card = Color(0xFFFFFFFF); // White
  static const Color lightAccent = Color(0xFFFFF0D2); // Soft Cream

  static const Color whatsapp = Color(0xFF25D366);
  static const Color like = Color(0xFFE53935);
  static const Color success = Color(0xFF2E9B55);
  static const Color border = Color(0xFFE8DCCB); // Light Beige
}
