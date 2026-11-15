import '../../core/errors/app_exception.dart';
import '../models/app_info.dart';
import '../models/child.dart';
import '../models/location_point.dart';
import '../models/pairing_code.dart';
import '../models/sos_event.dart';
import '../models/usage_record.dart';
import '../remote/api_client.dart';
import '../remote/api_endpoints.dart';

/// All parent-dashboard operations against the Vrajrani Tech Solution API.
///
/// Parses the mixed enveloped/raw response shapes exactly as the portal
/// client does. Business rules (clamping, ownership checks, monotonic usage
/// merge) live server-side and are intentionally not duplicated here.
class ParentsRepository {
  ParentsRepository({required this.apiClient});

  final ApiClient apiClient;
  Future<Child> getChild(int id) async =>
      Child.fromJson(await apiClient.getObject(ApiEndpoints.child(id)));

  Future<List<Child>> getChildren() async {
    final list = await apiClient.getList(ApiEndpoints.children);
    return list.map(Child.fromJson).toList();
  }

  Future<void> deleteChild(int childId) async {
    await apiClient.delete(ApiEndpoints.child(childId));
  }

  Future<List<PairingCode>> getPairingCodes() async {
    final list = await apiClient.getList(ApiEndpoints.pairingCodes);
    return list.map(PairingCode.fromJson).toList();
  }

  Future<PairingCode> createPairingCode({int? validForHours}) async {
    final json = await apiClient.postRaw(ApiEndpoints.pairingCodes, {
      'validForHours': ?validForHours,
    });
    return PairingCode.fromJson(json);
  }

  Future<void> revokePairingCode(int codeId) async {
    await apiClient.delete(ApiEndpoints.pairingCode(codeId));
  }

  Future<List<LocationPoint>> getLocations(
    int childId, {
    int limit = 100,
  }) async {
    final list = await apiClient.getList(
      ApiEndpoints.childLocations(childId, limit: limit),
    );
    return list.map(LocationPoint.fromJson).toList();
  }

  Future<List<AppInfo>> getApps(int childId) async {
    final list = await apiClient.getList(ApiEndpoints.childApps(childId));
    return list.map(AppInfo.fromJson).toList();
  }

  Future<List<AppInfo>> setAppPolicy(int childId, List<AppInfo> apps) async {
    final envelope = await apiClient.postEnveloped<List<AppInfo>>(
      ApiEndpoints.childAppPolicy(childId),
      {
        'childId': childId,
        'apps': apps
            .map(
              (a) => {
                'packageName': a.packageName,
                'isAllowed': a.isAllowed,
                'isBlocked': a.isBlocked,
                'dailyLimitMinutes': a.dailyLimitMinutes,
              },
            )
            .toList(),
      },
      dataParser: (json) {
        final appsJson = json['apps'];
        if (appsJson is List) {
          return appsJson
              .whereType<Map<String, dynamic>>()
              .map(AppInfo.fromJson)
              .toList();
        }
        return const <AppInfo>[];
      },
    );
    return envelope.data ?? const <AppInfo>[];
  }

  Future<List<UsageRecord>> getUsage(int childId, {int days = 7}) async {
    final list = await apiClient.getList(
      ApiEndpoints.childUsage(childId, days: days),
    );
    return list.map(UsageRecord.fromJson).toList();
  }

  Future<Child> setTracking(int childId, bool enabled) async {
    final envelope = await apiClient.postEnveloped<Child>(
      ApiEndpoints.childTracking(childId),
      {'trackingEnabled': enabled},
      dataParser: (json) =>
          Child.fromJson(json['child'] as Map<String, dynamic>? ?? json),
    );
    if (envelope.data != null) return envelope.data!;
    throw const AppException('Failed to update tracking.');
  }

  Future<void> setProtection(int childId, bool enabled) async {
    await apiClient.postConfirm(ApiEndpoints.childProtection(childId), {
      'protectionEnabled': enabled,
    });
  }

  /// Pushes a new Android keyguard password for the child device. The child
  /// applies it and locks the screen immediately (Device Owner required).
  Future<void> setDeviceLock(int childId, String pin) async {
    await apiClient.postConfirm(ApiEndpoints.childDeviceLock(childId), {
      'pin': pin,
    });
  }

  /// Pushes a new launcher parent-area PIN for the child device (remote
  /// overwrite; valid value is 4-8 numeric digits).
  Future<void> setParentLock(int childId, String pin) async {
    await apiClient.postConfirm(ApiEndpoints.childParentLock(childId), {
      'pin': pin,
    });
  }

  Future<List<SosEvent>> getSosEvents() async {
    final list = await apiClient.getList(ApiEndpoints.sosEvents);
    return list.map(SosEvent.fromJson).toList();
  }

  Future<void> resolveSos(int eventId) async {
    await apiClient.postConfirm(ApiEndpoints.resolveSos(eventId), null);
  }
}
