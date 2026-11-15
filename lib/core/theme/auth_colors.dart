import 'app_colors.dart';
import 'package:flutter/material.dart';

/// Centralized color palette for the minimalist iOS-inspired authentication
/// and legal screens, closely matching the design system specifications.
class AuthColors {
  AuthColors._();

  /// Primary background: warm off-white (#F7F4F3)
  static const Color background = AppColors.background;

  /// Primary accent: soft peach (#EDCDC2)
  static const Color primaryAccent = AppColors.primaryTint;

  /// Primary accent dark/pressed state: slightly deeper peach for tactile interaction
  static const Color primaryAccentPressed = AppColors.cardBorder;

  /// Secondary accent: dusty rose (#D5A798)
  static const Color secondaryAccent = AppColors.primary;

  /// Input background: pure white (#FFFFFF)
  static const Color inputBackground = Color(0xFFF5F5F2);

  /// Primary text: deep soft charcoal/black (#242424)
  static const Color textPrimary = AppColors.text;

  /// Secondary text: muted gray (#777373)
  static const Color textSecondary = AppColors.muted;

  /// Placeholder/hint text color
  static const Color textHint = AppColors.muted;

  /// Border color for containers and fields (#E9E2DF)
  static const Color border = AppColors.cardBorder;

  /// Subtle active/focus border
  static const Color borderFocused = AppColors.primary;

  /// Top circular icon badge background (#EDCDC2 with subtle warmth)
  static const Color iconBadgeBg = AppColors.primaryTint;

  /// Badge border stroke
  static const Color iconBadgeBorder = Color(0xFF242424);

  /// Error color for form validation
  static const Color error = AppColors.sos;

  /// Error light tint for subtle error badges/borders
  static const Color errorTint = Color(0xFFFDE8E8);

  /// Success color
  static const Color success = AppColors.onlineDark;

  /// Home indicator bar on iOS-styled bottom area
  static const Color homeIndicator = Color(0xFF242424);

  /// Ambient input drop shadow
  static const Color inputShadow = Color(0x0D000000);

  /// Pill button elevation drop shadow matching the reference image
  static const Color buttonShadow = Color(0x38242424);
}
