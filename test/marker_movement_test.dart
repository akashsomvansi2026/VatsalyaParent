import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vrajrani_tech_solution/data/models/child.dart';
import 'package:vrajrani_tech_solution/data/models/location_point.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/google_map_view.dart';

void main() {
  testWidgets(
    'short fresh fixes animate; long gaps snap to measured coordinates; taps identify child',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final key = GlobalKey<GoogleMapViewState>();
      final now = DateTime.now().toUtc();
      int? tapped;
      Child child(double latitude, int seconds) => Child(
        id: 1,
        name: 'Riya',
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
          recordedAtUtc: now.subtract(Duration(seconds: seconds)),
        ),
      );
      Future<void> render(Child c) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                key: key,
                parent: null,
                children: [c],
                selected: c,
                isValid: (c) => c.latestLocation!.isValid,
                pointOf: (c) => LatLng(
                  c.latestLocation!.latitude,
                  c.latestLocation!.longitude,
                ),
                locating: false,
                busy: false,
                onMapReady: () {},
                onFit: () {},
                onLocate: () {},
                onNearby: () {},
                onChooseChild: () {},
                onChildTap: (c) => tapped = c.id,
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }

      await render(child(28, 20));
      expect(key.currentState!.markers.single.position.latitude, 28);
      await render(child(28.0002, 10));
      expect(key.currentState!.starts, isNotEmpty);
      await tester.pump(const Duration(milliseconds: 400));
      final halfway = key.currentState!.markers.single.position.latitude;
      expect(halfway, greaterThan(28));
      expect(halfway, lessThan(28.0002));
      await tester.pump(const Duration(milliseconds: 500));
      expect(key.currentState!.markers.single.position.latitude, 28.0002);
      key.currentState!.markers.single.onTap!();
      expect(tapped, 1);
      await render(child(29, 0));
      expect(key.currentState!.starts, isEmpty);
      expect(key.currentState!.markers.single.position.latitude, 29);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
