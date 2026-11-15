import 'package:vrajrani_tech_solution/presentation/router/app_router.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vrajrani_tech_solution/core/app_update/app_update.dart';
import 'package:vrajrani_tech_solution/core/app_update/app_update_manager.dart';
import 'package:vrajrani_tech_solution/data/remote/api_client.dart';

Map<String, dynamic> response({
  bool available = true,
  bool mandatory = false,
}) => {
  'success': true,
  'statusCode': 200,
  'data': {
    'platform': 'android',
    'updateAvailable': available,
    'mandatory': mandatory,
    'latestVersion': '2.0.0',
    'minimumVersion': '1.0.0',
    'downloadUrl': null,
    'releaseNotes': 'Improved family safety',
  },
};
PackageInfo info() => PackageInfo(
  appName: 'Vatsalya',
  packageName: 'com.vrajranitech.solution',
  version: '1.0.1',
  buildNumber: '2',
);
AppUpdate update({
  bool available = true,
  bool mandatory = false,
  String? url,
}) => AppUpdate(
  available: available,
  mandatory: mandatory,
  installed: '1.0.1',
  latest: '2.0.0',
  downloadUrl: url,
);
AppUpdateController controller(Future<AppUpdate> Function(String) fetch) =>
    AppUpdateController(
      fetch: fetch,
      packageInfo: () async => info(),
      launch: (_) async => true,
    );

void main() {
  testWidgets('Mandatory router guard blocks deep links and Android Back', (
    tester,
  ) async {
    final c = controller((_) async => update(mandatory: true));
    await c.check();
    final container = ProviderContainer(
      overrides: [appUpdateProvider.overrideWithValue(c)],
    );
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => AppUpdateManager(child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/features');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/app-update');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Update Now'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/app-update');
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    c.dispose();
  });
  testWidgets(
    'Lifecycle resumes obey cooldown; compact dark update has no overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final c = controller((_) async {
        calls++;
        return update(mandatory: true);
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appUpdateProvider.overrideWithValue(c)],
          child: MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!,
            ),
            home: AppUpdateManager(child: const Scaffold()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  test('Server flags decide latest, optional and mandatory', () {
    expect(
      AppUpdate.parse(response(available: false), '1.0.1').available,
      false,
    );
    expect(AppUpdate.parse(response(), '1.0.1').mandatory, false);
    expect(AppUpdate.parse(response(mandatory: true), '1.0.1').mandatory, true);
  });
  test('Invalid fields and JSON envelope are rejected', () {
    for (final json in <Map<String, dynamic>>[
      {},
      {'success': true},
      response()..['data'] = {'updateAvailable': 'yes'},
      response()..['success'] = false,
    ]) {
      expect(() => AppUpdate.parse(json, '1.0.1'), throwsFormatException);
    }
    expect(validAppVersion('1.2.3'), true);
    expect(validAppVersion('unknown'), false);
  });
  test('API sends installed version with no auth and finite timeout', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.uri.host, 'joinus.akashdreamer.uk');
          expect(options.queryParameters, {
            'platform': 'android',
            'version': '1.0.1',
          });
          expect(options.headers['Authorization'], isNull);
          expect(options.followRedirects, false);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: response(),
            ),
          );
        },
      ),
    );
    final api = ApiClient(
      dio: dio,
      tokenProvider: () async => 'private',
      onUnauthorized: () => fail('Public request must not log out'),
    );
    final result = await AppUpdateService(api).check('1.0.1');
    expect(result.installed, '1.0.1');
  });
  test('Missing URL only falls back when publication is configured', () {
    expect(updateDestination(update(), 'app'), isNull);
    expect(
      updateDestination(
        update(),
        'app',
        playPublished: true,
      )?.queryParameters['id'],
      'app',
    );
  });
  test(
    'Only exact trusted HTTPS hosts and correct Play listing are allowed',
    () {
      for (final url in [
        'http://joinus.akashdreamer.uk/a.apk',
        'https://evil.com/a',
        'https://joinus.akashdreamer.uk.evil.com/a',
        'https://user@joinus.akashdreamer.uk/a',
        'https://joinus.akashdreamer.uk:444/a',
        'https://play.google.com/store/apps/details?id=other',
      ]) {
        expect(updateDestination(update(url: url), 'app'), isNull);
      }
      expect(
        updateDestination(
          update(url: 'https://joinus.akashdreamer.uk/a.apk'),
          'app',
        ),
        isNotNull,
      );
    },
  );
  test(
    'Concurrent and repeated resume checks share one request; manual bypasses cooldown',
    () async {
      final pending = Completer<AppUpdate>();
      var calls = 0;
      final c = controller((version) {
        calls++;
        expect(version, '1.0.1');
        return pending.future;
      });
      final a = c.check();
      final b = c.check(returnedFromStore: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      pending.complete(update(available: false));
      await Future.wait([a, b]);
      await c.check();
      expect(calls, 1);
      await c.check(manual: true);
      expect(calls, 2);
      c.dispose();
    },
  );
  test(
    'Timeout fails open unless mandatory was previously confirmed',
    () async {
      var fail = false;
      final c = controller((_) async {
        if (fail) throw TimeoutException('offline');
        return update(mandatory: true);
      });
      await c.check();
      expect(c.blocked, true);
      fail = true;
      await c.check(manual: true);
      expect(c.blocked, true);
      expect(c.error, isNotNull);
      c.dispose();
      final fresh = controller((_) async => throw TimeoutException('offline'));
      await fresh.check();
      expect(fresh.blocked, false);
      expect(fresh.error, isNotNull);
      fresh.dispose();
    },
  );
  test(
    'Later defers optional version; mandatory cannot be deferred; success clears gate',
    () async {
      var result = update();
      final c = controller((_) async => result);
      await c.check();
      c.later();
      expect(c.visible, false);
      await c.check(manual: true);
      expect(c.visible, true);
      result = update(mandatory: true);
      await c.check(manual: true);
      c.later();
      expect(c.blocked, true);
      result = update(available: false);
      await c.check(manual: true);
      expect(c.visible, false);
      c.dispose();
    },
  );
  test('Missing destination and launch failure provide errors', () async {
    final c = controller((_) async => update());
    await c.check();
    await c.openUpdate();
    expect(c.error, contains('No trusted'));
    c.dispose();
    final broken = AppUpdateController(
      fetch: (_) async => update(url: 'https://joinus.akashdreamer.uk/a'),
      packageInfo: () async => info(),
      launch: (_) async => false,
    );
    await broken.check();
    await broken.openUpdate();
    expect(broken.error, contains('Could not open'));
    broken.dispose();
  });
  test('Disposal during a request is safe', () async {
    final pending = Completer<AppUpdate>();
    final c = controller((_) => pending.future);
    final work = c.check();
    await Future<void>.delayed(Duration.zero);
    c.dispose();
    pending.complete(update());
    await work;
  });
  for (final mandatory in [false, true]) {
    testWidgets(
      'Update surface optional=$mandatory stays single and responds to Later',
      (tester) async {
        final c = controller((_) async => update(mandatory: mandatory));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appUpdateProvider.overrideWithValue(c)],
            child: MaterialApp(
              home: AppUpdateManager(
                child: const Scaffold(body: Text('Existing feature')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Update Now'), findsOneWidget);
        await c.check(manual: true);
        await tester.pumpAndSettle();
        expect(find.text('Update Now'), findsOneWidget);
        expect(find.text('Later'), mandatory ? findsNothing : findsOneWidget);
        if (!mandatory) {
          await tester.tap(find.text('Later'));
          await tester.pumpAndSettle();
          expect(find.text('Update Now'), findsNothing);
        }
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }
  testWidgets('Current version shows no update surface', (tester) async {
    final c = controller((_) async => update(available: false));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appUpdateProvider.overrideWithValue(c)],
        child: MaterialApp(home: AppUpdateManager(child: const Text('Home'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update Now'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
