import 'package:flutter/material.dart';

/// Centralized color constants for the Musify app
/// Eliminates color code duplication across the application
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xff384850);
  static const Color primaryDark = Color(0xff263238);
  static const Color primaryLight = Color(0xff4db6ac);

  // Accent Colors
  static const Color accent = Color(0xff61e88a);
  static const Color accentSecondary = Color(0xff4db6ac);

  // Background Colors
  static const Color backgroundPrimary = Color(0xff384850);
  static const Color backgroundSecondary = Color(0xff263238);
  static const Color backgroundTertiary = Color(0xff1c252a);
  static const Color backgroundModal = Color(0xff212c31);

  // UI Colors
  static const Color cardBackground = Colors.black12;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color iconPrimary = Colors.white;

  // Status Colors
  static const Color success = Color(0xff61e88a);
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Color(0xff4db6ac);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      backgroundPrimary,
      backgroundSecondary,
      backgroundSecondary,
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [
      accentSecondary,
      accent,
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      accentSecondary,
      accent,
    ],
  );

  // Transparency variations
  static Color get primaryWithOpacity => primary.withValues(alpha: 0.8);
  static Color get accentWithOpacity => accent.withValues(alpha: 0.8);
  static Color get backgroundWithOpacity =>
      backgroundPrimary.withValues(alpha: 0.9);
}

/// Legacy color support for backward compatibility
/// @deprecated Use AppColors instead
const Color accent = AppColors.accent;
