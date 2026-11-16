import 'package:flutter/material.dart';

/// Brand palette for Dir Shopping Store.
/// A deep indigo/violet primary with a warm amber accent gives the
/// "premium marketplace" feel without leaning on any single retailer's
/// existing brand colors.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4B3AF0);
  static const Color primaryDark = Color(0xFF2E22B8);
  static const Color secondary = Color(0xFFFFA43D);

  static const Color success = Color(0xFF1FAE64);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF2F86EB);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  static const Color lightBorder = Color(0xFFE4E3EC);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF121016);
  static const Color darkSurface = Color(0xFF1D1B23);
  static const Color darkOnSurface = Color(0xFFEDEBF3);
  static const Color darkBorder = Color(0xFF322E3B);

  static const Color textMuted = Color(0xFF8B8894);
}
