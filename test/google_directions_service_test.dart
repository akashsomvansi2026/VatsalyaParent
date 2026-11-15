import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vrajrani_tech_solution/features/family_map/services/directions_service.dart';

class DirectionsAdapter implements HttpClientAdapter {
  DirectionsAdapter(this.payload);
  final Map<String, dynamic> payload;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'Directions decodes polyline and aggregates legs and instructions',
    () async {
      final adapter = DirectionsAdapter({
        'status': 'OK',
        'routes': [
          {
            'overview_polyline': {'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@'},
            'copyrights': 'Google',
            'legs': [
              for (var i = 0; i < 2; i++)
                {
                  'distance': {'value': 1200},
                  'duration': {'value': 180},
                  'steps': [
                    {
                      'html_instructions': 'Turn <b>right</b> &amp; continue',
                      'distance': {'text': '1.2 km'},
                      'duration': {'text': '3 mins'},
                    },
                  ],
                },
            ],
          },
        ],
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final result = await DirectionsService(
        dio,
      ).route(const LatLng(1, 2), const LatLng(3, 4));
      expect(result.metres, 2400);
      expect(result.seconds, 360);
      expect(result.points.length, 3);
      expect(result.points.first.latitude, closeTo(38.5, .00001));
      expect(result.steps.first.instruction, 'Turn right & continue');
      expect(adapter.request!.queryParameters['origin'], '1.0,2.0');
      dio.close();
    },
  );
  for (final status in ['ZERO_RESULTS', 'REQUEST_DENIED']) {
    test('Directions reports $status without inventing an ETA', () async {
      final dio = Dio()
        ..httpClientAdapter = DirectionsAdapter({
          'status': status,
          'routes': [],
        });
      await expectLater(
        DirectionsService(dio).route(const LatLng(1, 2), const LatLng(3, 4)),
        throwsStateError,
      );
      dio.close();
    });
  }
}
