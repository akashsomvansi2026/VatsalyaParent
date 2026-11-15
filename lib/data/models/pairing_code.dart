/// A 6-character code a child app uses to pair with a parent.
class PairingCode {
  const PairingCode({
    required this.id,
    required this.code,
    required this.isActive,
    required this.isUsed,
    required this.createdAtUtc,
    this.expiresAtUtc,
    this.childName,
    this.childEmail,
    this.parent,
    this.accessToken,
    this.apiUrl,
  });

  final int id;
  final String code;
  final bool isActive;
  final bool isUsed;
  final DateTime createdAtUtc;
  final DateTime? expiresAtUtc;
  final String? childName, childEmail, accessToken, apiUrl;
  final Map<String, dynamic>? parent;

  factory PairingCode.fromJson(Map<String, dynamic> json) {
    return PairingCode(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isUsed: json['isUsed'] as bool? ?? false,
      createdAtUtc: _parseDate(json['createdAtUtc']) ?? DateTime.now().toUtc(),
      expiresAtUtc: _parseDate(json['expiresAtUtc']),
      childName: json['childName'] as String?,
      childEmail: json['childEmail'] as String?,
      parent: json['parent'] is Map
          ? Map<String, dynamic>.from(json['parent'] as Map)
          : null,
      accessToken: json['accessToken'] as String?,
      apiUrl: json['apiUrl'] as String?,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
