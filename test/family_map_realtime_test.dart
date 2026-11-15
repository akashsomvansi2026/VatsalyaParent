import 'dart:async';
import 'package:vrajrani_tech_solution/data/local/children_snapshot_cache.dart';
import 'package:vrajrani_tech_solution/core/errors/app_exception.dart';
import 'package:vrajrani_tech_solution/data/models/child.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/family_map_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/data/remote/realtime_gateway.dart';
import 'package:vrajrani_tech_solution/features/family_map/family_map_screen.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/google_map_view.dart';
import 'package:vrajrani_tech_solution/presentation/providers/infra_providers.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'main_screen_flow_test.dart' show MapSession, MapChildren;

class TestSnapshotCache extends ChildrenSnapshotCache {
  @override
  Future<void> save(int parentId, List<Child> children) async {}
  @override
  Future<CachedChildrenSnapshot?> read(int parentId) async => null;
}

class RefreshChildren extends MapChildren {
  bool fail = false;
  int calls = 0;
  @override
  Future<List<Child>> getChildren() async {
    calls++;
    if (fail) throw const AppException('Network unavailable', isNetwork: true);
    final now = DateTime.now().toUtc().toIso8601String();
    return [
      Child.fromJson({
        'id': 1,
        'name': 'Riya',
        'isOnline': true,
        'trackingEnabled': true,
        'lastSeenAtUtc': now,
        'batteryLevel': 63,
        'trackingStatus': {
          'locationPermissionGranted': true,
          'locationServicesEnabled': true,
          'backgroundTrackingActive': true,
          'reportedAtUtc': now,
        },
        'latestLocation': {
          'latitude': 11,
          'longitude': 77,
          'accuracy': 12,
          'recordedAtUtc': now,
        },
      }),
    ];
  }
}

void main() {
  testWidgets(
    'network failure removes active status; paused events are ignored and resume reloads',
    (tester) async {
      final repo = RefreshChildren();
      final events = StreamController<RealtimeEvent>.broadcast();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(MapSession.new),
            childrenSnapshotCacheProvider.overrideWithValue(
              TestSnapshotCache(),
            ),
            parentsRepositoryProvider.overrideWithValue(repo),
            realtimeStreamProvider.overrideWith((ref) => events.stream),
          ],
          child: const MaterialApp(home: FamilyMapScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      var map = tester.widget<GoogleMapView>(find.byType(GoogleMapView));
      expect(map.synchronized, isTrue);
      map.onChildTap(map.children.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Tracking Active'), findsWidgets);
      repo.fail = true;
      tester.widget<FamilyMapAppBar>(find.byType(FamilyMapAppBar)).onRefresh();
      await tester.pump();
      await tester.pump();
      map = tester.widget<GoogleMapView>(find.byType(GoogleMapView));
      expect(map.synchronized, isFalse);
      expect(find.text('Tracking Active'), findsNothing);
      expect(find.text('Live connection unavailable'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      events.add(
        const RealtimeEvent(
          type: 'child_updated',
          data: {
            'child': {'id': 1, 'name': 'Riya', 'batteryLevel': 5},
          },
        ),
      );
      await tester.pump();
      await tester.pump();
      map = tester.widget<GoogleMapView>(find.byType(GoogleMapView));
      expect(map.children.single.batteryLevel, 63);
      final before = repo.calls;
      repo.fail = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(repo.calls, greaterThan(before));
      map = tester.widget<GoogleMapView>(find.byType(GoogleMapView));
      expect(map.synchronized, isTrue);
      expect(find.text('Tracking Active'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      unawaited(events.close());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'marker selection needs no parent GPS; details update for the selected child only',
    (tester) async {
      final events = StreamController<RealtimeEvent>.broadcast();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(MapSession.new),
            childrenSnapshotCacheProvider.overrideWithValue(
              TestSnapshotCache(),
            ),
            parentsRepositoryProvider.overrideWithValue(MapChildren()),
            realtimeStreamProvider.overrideWith((ref) => events.stream),
          ],
          child: const MaterialApp(home: FamilyMapScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      var map = tester.widget<GoogleMapView>(find.byType(GoogleMapView));
      map.onChildTap(map.children.first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Riya'), findsWidgets);
      expect(find.text('Last known position'), findsOneWidget);
      expect(find.text('Battery: Not reported'), findsOneWidget);
      final now = DateTime.now().toUtc().toIso8601String();
      events.add(
        RealtimeEvent(
          type: 'child_updated',
          data: {
            'child': {
              'id': 1,
              'name': 'Riya',
              'trackingEnabled': true,
              'isOnline': true,
              'lastSeenAtUtc': now,
              'batteryLevel': 63,
              'trackingStatus': {
                'locationPermissionGranted': true,
                'locationServicesEnabled': true,
                'backgroundTrackingActive': true,
                'reportedAtUtc': now,
              },
              'latestLocation': {
                'latitude': 11.0169,
                'longitude': 76.9558,
                'accuracy': 12,
                'recordedAtUtc': now,
              },
            },
          },
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Tracking Active'), findsWidgets);
      expect(find.text('Battery: 63%'), findsOneWidget);
      events.add(
        const RealtimeEvent(
          type: 'child_updated',
          data: {
            'child': {
              'id': 2,
              'name': 'Aarav',
              'trackingEnabled': false,
              'batteryLevel': 21,
            },
          },
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Battery: 63%'), findsOneWidget);
      expect(find.text('Battery: 21%'), findsNothing);
      map = tester.widget<GoogleMapView>(find.byType(GoogleMapView));
      expect(map.children[0].latestLocation!.latitude, 11.0169);
      expect(map.children[1].trackingEnabled, isFalse);
      events.add(
        RealtimeEvent(
          type: 'child_updated',
          data: {
            'child': {
              'id': 1,
              'name': 'Riya',
              'trackingEnabled': true,
              'isOnline': true,
              'latestLocation': {
                'latitude': 20,
                'longitude': 70,
                'recordedAtUtc': DateTime.now()
                    .toUtc()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
              },
            },
          },
        ),
      );
      await tester.pump();
      await tester.pump();
      map = tester.widget<GoogleMapView>(find.byType(GoogleMapView));
      expect(map.children.first.latestLocation!.latitude, 11.0169);
      events.add(
        const RealtimeEvent(
          type: 'child_updated',
          data: {
            'child': {
              'id': 1,
              'name': 'Riya',
              'trackingEnabled': true,
              'latestLocation': null,
            },
          },
        ),
      );
      await tester.pump();
      await tester.pump();
      map = tester.widget<GoogleMapView>(find.byType(GoogleMapView));
      expect(map.children.first.latestLocation, isNull);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      unawaited(events.close());
      await tester.binding.setSurfaceSize(null);
    },
  );
}
