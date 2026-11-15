import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart' as places;
import '../../../core/config/api_keys.dart';

final placesServiceProvider = Provider((ref) => PlacesService());

class NearbyPlace {
  const NearbyPlace(
    this.id,
    this.name,
    this.address,
    this.position,
    this.rating,
  );
  final String id, name, address;
  final LatLng position;
  final double? rating;
}

enum NearbyFailureKind { configuration, network, quota, unsupported, unknown }

class NearbyFailure implements Exception {
  const NearbyFailure(this.kind);
  final NearbyFailureKind kind;
  String get message => switch (kind) {
    NearbyFailureKind.configuration =>
      'Nearby search is not configured for this app. Check Places API access, billing and app key restrictions.',
    NearbyFailureKind.network =>
      'Could not connect to nearby search. Check your internet connection and retry.',
    NearbyFailureKind.quota =>
      'Nearby search is temporarily at its usage limit. Please try again later.',
    NearbyFailureKind.unsupported =>
      'Nearby search is unavailable on this device. Update or restart the app.',
    NearbyFailureKind.unknown =>
      'Nearby search could not finish. Please retry.',
  };

  static NearbyFailure from(Object error) {
    if (error is NearbyFailure) return error;
    if (error is TimeoutException) {
      return const NearbyFailure(NearbyFailureKind.network);
    }
    if (error is MissingPluginException) {
      return const NearbyFailure(NearbyFailureKind.unsupported);
    }
    if (error is PlatformException) {
      // Inspect locally; never expose SDK messages that might contain a key.
      final value = '${error.code} ${error.message ?? ""}'.toLowerCase();
      if (value.contains('quota') ||
          value.contains('resource_exhausted') ||
          value.contains('rate limit') ||
          value.contains('over_query_limit')) {
        return const NearbyFailure(NearbyFailureKind.quota);
      }
      if (value.contains('network') ||
          value.contains('timeout') ||
          value.contains('connection') ||
          value.contains('unavailable')) {
        return const NearbyFailure(NearbyFailureKind.network);
      }
      if (value.contains('key') ||
          value.contains('denied') ||
          value.contains('billing') ||
          value.contains('authorized') ||
          value.contains('not enabled') ||
          value.contains('9003') ||
          value.contains('9011')) {
        return const NearbyFailure(NearbyFailureKind.configuration);
      }
    }
    return const NearbyFailure(NearbyFailureKind.unknown);
  }
}

class PlacesService {
  PlacesService({
    places.FlutterGooglePlacesSdk? sdk,
    DateTime Function()? now,
    Future<String?> Function()? keyLoader,
    // Keep the existing public sdk injection parameter for callers and tests.
    // ignore: prefer_initializing_formals
  }) : _sdk = sdk,
       _keyLoader = keyLoader ?? loadApiKey,
       _now = now ?? DateTime.now;
  places.FlutterGooglePlacesSdk? _sdk;
  final Future<String?> Function() _keyLoader;
  final DateTime Function() _now;
  Future<places.FlutterGooglePlacesSdk>? _initializing;

  static Future<String?> loadApiKey() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Use exactly the key packaged for the map tiles, including builds without Dart defines.
      return const MethodChannel(
        'vatsalya/maps',
      ).invokeMethod<String>('getApiKey');
    }
    return kGoogleMapsApiKey;
  }

  Future<places.FlutterGooglePlacesSdk> _client() async {
    if (_sdk != null) return _sdk!;
    return _initializing ??= () async {
      try {
        final key = (await _keyLoader())?.trim();
        if (key == null ||
            key.isEmpty ||
            key.contains('YOUR_GOOGLE_MAPS_API_KEY')) {
          throw const NearbyFailure(NearbyFailureKind.configuration);
        }
        return _sdk = places.FlutterGooglePlacesSdk(key);
      } catch (_) {
        _initializing = null;
        rethrow;
      }
    }();
  }

  final _cache = <String, ({DateTime expires, List<NearbyPlace> rows})>{};
  static const categories = {
    'School': 'school',
    'Hospital': 'hospital',
    'Park': 'park',
    'Restaurant': 'restaurant',
    'Mall': 'shopping_mall',
    'Pharmacy': 'pharmacy',
  };
  Future<List<NearbyPlace>> searchNearby(LatLng origin, String category) async {
    if (!origin.latitude.isFinite ||
        !origin.longitude.isFinite ||
        origin.latitude.abs() > 90 ||
        origin.longitude.abs() > 180) {
      throw ArgumentError('Invalid nearby search coordinates');
    }
    final type = categories[category];
    if (type == null) throw ArgumentError.value(category);
    final key =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}:$type';
    final now = _now();
    _cache.removeWhere((_, value) => !now.isBefore(value.expires));
    final cached = _cache[key];
    if (cached != null) return cached.rows;
    try {
      final sdk = await _client().timeout(const Duration(seconds: 15));
      final response = await sdk
          .searchNearby(
            locationRestriction: places.CircularBounds(
              center: places.LatLng(
                lat: origin.latitude,
                lng: origin.longitude,
              ),
              radius: 3000,
            ),
            includedTypes: [type],
            fields: [
              places.PlaceField.Id,
              places.PlaceField.DisplayName,
              places.PlaceField.FormattedAddress,
              places.PlaceField.Location,
              places.PlaceField.Rating,
            ],
          )
          .timeout(const Duration(seconds: 15));
      final rows = <NearbyPlace>[];
      for (final place in response.places) {
        final location = place.latLng;
        if (location != null &&
            location.lat.isFinite &&
            location.lng.isFinite &&
            location.lat.abs() <= 90 &&
            location.lng.abs() <= 180) {
          rows.add(
            NearbyPlace(
              place.id ?? '',
              place.displayName?.text ?? place.name ?? 'Place',
              place.address ?? '',
              LatLng(location.lat, location.lng),
              place.rating,
            ),
          );
        }
      }
      final result = List<NearbyPlace>.unmodifiable(rows);
      _cache[key] = (
        expires: _now().add(const Duration(minutes: 5)),
        rows: result,
      );
      return result;
    } catch (error) {
      if (kDebugMode) {
        final description = error is PlatformException
            ? '${error.code}: ${error.message ?? ""}'
            : error.runtimeType.toString();
        final sanitized = description.replaceAll(
          RegExp(r'AIza[\w-]+'),
          '<redacted-key>',
        );
        debugPrint(
          '[nearby] ${sanitized.substring(0, sanitized.length.clamp(0, 800))}',
        );
      }
      throw NearbyFailure.from(error);
    }
  }
}
