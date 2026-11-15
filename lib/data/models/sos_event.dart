/// SOS event raised from a child device.
class SosEvent {
  const SosEvent({
    required this.id,
    required this.childId,
    required this.childName,
    required this.latitude,
    required this.longitude,
    this.address,
    this.message,
    required this.status,
    required this.triggeredAtUtc,
    this.resolvedAtUtc,
  });

  final int id;
  final int childId;
  final String childName;
  final double latitude;
  final double longitude;
  final String? address;
  final String? message;
  final String status;
  final DateTime triggeredAtUtc;
  final DateTime? resolvedAtUtc;

  bool get isActive => status == 'Active';

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    return SosEvent(
      id: json['id'] as int,
      childId: json['childId'] as int? ?? 0,
      childName: json['childName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? '',
      triggeredAtUtc:
          _parseDate(json['triggeredAtUtc']) ?? DateTime.now().toUtc(),
      resolvedAtUtc: _parseDate(json['resolvedAtUtc']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
