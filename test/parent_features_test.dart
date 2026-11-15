import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/core/config/app_config.dart';
import 'package:vrajrani_tech_solution/core/config/parent_features.dart';
import 'package:vrajrani_tech_solution/core/utils/load_section.dart';
import 'package:vrajrani_tech_solution/core/utils/pairing_payload.dart';
import 'package:vrajrani_tech_solution/data/models/parent_user.dart';
import 'package:vrajrani_tech_solution/data/models/child.dart';
import 'package:vrajrani_tech_solution/data/models/pairing_code.dart';
import 'package:vrajrani_tech_solution/data/remote/api_client.dart';
import 'package:vrajrani_tech_solution/data/remote/realtime_gateway.dart';
import 'package:vrajrani_tech_solution/data/repositories/parents_repository.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/workspace_widgets.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(Object value, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
void main() {
  test('Realtime uses websocket scheme and safely encodes JWT', () {
    final uri = AppConfig.realtimeUri('https://example.test:8080', 'a+b&c');
    expect(uri.scheme, 'wss');
    expect(uri.path, '/api/realtime');
    expect(
      uri.queryParameters['access_token'] ?? uri.queryParameters['token'],
      'a+b&c',
    );
    expect(AppConfig.realtimeUri('http://example.test', 'token').scheme, 'ws');
  });
  test(
    'Nested realtime frame exposes child data and tolerates invalid frames',
    () {
      final event = RealtimeEvent.fromMessage(
        '{"type":"location","data":{"childId":7,"latitude":12}}',
      )!;
      expect(event.childId, 7);
      expect(event.data['latitude'], 12);
      expect(RealtimeEvent.fromMessage('ping'), isNull);
    },
  );
  test(
    'Missing battery stays unknown',
    () => expect(Child.fromJson({'id': 1}).batteryLevel, isNull),
  );
  test(
    'Parent permissions are parsed dynamically and absent actions denied',
    () {
      final user = ParentUser.fromJson({
        'id': 1,
        'permissions': [
          {'key': 'parent.child.view'},
          {'module': 'parent.profile', 'action': 'view'},
        ],
      });
      expect(user.can('child.view'), isTrue);
      expect(user.can('profile.view'), isTrue);
      expect(user.can('child.delete'), isFalse);
      final approval = ParentFeature.all.firstWhere(
        (f) => f.key == 'app.approval',
      );
      expect(approval.can({'parent.app.approval.manage'}, 'view'), isTrue);
      expect(approval.can({'parent.app.approval.manage'}, 'create'), isFalse);
    },
  );
  test('Pairing includes dedicated identity token only for active code', () {
    final code = PairingCode.fromJson({
      'id': 1,
      'code': 'ABC234',
      'isActive': true,
      'accessToken': 'one-time',
      'childName': 'Riya',
      'childEmail': 'child@example.test',
      'parent': {'name': 'Parent'},
    });
    final json = jsonDecode(pairingPayload(code, 'http://192.168.1.10:5000'));
    expect(json['accessToken'], 'one-time');
    expect(json['child']['name'], 'Riya');
    expect(json['apiUrl'], 'http://192.168.1.10:5000');
    final revoked = PairingCode.fromJson({
      'id': 1,
      'code': 'ABC234',
      'isActive': false,
      'accessToken': 'one-time',
    });
    expect(
      jsonDecode(
        pairingPayload(revoked, 'https://example.test'),
      ).containsKey('accessToken'),
      isFalse,
    );
  });
  test('Pairing rejects inaccessible and credential-bearing addresses', () {
    for (final url in [
      'http://localhost:5000',
      'http://10.0.2.2:5000',
      'https://user:pass@example.test',
      'https://example.test/api',
    ]) {
      expect(() => validatePairingServer(url), throwsFormatException);
    }
  });
  test(
    'Denied sections make no request and failed section does not lose others',
    () async {
      var calls = 0;
      final warnings = <String>[];
      expect(
        await loadSection<int>(
          false,
          () async {
            calls++;
            return [1];
          },
          warnings,
          'Private',
        ),
        isEmpty,
      );
      expect(calls, 0);
      final result = await Future.wait([
        loadSection<int>(true, () async => [7], warnings, 'Children'),
        loadSection<int>(
          true,
          () async => throw Exception('offline'),
          warnings,
          'SOS',
        ),
      ]);
      expect(result.first, [7]);
      expect(result.last, isEmpty);
      expect(warnings, hasLength(1));
    },
  );
  test('SOS resolution accepts server empty confirmation object', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = Adapter((request) async {
        expect(request.method, 'POST');
        return body({'success': true, 'data': {}});
      });
    await ParentsRepository(
      apiClient: ApiClient(
        tokenProvider: () async => 'jwt',
        onUnauthorized: () {},
        dio: dio,
      ),
    ).resolveSos(3);
  });
  test('Old response cannot cross an account switch', () async {
    var revision = 0;
    final pending = Completer<ResponseBody>();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = Adapter((_) => pending.future);
    final api = ApiClient(
      tokenProvider: () async => 'jwt',
      onUnauthorized: () {},
      sessionRevision: () => revision,
      dio: dio,
    );
    final request = api.getList('/api/children');
    await Future<void>.delayed(Duration.zero);
    revision++;
    pending.complete(
      body([
        {'id': 7},
      ]),
    );
    await expectLater(request, throwsA(isA<Exception>()));
  });
  test('Old unauthorized response does not sign out the new account', () async {
    var revision = 0, logout = 0;
    final pending = Completer<ResponseBody>();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = Adapter((_) => pending.future);
    final api = ApiClient(
      tokenProvider: () async => 'jwt',
      onUnauthorized: () {
        logout++;
      },
      sessionRevision: () => revision,
      dio: dio,
    );
    final request = api.getObject('/admin/auth/me');
    await Future<void>.delayed(Duration.zero);
    revision++;
    pending.complete(body({'message': 'expired'}, 401));
    await expectLater(request, throwsA(isA<Exception>()));
    expect(logout, 0);
  });
  testWidgets(
    'Editor preserves password spaces and rejects invalid numeric input',
    (tester) async {
      Map<String, String>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await editValues(context, 'Edit', [
                  const EditorField('password', 'Password', secret: true),
                  EditorField(
                    'limit',
                    'Limit',
                    required: true,
                    validate: (v) => numberValidation(v, 0, 1440),
                  ),
                ]);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        ' abc123456789 ',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '1441');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      await tester.enterText(find.byType(TextFormField).at(1), '90');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(result!['password'], ' abc123456789 ');
      expect(result!['limit'], '90');
    },
  );
}
