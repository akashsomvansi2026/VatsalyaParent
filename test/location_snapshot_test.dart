import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/core/utils/location_snapshot.dart';
import 'package:vrajrani_tech_solution/core/utils/child_location_status.dart';
import 'package:vrajrani_tech_solution/data/models/child.dart';
import 'package:vrajrani_tech_solution/data/models/location_point.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 12);
  Child child(
    DateTime? captured, {
    double latitude = 28,
    String device = 'phone-a',
  }) => Child(
    id: 1,
    name: 'Riya',
    deviceId: device,
    trackingEnabled: true,
    isOnline: true,
    lastSeenAtUtc: now,
    trackingStatus: {
      'locationPermissionGranted': true,
      'locationServicesEnabled': true,
      'backgroundTrackingActive': true,
      'reportedAtUtc': now.toIso8601String(),
    },
    latestLocation: LocationPoint(
      latitude: latitude,
      longitude: 77,
      accuracy: 12,
      recordedAtUtc: captured,
    ),
  );
  test(
    'future and over-retention fixes cannot replace a valid last-known position',
    () {
      final previous = child(now.subtract(const Duration(minutes: 1)));
      for (final next in [
        child(now.add(const Duration(seconds: 1)), latitude: 30),
        child(now.subtract(const Duration(days: 8)), latitude: 31),
        child(now, latitude: 100),
      ]) {
        expect(
          mergeLocationSnapshot(previous, next, now: now).latestLocation,
          same(previous.latestLocation),
        );
        expect(
          mergeLocationSnapshot(null, next, now: now).latestLocation,
          isNull,
        );
      }
    },
  );
  test(
    'snapshots clear locations authoritatively and never mix installations',
    () {
      final previous = child(now);
      expect(
        mergeLocationSnapshot(
          previous,
          previous.copyWith(clearLatestLocation: true),
          now: now,
        ).latestLocation,
        isNull,
      );
      expect(
        mergeLocationSnapshot(
          previous,
          child(now.subtract(const Duration(days: 8)), device: 'phone-b'),
          now: now,
        ).latestLocation,
        isNull,
      );
      expect(
        mergeLocationSnapshot(
          previous,
          child(now.subtract(const Duration(minutes: 1)), latitude: 29),
          now: now,
        ).latestLocation,
        same(previous.latestLocation),
      );
    },
  );
  test('transport outage never reports active; timestamps remain visible', () {
    final c = child(now);
    expect(ChildLocationStatus.fromChild(c, now: now).isRecent, isTrue);
    final offline = ChildLocationStatus.fromChild(
      c,
      now: now,
      synchronized: false,
    );
    expect(offline.isRecent, isFalse);
    expect(offline.hasLocation, isTrue);
    expect(offline.detail, contains('unverified'));
    expect(
      ChildLocationStatus.fromChild(child(null), now: now).isRecent,
      isFalse,
    );
  });
}
