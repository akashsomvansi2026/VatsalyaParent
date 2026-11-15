import 'package:flutter_test/flutter_test.dart';

import 'package:vrajrani_tech_solution/core/utils/formatters.dart';
import 'package:vrajrani_tech_solution/data/models/app_info.dart';
import 'package:vrajrani_tech_solution/data/models/child.dart';
import 'package:vrajrani_tech_solution/data/models/location_point.dart';
import 'package:vrajrani_tech_solution/data/models/sos_event.dart';

void main() {
  group('Child.fromJson', () {
    const json = {
      'id': 7,
      'name': 'Riya',
      'nickname': 'Ria',
      'batteryLevel': 42,
      'trackingEnabled': true,
      'protectionEnabled': false,
      'isOnline': true,
      'lastSeenAtUtc': '2026-09-15T12:00:00Z',
      'latestLocation': {
        'latitude': 11.0168,
        'longitude': 76.9558,
        'accuracy': 9.5,
      },
    };

    test('parses core fields', () {
      final child = Child.fromJson(json);
      expect(child.id, 7);
      expect(child.displayName, 'Ria');
      expect(child.batteryLevel, 42);
      expect(child.trackingEnabled, isTrue);
      expect(child.protectionEnabled, isFalse);
      expect(child.isOnline, isTrue);
      expect(child.lastSeenAtUtc, DateTime.utc(2026, 9, 15, 12));
      expect(child.latestLocation!.latitude, closeTo(11.0168, 1e-9));
    });

    test('defaults to protected when protectionEnabled is absent', () {
      final child = Child.fromJson({'id': 1, 'name': 'A'});
      expect(child.protectionEnabled, isTrue);
      expect(child.trackingEnabled, isTrue);
      expect(child.isOnline, isFalse);
    });

    test('copyWith toggles protection without touching other fields', () {
      final child = Child.fromJson(json);
      final toggled = child.copyWith(protectionEnabled: true);
      expect(toggled.protectionEnabled, isTrue);
      expect(toggled.isOnline, isTrue);
      expect(toggled.displayName, 'Ria');
      expect(child.protectionEnabled, isFalse);
    });
  });

  group('SosEvent.fromJson', () {
    test('isActive reflects status', () {
      final active = SosEvent.fromJson({
        'id': 1,
        'childId': 7,
        'childName': 'Riya',
        'latitude': 11.01,
        'longitude': 76.95,
        'status': 'Active',
        'triggeredAtUtc': '2026-09-10T08:00:00Z',
      });
      final resolved = SosEvent.fromJson({
        'id': 2,
        'childId': 7,
        'childName': 'Riya',
        'latitude': 11.01,
        'longitude': 76.95,
        'status': 'Resolved',
        'triggeredAtUtc': '2026-09-10T08:00:00Z',
      });
      expect(active.isActive, isTrue);
      expect(resolved.isActive, isFalse);
    });
  });

  group('LocationPoint.fromJson', () {
    test('parses numeric fields as doubles with defaults', () {
      final point = LocationPoint.fromJson({
        'latitude': 11.0168,
        'longitude': 76.9558,
        'accuracy': 5,
        'speed': 0,
      });
      expect(point.latitude, closeTo(11.0168, 1e-9));
      expect(point.longitude, closeTo(76.9558, 1e-9));
      expect(point.accuracy, closeTo(5, 1e-9));
      expect(point.speed, 0);
      expect(point.recordedAtUtc, isNull);
    });
  });

  group('AppInfo.fromJson', () {
    test('parses defaults when fields are absent', () {
      final app = AppInfo.fromJson({'packageName': 'com.example.app'});
      expect(app.packageName, 'com.example.app');
      expect(app.appName, isEmpty);
      expect(app.isAllowed, isTrue);
      expect(app.isBlocked, isFalse);
      expect(app.dailyLimitMinutes, 0);
    });
  });

  group('Formatters', () {
    test('duration formats hours/minutes', () {
      expect(Formatters.duration(2 * 3600 * 1000 + 5 * 60 * 1000), '2h 5m');
      expect(Formatters.duration(90 * 1000), '1m 30s');
      expect(Formatters.duration(0), '0s');
    });

    test('dailyLimit formats options', () {
      expect(Formatters.dailyLimit(0), 'Unlimited');
      expect(Formatters.dailyLimit(30), '30 min');
      expect(Formatters.dailyLimit(60), '1 hr');
      expect(Formatters.dailyLimit(90), '1 hr 30 min');
      expect(Formatters.dailyLimit(240), '4 hrs');
    });

    test('batteryFraction clamps', () {
      expect(Formatters.batteryFraction(null), 0);
      expect(Formatters.batteryFraction(100), 1);
      expect(Formatters.batteryFraction(42), closeTo(0.42, 1e-9));
      expect(Formatters.batteryFraction(120), 1);
    });

    test('relativeTime handles null', () {
      expect(Formatters.relativeTime(null), 'never');
    });

    test('coordinates renders five decimals', () {
      expect(Formatters.coordinates(11.0168444, 76.9558234),
          '11.01684, 76.95582');
    });
  });
}