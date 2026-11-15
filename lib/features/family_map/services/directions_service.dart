import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/api_keys.dart';

final directionsServiceProvider = Provider((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return DirectionsService(dio);
});

class RouteStep {
  const RouteStep(this.instruction, this.distance, this.duration);
  final String instruction, distance, duration;
}

class RouteResult {
  const RouteResult(
    this.points,
    this.metres,
    this.seconds,
    this.steps,
    this.copyright,
  );
  final List<LatLng> points;
  final double metres, seconds;
  final List<RouteStep> steps;
  final String copyright;
}

class DirectionsService {
  DirectionsService(this.dio);
  final Dio dio;
  Future<RouteResult> route(LatLng origin, LatLng destination) async {
    const proxy = String.fromEnvironment('GOOGLE_DIRECTIONS_PROXY_URL');
    final response = await dio.get<Map<String, dynamic>>(
      proxy.isEmpty
          ? 'https://maps.googleapis.com/maps/api/directions/json'
          : proxy,
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        if (proxy.isEmpty) 'key': kGoogleMapsApiKey,
      },
    );
    final data = response.data!;
    if (data['status'] != 'OK') {
      throw StateError('Directions unavailable: ${data['status']}');
    }
    final route = (data['routes'] as List).first as Map;
    final legs = route['legs'] as List;
    final points = PolylinePoints.decodePolyline(
      (route['overview_polyline'] as Map)['points'] as String,
    ).map((p) => LatLng(p.latitude, p.longitude)).toList();
    double metres = 0, seconds = 0;
    final steps = <RouteStep>[];
    for (final leg in legs) {
      metres += (leg['distance']['value'] as num).toDouble();
      seconds += (leg['duration']['value'] as num).toDouble();
      for (final step in leg['steps']) {
        final text = (step['html_instructions'] as String)
            .replaceAll(RegExp('<[^>]*>'), ' ')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        steps.add(
          RouteStep(
            text,
            step['distance']['text'] as String,
            step['duration']['text'] as String,
          ),
        );
      }
    }
    return RouteResult(
      points,
      metres,
      seconds,
      steps,
      route['copyrights'] as String? ?? 'Google',
    );
  }
}
