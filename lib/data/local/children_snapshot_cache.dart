import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/child.dart';

class CachedChildrenSnapshot {
  const CachedChildrenSnapshot(this.children, this.savedAtUtc);
  final List<Child> children;
  final DateTime savedAtUtc;
}

/// Minimal, account-scoped encrypted cache for showing the last synchronized
/// child locations during a Parent network outage.
class ChildrenSnapshotCache {
  ChildrenSnapshotCache([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  String _key(int parentId) => 'vg_children_snapshot_v1_$parentId';

  Future<void> save(int parentId, List<Child> children) async {
    final payload = {
      'savedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'children': children
          .map(
            (child) => {
              'id': child.id,
              'name': child.name,
              'nickname': child.nickname,
              'avatarUrl': child.avatarUrl,
              'deviceName': child.deviceName,
              'deviceModel': child.deviceModel,
              'trackingStatus': child.trackingStatus,
              'locationStaleAfterSeconds': child.locationStaleAfterSeconds,
              'batteryLevel': child.batteryLevel,
              'trackingEnabled': child.trackingEnabled,
              'protectionEnabled': child.protectionEnabled,
              'lastSeenAtUtc': child.lastSeenAtUtc?.toIso8601String(),
              'latestLocation': child.latestLocation?.isValid != true
                  ? null
                  : {
                      'latitude': child.latestLocation!.latitude,
                      'longitude': child.latestLocation!.longitude,
                      'accuracy': child.latestLocation!.accuracy,
                      'speed': child.latestLocation!.speed,
                      'heading': child.latestLocation!.heading,
                      'headingAccuracy': child.latestLocation!.headingAccuracy,
                      'isMocked': child.latestLocation!.isMocked,
                      'batteryLevel': child.latestLocation!.batteryLevel,
                      'recordedAtUtc': child.latestLocation!.recordedAtUtc
                          ?.toIso8601String(),
                    },
            },
          )
          .toList(),
    };
    await _storage.write(key: _key(parentId), value: jsonEncode(payload));
  }

  Future<CachedChildrenSnapshot?> read(int parentId) async {
    try {
      final value = await _storage.read(key: _key(parentId));
      if (value == null) return null;
      final payload = jsonDecode(value) as Map<String, dynamic>;
      final savedAt = DateTime.parse(payload['savedAtUtc'] as String).toUtc();
      if (DateTime.now().toUtc().difference(savedAt) >
          const Duration(days: 7)) {
        await clear(parentId);
        return null;
      }
      final rows = payload['children'] as List;
      return CachedChildrenSnapshot(
        rows
            .map(
              (row) => Child.fromJson(
                Map<String, dynamic>.from(row as Map),
              ).copyWith(isOnline: false),
            )
            .toList(),
        savedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(int parentId) => _storage.delete(key: _key(parentId));
}
