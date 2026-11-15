import 'package:flutter/services.dart';

import '../../data/models/location_point.dart';

class NearbyAddress {
  const NearbyAddress({
    this.street,
    this.area,
    this.city,
    this.state,
    this.postalCode,
  });

  final String? street, area, city, state, postalCode;

  String get shortLabel {
    final place = [area, city].where((part) => part?.isNotEmpty == true).toList();
    if (place.isNotEmpty) return 'Near ${place.join(', ')}';
    if (street?.isNotEmpty == true) return 'Near $street';
    if (state?.isNotEmpty == true) return 'Near $state';
    return 'Address unavailable';
  }

  String? get details {
    final parts = [street, area, city, state, postalCode]
        .where((part) => part?.isNotEmpty == true)
        .toSet()
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  factory NearbyAddress.fromMap(Map<Object?, Object?> value) => NearbyAddress(
        street: value['street'] as String?,
        area: value['area'] as String?,
        city: value['city'] as String?,
        state: value['state'] as String?,
        postalCode: value['postalCode'] as String?,
      );
}

/// Uses device geocoding only. Failed lookups are never shown as an exact
/// address. The short memory cache avoids a lookup on every rebuild.
class NearbyAddressService {
  NearbyAddressService._();
  static const _channel = MethodChannel('vatsalya/location');
  static final _cache = <String, Future<NearbyAddress?>>{};

  static Future<NearbyAddress?> resolve(LocationPoint point) {
    final key = '${point.latitude.toStringAsFixed(4)},${point.longitude.toStringAsFixed(4)}';
    return _cache.putIfAbsent(key, () async {
      try {
        final result = await _channel.invokeMapMethod<Object?, Object?>(
          'reverseGeocode',
          {'latitude': point.latitude, 'longitude': point.longitude},
        ).timeout(const Duration(seconds: 8));
        return result == null ? null : NearbyAddress.fromMap(result);
      } catch (_) {
        // Cache an unavailable result for this coordinate. Retrying on every
        // FutureBuilder rebuild would create a request/render loop.
        return null;
      }
    });
  }

  static Future<bool> openInMaps(LocationPoint point) async {
    try {
      return await _channel.invokeMethod<bool>('openInMaps', {
            'latitude': point.latitude,
            'longitude': point.longitude,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
