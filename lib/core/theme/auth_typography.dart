import 'package:flutter/material.dart';

import 'auth_colors.dart';

/// Centralized typography definitions for the authentication experience.
/// Inherits the app font so authentication and workspace stay consistent.
class AuthTypography {
  AuthTypography._();

  // Headings: Elegant Serif
  static TextStyle headingLarge({Color color = AuthColors.textPrimary}) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
      height: 1.2,
    );
  }

  static TextStyle headingMedium({Color color = AuthColors.textPrimary}) {
    return TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.3,
      height: 1.25,
    );
  }

  static TextStyle headingSmall({Color color = AuthColors.textPrimary}) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -0.2,
      height: 1.3,
    );
  }

  // Subtitles & Body: Clean Sans-Serif (Inter)
  static TextStyle subtitle({Color color = AuthColors.textSecondary}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.45,
      letterSpacing: 0.1,
    );
  }

  static TextStyle body({Color color = AuthColors.textSecondary}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.55,
      letterSpacing: 0.1,
    );
  }

  static TextStyle bodySemibold({Color color = AuthColors.textPrimary}) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle input({Color color = AuthColors.textPrimary}) {
    return TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: color);
  }

  static TextStyle hint({Color color = AuthColors.textHint}) {
    return TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: color);
  }

  static TextStyle button({Color color = AuthColors.textPrimary}) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.3,
    );
  }

  static TextStyle caption({Color color = AuthColors.textSecondary}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle sectionTitle({Color color = AuthColors.textPrimary}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.35,
    );
  }
}
