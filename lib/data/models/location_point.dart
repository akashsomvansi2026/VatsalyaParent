/// A tracked location point for a child.
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.heading,
    this.headingAccuracy,
    this.isMocked,
    this.speed,
    this.accuracy,
    this.batteryLevel,
    this.recordedAtUtc,
  });

  final double latitude;
  final double longitude;
  final double? altitude;
  final double? heading;
  final double? headingAccuracy;
  final bool? isMocked;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;

  /// Keep timestamp-less legacy fixes as last-known only. Never render future
  /// measurements or retain coordinates past the existing seven-day cache window.
  bool isDisplayableAt(DateTime now) {
    if (!isValid) return false;
    final captured = recordedAtUtc;
    if (captured == null) return true;
    final age = now.toUtc().difference(captured);
    return !age.isNegative && age <= const Duration(days: 7);
  }

  bool get hasReliableHeading =>
      heading != null &&
      heading!.isFinite &&
      heading! >= 0 &&
      heading! < 360 &&
      headingAccuracy != null &&
      headingAccuracy!.isFinite &&
      headingAccuracy! >= 0 &&
      headingAccuracy! <= 30 &&
      speed != null &&
      speed!.isFinite &&
      speed! >= 1 &&
      isMocked != true;
  final double? speed;
  final double? accuracy;
  final int? batteryLevel;
  final DateTime? recordedAtUtc;

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num?)?.toDouble() ?? double.nan,
      longitude: (json['longitude'] as num?)?.toDouble() ?? double.nan,
      altitude: (json['altitude'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      headingAccuracy: (json['headingAccuracy'] as num?)?.toDouble(),
      isMocked: json['isMocked'] as bool?,
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      batteryLevel: json['batteryLevel'] as int?,
      recordedAtUtc: _parseDate(json['recordedAtUtc']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
