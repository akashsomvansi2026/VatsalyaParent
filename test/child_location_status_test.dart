import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/core/utils/child_location_status.dart';
import 'package:vrajrani_tech_solution/data/models/child.dart';
import 'package:vrajrani_tech_solution/data/models/location_point.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);
  Child child({
    bool online = true,
    bool enabled = true,
    int seconds = 10,
    bool permission = true,
    bool services = true,
    bool background = true,
    bool legacy = false,
    double accuracy = 12,
    double latitude = 26.85,
    int reportSeconds = 5,
    int seenSeconds = 5,
    bool mocked = false,
  }) => Child(
    id: 1,
    name: 'Riya',
    trackingEnabled: enabled,
    isOnline: online,
    lastSeenAtUtc: now.subtract(Duration(seconds: seenSeconds)),
    trackingStatus: legacy
        ? null
        : {
            'locationPermissionGranted': permission,
            'locationServicesEnabled': services,
            'backgroundTrackingActive': background,
            'reportedAtUtc': now
                .subtract(Duration(seconds: reportSeconds))
                .toIso8601String(),
          },
    latestLocation: LocationPoint(
      latitude: latitude,
      longitude: 80.95,
      accuracy: accuracy,
      isMocked: mocked,
      recordedAtUtc: now.subtract(Duration(seconds: seconds)),
    ),
  );
  TrackingState state(Child c) =>
      ChildLocationStatus.fromChild(c, now: now).state;
  test('fresh GPS requires all independent device checks', () {
    expect(state(child()), TrackingState.active);
    expect(state(child(legacy: true)), TrackingState.unavailable);
    expect(state(child(background: false)), TrackingState.unavailable);
    expect(state(child(reportSeconds: 121)), TrackingState.unavailable);
  });
  test('disabled toggle or missing permission/services is explicit', () {
    for (final c in [
      child(enabled: false),
      child(permission: false),
      child(services: false),
    ]) {
      expect(state(c), TrackingState.disabled);
      expect(ChildLocationStatus.fromChild(c, now: now).hasLocation, isTrue);
    }
  });
  test('online heartbeat cannot freshen an old or future location', () {
    expect(state(child(seconds: 181)), TrackingState.stale);
    expect(state(child(seconds: -10)), TrackingState.unavailable);
    expect(
      ChildLocationStatus.fromChild(child(seconds: -10), now: now).hasLocation,
      isFalse,
    );
    expect(state(child(online: false)), TrackingState.offline);
    expect(state(child(seenSeconds: 121)), TrackingState.offline);
  });
  test('poor, simulated and invalid locations are never verified live', () {
    expect(state(child(accuracy: 500)), TrackingState.unavailable);
    expect(state(child(accuracy: 0)), TrackingState.unavailable);
    expect(state(child(mocked: true)), TrackingState.unavailable);
    expect(
      ChildLocationStatus.fromChild(child(latitude: 91), now: now).hasLocation,
      isFalse,
    );
    expect(LocationPoint.fromJson({}).isValid, isFalse);
    expect(
      LocationPoint.fromJson({'latitude': 0, 'longitude': 0}).isValid,
      isTrue,
    );
  });
  test('bearing requires measured accuracy and motion', () {
    expect(
      const LocationPoint(
        latitude: 0,
        longitude: 0,
        heading: 90,
        speed: 2,
      ).hasReliableHeading,
      isFalse,
    );
    expect(
      const LocationPoint(
        latitude: 0,
        longitude: 0,
        heading: 90,
        headingAccuracy: 10,
        speed: 2,
      ).hasReliableHeading,
      isTrue,
    );
  });
}
