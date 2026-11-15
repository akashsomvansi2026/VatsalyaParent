import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vrajrani_tech_solution/features/family_map/services/places_service.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/nearby_places_sheet.dart';
import 'google_places_service_test.dart' show FakePlaces;

void main() {
  testWidgets('Nearby shows a specific network failure and Retry loads results', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    final sdk = FakePlaces()
      ..failure = PlatformException(
        code: 'API_ERROR',
        message: 'Network error',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NearbyPlacesSheet(
            origin: const LatLng(12, 77),
            service: PlacesService(sdk: sdk),
            onPlace: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text(
        'Could not connect to nearby search. Check your internet connection and retry.',
      ),
      findsOneWidget,
    );
    sdk.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
    expect(sdk.calls, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
}
