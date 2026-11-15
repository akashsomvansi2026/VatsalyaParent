import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart' as sdk;
import 'package:vrajrani_tech_solution/features/family_map/services/places_service.dart';

class FakePlaces extends sdk.FlutterGooglePlacesSdk {
  FakePlaces() : super('test');
  int calls = 0;
  Object? failure;
  List<String>? types;
  @override
  Future<sdk.SearchNearbyResponse> searchNearby({
    required List<sdk.PlaceField> fields,
    required sdk.CircularBounds locationRestriction,
    List<String>? includedTypes,
    List<String>? includedPrimaryTypes,
    List<String>? excludedTypes,
    List<String>? excludedPrimaryTypes,
    sdk.NearbySearchRankPreference? rankPreference,
    String? regionCode,
    int? maxResultCount,
  }) async {
    calls++;
    if (failure != null) throw failure!;
    types = includedTypes;
    return const sdk.SearchNearbyResponse([
      sdk.Place(id: 'p1', name: 'School', latLng: sdk.LatLng(lat: 12, lng: 77)),
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Android Nearby reads the same packaged key as Maps', () async {
    const channel = MethodChannel('vatsalya/maps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getApiKey');
          return 'test-packaged-key';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    expect(await PlacesService.loadApiKey(), 'test-packaged-key');
  });
  test('missing key fails clearly before calling Places', () async {
    final service = PlacesService(keyLoader: () async => null);
    await expectLater(
      service.searchNearby(const LatLng(12, 77), 'School'),
      throwsA(
        isA<NearbyFailure>().having(
          (e) => e.kind,
          'kind',
          NearbyFailureKind.configuration,
        ),
      ),
    );
  });
  test('failed SDK searches can retry and do not poison the cache', () async {
    final client = FakePlaces()
      ..failure = PlatformException(
        code: 'API_ERROR_NEARBY_SEARCH',
        message: 'Network error',
      );
    final service = PlacesService(sdk: client);
    await expectLater(
      service.searchNearby(const LatLng(12, 77), 'School'),
      throwsA(
        isA<NearbyFailure>().having(
          (e) => e.kind,
          'kind',
          NearbyFailureKind.network,
        ),
      ),
    );
    client.failure = null;
    expect(
      await service.searchNearby(const LatLng(12, 77), 'School'),
      hasLength(1),
    );
    expect(client.calls, 2);
  });
  test('configuration and quota errors are distinct and sanitized', () {
    final denied = NearbyFailure.from(
      PlatformException(
        code: 'API_ERROR',
        message: 'API key secret-value is not authorized',
      ),
    );
    expect(denied.kind, NearbyFailureKind.configuration);
    expect(denied.message, isNot(contains('secret-value')));
    expect(
      NearbyFailure.from(PlatformException(code: 'RESOURCE_EXHAUSTED')).kind,
      NearbyFailureKind.quota,
    );
  });
  test(
    'Nearby caches by origin and category for exactly five minutes',
    () async {
      var now = DateTime.utc(2026, 10, 15);
      final client = FakePlaces();
      final service = PlacesService(sdk: client, now: () => now);
      const origin = LatLng(12, 77);
      final result = await service.searchNearby(origin, 'School');
      expect(result.single.position, origin);
      await service.searchNearby(origin, 'School');
      expect(client.calls, 1);
      now = now.add(const Duration(minutes: 4, seconds: 59));
      await service.searchNearby(origin, 'School');
      expect(client.calls, 1);
      now = now.add(const Duration(seconds: 1));
      await service.searchNearby(origin, 'School');
      expect(client.calls, 2);
      await service.searchNearby(origin, 'Hospital');
      expect(client.calls, 3);
      expect(client.types, ['hospital']);
      await service.searchNearby(const LatLng(13, 77), 'Hospital');
      expect(client.calls, 4);
    },
  );
  test('Nearby rejects unknown categories without an SDK request', () async {
    final client = FakePlaces();
    await expectLater(
      PlacesService(sdk: client).searchNearby(const LatLng(0, 0), 'Unknown'),
      throwsArgumentError,
    );
    expect(client.calls, 0);
  });
}
