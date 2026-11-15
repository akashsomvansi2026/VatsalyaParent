/// Daily per-app screen-time record.
class UsageRecord {
  const UsageRecord({
    required this.packageName,
    required this.appName,
    required this.usageDate,
    required this.usedMillis,
    this.updatedAtUtc,
  });

  final String packageName;
  final String appName;
  final DateTime usageDate;
  final int usedMillis;
  final DateTime? updatedAtUtc;

  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    return UsageRecord(
      packageName: json['packageName'] as String? ?? '',
      appName: json['appName'] as String? ?? '',
      usageDate:
          DateTime.tryParse(json['usageDate'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      usedMillis: (json['usedMillis'] as num?)?.toInt() ?? 0,
      updatedAtUtc: _parseDate(json['updatedAtUtc']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
