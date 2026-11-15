import 'location_point.dart';

/// A child device paired to the current parent.
class Child {
  const Child({
    required this.id,
    required this.name,
    this.nickname,
    this.trackingStatus,
    this.locationStaleAfterSeconds = 180,
    this.avatarUrl,
    this.deviceId,
    this.deviceName,
    this.deviceToken,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    this.batteryLevel,
    required this.trackingEnabled,
    this.protectionEnabled = true,
    required this.isOnline,
    this.lastSeenAtUtc,
    this.latestLocation,
    this.createdAtUtc,
  });

  final Map<String, dynamic>? trackingStatus;
  final int locationStaleAfterSeconds;
  final int id;
  final String name;
  final String? nickname;
  final String? avatarUrl;
  final String? deviceId;
  final String? deviceName;
  final String? deviceToken;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final int? batteryLevel;
  final bool trackingEnabled;
  final bool protectionEnabled;
  final bool isOnline;
  final DateTime? lastSeenAtUtc;
  final LocationPoint? latestLocation;
  final DateTime? createdAtUtc;

  String get displayName => nickname?.isNotEmpty == true ? nickname! : name;

  factory Child.fromJson(Map<String, dynamic> json) {
    final location = json['latestLocation'];
    return Child(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      nickname: json['nickname'] as String?,
      trackingStatus: json['trackingStatus'] is Map
          ? Map<String, dynamic>.from(json['trackingStatus'] as Map)
          : null,
      locationStaleAfterSeconds:
          (json['locationStaleAfterSeconds'] as num?)?.toInt() ?? 180,
      avatarUrl: json['avatarUrl'] as String?,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      deviceToken: json['deviceToken'] as String?,
      deviceModel: json['deviceModel'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      batteryLevel: json['batteryLevel'] as int?,
      trackingEnabled: json['trackingEnabled'] as bool? ?? true,
      protectionEnabled: json['protectionEnabled'] as bool? ?? true,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAtUtc: _parseDate(json['lastSeenAtUtc']),
      latestLocation: location is Map<String, dynamic>
          ? LocationPoint.fromJson(location)
          : null,
      createdAtUtc: _parseDate(json['createdAtUtc']),
    );
  }

  Child copyWith({
    String? name,
    String? nickname,
    String? deviceName,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
    int? batteryLevel,
    bool? trackingEnabled,
    bool? protectionEnabled,
    bool? isOnline,
    DateTime? lastSeenAtUtc,
    LocationPoint? latestLocation,
    bool clearLatestLocation = false,
  }) {
    return Child(
      id: id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      trackingStatus: trackingStatus,
      locationStaleAfterSeconds: locationStaleAfterSeconds,
      avatarUrl: avatarUrl,
      deviceId: deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceToken: deviceToken,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      protectionEnabled: protectionEnabled ?? this.protectionEnabled,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAtUtc: lastSeenAtUtc ?? this.lastSeenAtUtc,
      latestLocation: clearLatestLocation
          ? null
          : latestLocation ?? this.latestLocation,
      createdAtUtc: createdAtUtc,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
