import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/app_info.dart';

/// Renders authentic real-world app icons for installed child apps.
/// Supports Base64 images, remote URLs, built-in authentic brand glyphs,
/// and deterministic, vibrant gradient badges for all other apps.
class RealAppIcon extends StatelessWidget {
  const RealAppIcon({
    super.key,
    required this.app,
    this.size = 48,
  });

  final AppInfo app;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.26);

    // 1. Check if server/child device provided a custom base64 or network icon.
    final iconData = app.icon?.trim();
    if (iconData != null && iconData.isNotEmpty) {
      if (iconData.startsWith('http://') || iconData.startsWith('https://')) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(
            iconData,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildBrandOrFallback(borderRadius),
          ),
        );
      }
      try {
        final cleaned = iconData.contains(',') ? iconData.split(',').last : iconData;
        final bytes = base64Decode(cleaned);
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildBrandOrFallback(borderRadius),
          ),
        );
      } catch (_) {}
    }

    return _buildBrandOrFallback(borderRadius);
  }

  Widget _buildBrandOrFallback(BorderRadius borderRadius) {
    final pkg = app.packageName.toLowerCase();
    final name = app.appName.toLowerCase();

    final brand = _resolveBrand(pkg, name);
    if (brand != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: brand.backgroundColor,
          gradient: brand.gradient,
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (brand.shadowColor ?? Colors.black).withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: brand.childBuilder(size)),
      );
    }

    // 3. Deterministic branded squircle fallback for any other package.
    final palette = _paletteForPackage(pkg.isNotEmpty ? pkg : name);
    final initial = (app.appName.isNotEmpty
            ? app.appName[0]
            : (app.packageName.isNotEmpty ? app.packageName.split('.').last[0] : 'A'))
        .toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  _BrandIcon? _resolveBrand(String pkg, String name) {
    // YouTube
    if (pkg.contains('youtube') || name.contains('youtube')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFFFF0000),
        shadowColor: const Color(0xFFFF0000),
        childBuilder: (s) => Icon(Icons.play_arrow_rounded, color: Colors.white, size: s * 0.65),
      );
    }

    // WhatsApp
    if (pkg.contains('whatsapp') || name.contains('whatsapp')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF25D366),
        shadowColor: const Color(0xFF25D366),
        childBuilder: (s) => Icon(Icons.chat_bubble_rounded, color: Colors.white, size: s * 0.55),
      );
    }

    // Instagram
    if (pkg.contains('instagram') || name.contains('instagram')) {
      return _BrandIcon(
        gradient: const RadialGradient(
          center: Alignment(-0.8, 0.8),
          radius: 1.2,
          colors: [
            Color(0xFFFEE411),
            Color(0xFFFEDB16),
            Color(0xFFFE3C74),
            Color(0xFFD62976),
            Color(0xFF962FBF),
            Color(0xFF4F5BD5),
          ],
        ),
        shadowColor: const Color(0xFFD62976),
        childBuilder: (s) => Container(
          width: s * 0.58,
          height: s * 0.58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s * 0.16),
            border: Border.all(color: Colors.white, width: 2.2),
          ),
          child: Center(
            child: Container(
              width: s * 0.22,
              height: s * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      );
    }

    // TikTok
    if (pkg.contains('musically') || pkg.contains('tiktok') || name.contains('tiktok')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF010101),
        shadowColor: Colors.black,
        childBuilder: (s) => Icon(Icons.music_note_rounded, color: const Color(0xFF00F2FE), size: s * 0.65),
      );
    }

    // Snapchat
    if (pkg.contains('snapchat') || name.contains('snapchat')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFFFFFC00),
        shadowColor: const Color(0xFFFFFC00),
        childBuilder: (s) => Icon(Icons.sentiment_very_satisfied_rounded, color: Colors.black87, size: s * 0.65),
      );
    }

    // Spotify
    if (pkg.contains('spotify') || name.contains('spotify')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF121212),
        shadowColor: const Color(0xFF1DB954),
        childBuilder: (s) => Icon(Icons.graphic_eq_rounded, color: const Color(0xFF1DB954), size: s * 0.65),
      );
    }

    // Netflix
    if (pkg.contains('netflix') || name.contains('netflix')) {
      return _BrandIcon(
        backgroundColor: Colors.black,
        shadowColor: const Color(0xFFE50914),
        childBuilder: (s) => Text(
          'N',
          style: TextStyle(
            color: const Color(0xFFE50914),
            fontSize: s * 0.62,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
          ),
        ),
      );
    }

    // Roblox
    if (pkg.contains('roblox') || name.contains('roblox')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF232527),
        shadowColor: Colors.black,
        childBuilder: (s) => Transform.rotate(
          angle: -0.22,
          child: Container(
            width: s * 0.44,
            height: s * 0.44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(s * 0.08),
            ),
          ),
        ),
      );
    }

    // Minecraft
    if (pkg.contains('minecraft') || name.contains('minecraft')) {
      return _BrandIcon(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF558B2F), Color(0xFF33691E), Color(0xFF5D4037)],
          stops: [0.0, 0.45, 0.46],
        ),
        shadowColor: const Color(0xFF33691E),
        childBuilder: (s) => Icon(Icons.grid_view_rounded, color: Colors.white.withValues(alpha: 0.9), size: s * 0.55),
      );
    }

    // Google Chrome
    if (pkg.contains('chrome') || name.contains('chrome')) {
      return _BrandIcon(
        backgroundColor: Colors.white,
        shadowColor: const Color(0xFF4285F4),
        childBuilder: (s) => Icon(Icons.public_rounded, color: const Color(0xFF4285F4), size: s * 0.65),
      );
    }

    // Google Maps
    if (pkg.contains('maps') || name == 'maps') {
      return _BrandIcon(
        backgroundColor: Colors.white,
        shadowColor: const Color(0xFFEA4335),
        childBuilder: (s) => Icon(Icons.place_rounded, color: const Color(0xFFEA4335), size: s * 0.65),
      );
    }

    // Gmail
    if (pkg.contains('gm') || pkg.contains('gmail') || name.contains('gmail')) {
      return _BrandIcon(
        backgroundColor: Colors.white,
        shadowColor: const Color(0xFFEA4335),
        childBuilder: (s) => Icon(Icons.mail_rounded, color: const Color(0xFFEA4335), size: s * 0.6),
      );
    }

    // Google Play Store
    if (pkg.contains('vending') || name.contains('play store')) {
      return _BrandIcon(
        backgroundColor: Colors.white,
        shadowColor: const Color(0xFF00C853),
        childBuilder: (s) => Icon(Icons.play_arrow_rounded, color: const Color(0xFF00C853), size: s * 0.68),
      );
    }

    // Discord
    if (pkg.contains('discord') || name.contains('discord')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF5865F2),
        shadowColor: const Color(0xFF5865F2),
        childBuilder: (s) => Icon(Icons.sports_esports_rounded, color: Colors.white, size: s * 0.6),
      );
    }

    // Telegram
    if (pkg.contains('telegram') || name.contains('telegram')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF24A1DE),
        shadowColor: const Color(0xFF24A1DE),
        childBuilder: (s) => Icon(Icons.send_rounded, color: Colors.white, size: s * 0.55),
      );
    }

    // Facebook
    if (pkg.contains('katana') || (pkg.contains('facebook') && !pkg.contains('orca')) || name == 'facebook') {
      return _BrandIcon(
        backgroundColor: const Color(0xFF1877F2),
        shadowColor: const Color(0xFF1877F2),
        childBuilder: (s) => Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: s * 0.72,
            fontWeight: FontWeight.w900,
            fontFamily: 'sans-serif',
          ),
        ),
      );
    }

    // Messenger
    if (pkg.contains('orca') || name.contains('messenger')) {
      return _BrandIcon(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF00C6FF), Color(0xFF0078FF), Color(0xFFA800E0)],
        ),
        shadowColor: const Color(0xFF0078FF),
        childBuilder: (s) => Icon(Icons.bolt_rounded, color: Colors.white, size: s * 0.65),
      );
    }

    // Twitter / X
    if (pkg.contains('twitter') || name == 'x' || name.contains('twitter')) {
      return _BrandIcon(
        backgroundColor: Colors.black,
        shadowColor: Colors.black,
        childBuilder: (s) => Text(
          '𝕏',
          style: TextStyle(
            color: Colors.white,
            fontSize: s * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Reddit
    if (pkg.contains('reddit') || name.contains('reddit')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFFFF4500),
        shadowColor: const Color(0xFFFF4500),
        childBuilder: (s) => Icon(Icons.forum_rounded, color: Colors.white, size: s * 0.6),
      );
    }

    // Pinterest
    if (pkg.contains('pinterest') || name.contains('pinterest')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFFE60023),
        shadowColor: const Color(0xFFE60023),
        childBuilder: (s) => Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontSize: s * 0.65,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
          ),
        ),
      );
    }

    // Twitch
    if (pkg.contains('twitch') || name.contains('twitch')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF9146FF),
        shadowColor: const Color(0xFF9146FF),
        childBuilder: (s) => Icon(Icons.videocam_rounded, color: Colors.white, size: s * 0.6),
      );
    }

    // Amazon
    if (pkg.contains('amazon') || name.contains('amazon')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF232F3E),
        shadowColor: const Color(0xFFFF9900),
        childBuilder: (s) => Icon(Icons.shopping_cart_rounded, color: const Color(0xFFFF9900), size: s * 0.58),
      );
    }

    // Zoom
    if (pkg.contains('zoom') || name.contains('zoom')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF2D8CFF),
        shadowColor: const Color(0xFF2D8CFF),
        childBuilder: (s) => Icon(Icons.videocam_rounded, color: Colors.white, size: s * 0.6),
      );
    }

    // Duolingo
    if (pkg.contains('duolingo') || name.contains('duolingo')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF58CC02),
        shadowColor: const Color(0xFF58CC02),
        childBuilder: (s) => Icon(Icons.school_rounded, color: Colors.white, size: s * 0.6),
      );
    }

    // Gaming: Free Fire / PUBG / Call of Duty / Battle Royale
    if (pkg.contains('freefire') || pkg.contains('pubg') || pkg.contains('callofduty') || name.contains('pubg') || name.contains('free fire')) {
      return _BrandIcon(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF37474F), Color(0xFF212121), Color(0xFFD84315)],
        ),
        shadowColor: const Color(0xFFD84315),
        childBuilder: (s) => Icon(Icons.military_tech_rounded, color: const Color(0xFFFFB300), size: s * 0.65),
      );
    }

    // Candy Crush
    if (pkg.contains('candycrush') || name.contains('candy crush')) {
      return _BrandIcon(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF4081), Color(0xFFE040FB), Color(0xFFFFD700)],
        ),
        shadowColor: const Color(0xFFFF4081),
        childBuilder: (s) => Icon(Icons.cake_rounded, color: Colors.white, size: s * 0.6),
      );
    }

    // Subway Surfers
    if (pkg.contains('subwaysurf') || name.contains('subway surfers')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFFFF9800),
        shadowColor: const Color(0xFFFF9800),
        childBuilder: (s) => Icon(Icons.directions_run_rounded, color: Colors.white, size: s * 0.65),
      );
    }

    // Brawl Stars / Clash of Clans / Supercell
    if (pkg.contains('supercell') || name.contains('brawl stars') || name.contains('clash')) {
      return _BrandIcon(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC107), Color(0xFFFF6F00)],
        ),
        shadowColor: const Color(0xFFFF6F00),
        childBuilder: (s) => Icon(Icons.star_rounded, color: Colors.white, size: s * 0.68),
      );
    }

    // System Utilities
    if (pkg.contains('camera') || name.contains('camera')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF37474F),
        childBuilder: (s) => Icon(Icons.camera_alt_rounded, color: Colors.white, size: s * 0.6),
      );
    }
    if (pkg.contains('gallery') || pkg.contains('photos') || name.contains('gallery') || name.contains('photos')) {
      return _BrandIcon(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFFAB47BC), Color(0xFFEC407A)],
        ),
        childBuilder: (s) => Icon(Icons.photo_library_rounded, color: Colors.white, size: s * 0.6),
      );
    }
    if (pkg.contains('settings') || name.contains('settings')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF607D8B),
        childBuilder: (s) => Icon(Icons.settings_rounded, color: Colors.white, size: s * 0.6),
      );
    }
    if (pkg.contains('clock') || name.contains('clock')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF1E88E5),
        childBuilder: (s) => Icon(Icons.access_time_filled_rounded, color: Colors.white, size: s * 0.6),
      );
    }
    if (pkg.contains('calculator') || name.contains('calculator')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF00897B),
        childBuilder: (s) => Icon(Icons.calculate_rounded, color: Colors.white, size: s * 0.6),
      );
    }
    if (pkg.contains('dialer') || pkg.contains('phone') || name.contains('phone')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF43A047),
        childBuilder: (s) => Icon(Icons.phone_rounded, color: Colors.white, size: s * 0.6),
      );
    }
    if (pkg.contains('messaging') || pkg.contains('mms') || name.contains('messages')) {
      return _BrandIcon(
        backgroundColor: const Color(0xFF1976D2),
        childBuilder: (s) => Icon(Icons.message_rounded, color: Colors.white, size: s * 0.6),
      );
    }

    return null;
  }

  static List<Color> _paletteForPackage(String text) {
    const gradients = [
      [Color(0xFF6366F1), Color(0xFF4F46E5)],
      [Color(0xFFEC4899), Color(0xFFDB2777)],
      [Color(0xFF14B8A6), Color(0xFF0D9488)],
      [Color(0xFFF59E0B), Color(0xFFD97706)],
      [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      [Color(0xFF06B6D4), Color(0xFF0891B2)],
      [Color(0xFF10B981), Color(0xFF059669)],
      [Color(0xFFEF4444), Color(0xFFDC2626)],
      [Color(0xFF3B82F6), Color(0xFF2563EB)],
    ];
    final hash = text.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return gradients[hash % gradients.length];
  }
}

class _BrandIcon {
  const _BrandIcon({
    this.backgroundColor,
    this.gradient,
    this.shadowColor,
    required this.childBuilder,
  });

  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? shadowColor;
  final Widget Function(double size) childBuilder;
}
