import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final DateFormat _shortDateTime = DateFormat('d MMM yyyy, h:mm a');

  /// Formats a UTC timestamp the same way the portal does:
  /// "just now", "Nm ago", "Nh ago", "Nd ago", then a local date.
  static String relativeTime(DateTime? utc) {
    if (utc == null) return 'never';
    final diff = DateTime.now().toUtc().difference(utc);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _shortDateTime.format(utc.toLocal());
  }

  /// Local-friendly date time.
  static String dateTime(DateTime? utc) {
    if (utc == null) return '—';
    return _shortDateTime.format(utc.toLocal());
  }

  /// Human readable coordinates (portal renders them as lat, lng).
  static String coordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  /// Battery color thresholding matching the portal (>=50 green, >=20 amber).
  static String batteryLabel(int? battery) =>
      battery == null ? '—' : '$battery%';

  /// Daily limit in minutes rendered like the portal's select options.
  static String dailyLimit(int minutes) {
    if (minutes <= 0) return 'Unlimited';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return hours == 1 ? '1 hr' : '$hours hrs';
    return '$hours hr $rem min';
  }

  /// Screen-time duration from millis as "h m" (or "m s" for short runs),
  /// mirroring the portal's h/m display.
  static String duration(int millis) {
    final totalSeconds = (millis / 1000).round();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  /// Battery bar fill fraction (0..1), clamped.
  static double batteryFraction(int? battery) {
    final value = (battery ?? 0) / 100.0;
    return value.clamp(0.0, 1.0);
  }
}
