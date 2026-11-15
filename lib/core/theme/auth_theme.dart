import 'app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_colors.dart';

/// Complete theme configuration and shared visual constants for the
/// minimalist iOS-inspired authentication design system.
class AuthTheme {
  AuthTheme._();

  static const double fieldRadius = 16.0;
  static const double buttonRadius = 16.0;
  static const double fieldHeight = 54.0;
  static const double buttonHeight = 54.0;
  static const double horizontalPadding = 24.0;

  /// System UI overlay style for seamless light status bar integration
  static const SystemUiOverlayStyle lightSystemUiOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS
    systemNavigationBarColor: AuthColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// Shadow for text fields matching the clean, tactile look
  static const List<BoxShadow> fieldShadow = [
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 10,
      offset: Offset(0, 3),
      spreadRadius: 0,
    ),
  ];

  /// Shadow for pill primary buttons matching the reference image's soft drop shadow
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x2E242424),
      blurRadius: 12,
      offset: Offset(0, 5),
      spreadRadius: 0,
    ),
  ];

  /// Subtle container card shadow for legal sections or modals
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08242424),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Dedicated ThemeData builder if wrapping auth screens in their own theme
  static ThemeData get themeData => AppTheme.light();
}
