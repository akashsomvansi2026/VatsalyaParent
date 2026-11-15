/// App-level policy for a child device (installed app row).
class AppInfo {
  const AppInfo({
    required this.packageName,
    required this.appName,
    required this.isAllowed,
    required this.isBlocked,
    required this.dailyLimitMinutes,
    this.icon,
    this.updatedAtUtc,
  });

  final String packageName;
  final String appName;
  final bool isAllowed;
  final bool isBlocked;
  final int dailyLimitMinutes;
  final String? icon;
  final DateTime? updatedAtUtc;

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      packageName: json['packageName'] as String? ?? '',
      appName: json['appName'] as String? ?? '',
      isAllowed: json['isAllowed'] as bool? ?? true,
      isBlocked: json['isBlocked'] as bool? ?? false,
      dailyLimitMinutes: json['dailyLimitMinutes'] as int? ?? 0,
      icon: (json['icon'] ?? json['iconUrl'] ?? json['iconBase64'] ?? json['appIcon']) as String?,
      updatedAtUtc: _parseDate(json['updatedAtUtc']),
    );
  }

  AppInfo copyWith({
    bool? isAllowed,
    bool? isBlocked,
    int? dailyLimitMinutes,
    String? icon,
  }) {
    return AppInfo(
      packageName: packageName,
      appName: appName,
      isAllowed: isAllowed ?? this.isAllowed,
      isBlocked: isBlocked ?? this.isBlocked,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      icon: icon ?? this.icon,
      updatedAtUtc: updatedAtUtc,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
