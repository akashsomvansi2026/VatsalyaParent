import 'package:flutter/material.dart';

/// Shared semantic palette for every application surface.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFAFAF8);
  static const Color text = Color(0xFF20211E);
  static const Color muted = Color(0xFF70736D);

  // Shared warm family-app palette.
  static const Color primary = Color(0xFFD85B16);
  static const Color primaryDark = Color(0xFFAD4310);
  static const Color primaryLight = Color(0xFFD85B16);
  static const Color primaryPale = Color(0xFFFF914D);

  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFECEDE8);

  static const Color secondary = Color(0xFF365F91);
  static const Color info = secondary;
  static const Color disabled = Color(0xFFE2E8ED);

  // Status colors.
  static const Color online = Color(0xFF21815C);
  static const Color onlineDark = Color(0xFF176B49);
  static const Color offline = Color(0xFF70736D);
  static const Color warning = Color(0xFF9A5800);

  // SOS / danger.
  static const Color sos = Color(0xFFC62828);
  static const Color sosDark = Color(0xFFB71C1C);
  static const Color sosLight = Color(0xFFE53935);

  static const Color batteryAmber = Color(0xFFFFB300);
  static const Color batteryGreen = onlineDark;
  static const Color batteryRed = sos;

  // Soft tints for icon badges and cards.
  static const Color primaryTint = Color(0xFFFFF0E5);
  static const Color onlineTint = Color(0xFFE8F5E9);
  static const Color sosTint = Color(0xFFFFEBEE);
  static const Color warningTint = Color(0xFFFFF3E0);
  static const Color cardShadow = Color(0x0820211E);

  // Modern semantic aliases.
  static const Color textPrimary = text;
  static const Color textSecondary = muted;
  static const Color error = sos;
  static const Color errorBg = sosTint;
  static const Color success = online;
  static const Color successBg = onlineTint;
  static const Color neutralBg = Color(0xFFF4F4F1);
}
