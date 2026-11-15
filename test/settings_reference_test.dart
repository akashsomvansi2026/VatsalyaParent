import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/core/app_update/app_update.dart';
import 'package:vrajrani_tech_solution/data/models/parent_user.dart';
import 'package:vrajrani_tech_solution/data/remote/parent_push_service.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/providers/infra_providers.dart';
import 'package:vrajrani_tech_solution/presentation/screens/settings/settings_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/shell/home_shell.dart';
import 'parent_screens_test.dart' show FakeWorkspace;

class SettingsSession extends SessionNotifier {
  int reloads = 0, logouts = 0;
  @override
  SessionState build() => SessionState.authenticated(
    const ParentUser(
      id: 1,
      name: 'Aman Singh',
      email: 'aman.long.parent.account@example.test',
    ),
  );
  @override
  Future<void> reloadAccount() async {
    reloads++;
  }

  @override
  Future<void> logout() async {
    logouts++;
  }
}

class SettingsPush extends ParentPushService {
  SettingsPush() : super(FakeWorkspace());
  int enables = 0, disables = 0;
  @override
  Future<void> enable({bool requestPermission = true}) async {
    enables++;
    active = true;
    status = 'Notifications enabled for this account.';
  }

  @override
  Future<void> disable() async {
    disables++;
    active = false;
    status = 'Notifications are not enabled.';
  }
}

PackageInfo installedInfo() => PackageInfo(
  appName: 'Vatsalya Guard',
  packageName: 'com.vrajranitech.solution',
  version: '7.3.2',
  buildNumber: '42',
);

void main() {
  for (final scenario in [
    (size: Size(390, 1050), scale: 1.0),
    (size: Size(320, 568), scale: 3.0),
    (size: Size(844, 390), scale: 2.0),
    (size: Size(1280, 800), scale: 1.0),
  ]) {
    testWidgets(
      'Settings ${scenario.size} ${scenario.scale}x keeps real actions',
      (tester) async {
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        if (const bool.fromEnvironment('CAPTURE_SETTINGS')) {
          await tester.runAsync(() async {
            final font = FontLoader('Roboto')
              ..addFont(
                File(
                  '${Platform.environment['WINDIR']}/Fonts/arial.ttf',
                ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
              );
            await font.load();
            final icons = FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
          });
        }
        final session = SettingsSession();
        final push = SettingsPush();
        var checks = 0;
        final updates = AppUpdateController(
          fetch: (version) async {
            checks++;
            return AppUpdate(
              available: false,
              mandatory: false,
              installed: version,
              latest: version,
            );
          },
          packageInfo: () async => installedInfo(),
          launch: (_) async => false,
        );
        addTearDown(updates.dispose);
        final boundary = GlobalKey();
        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            ShellRoute(
              builder: (_, _, child) => HomeShell(child: child),
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (_, _) => RepaintBoundary(
                    key: boundary,
                    child: const SettingsScreen(),
                  ),
                ),
              ],
            ),
            for (final path in ['/features', '/account', '/privacy'])
              GoRoute(
                path: path,
                builder: (_, _) => Scaffold(body: Text('Destination $path')),
              ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionProvider.overrideWith(() => session),
              parentPushProvider.overrideWithValue(push),
              appUpdateProvider.overrideWithValue(updates),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scenario.scale),
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                ),
                child: child!,
              ),
            ),
          ),
        );
        if (const bool.fromEnvironment('CAPTURE_SETTINGS')) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage('assets/illustrations/settings_shield.png'),
              boundary.currentContext!,
            ),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Aman Singh'), findsOneWidget);
        expect(find.text('Version 7.3.2'), findsOneWidget);
        if (scenario.size.width == 390 &&
            const bool.fromEnvironment('CAPTURE_SETTINGS')) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('verification/settings').create(recursive: true);
            await File(
              'verification/settings/settings-preview.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        Future<void> dismissFeedback() async {
          tester
              .state<ScaffoldMessengerState>(
                find.byType(ScaffoldMessenger).first,
              )
              .hideCurrentSnackBar();
          await tester.pumpAndSettle();
        }

        Future<void> tapText(String text) async {
          await tester.ensureVisible(find.text(text));
          await tester.pumpAndSettle();
          await tester.tap(find.text(text));
          await tester.pumpAndSettle();
          await dismissFeedback();
        }

        await tapText('Check for Updates');
        expect(checks, 1);
        await tester.ensureVisible(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(push.enables, 1);
        expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
        await dismissFeedback();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(push.disables, 1);
        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
        await dismissFeedback();
        await tapText('Refresh account permissions');
        expect(session.reloads, 1);
        await tapText('Sign out');
        await tapText('Cancel');
        expect(session.logouts, 0);
        await tapText('Sign out');
        await tapText('Confirm');
        expect(session.logouts, 1);
        await tapText('App information');
        expect(find.text('7.3.2 (42)'), findsOneWidget);
        Navigator.of(tester.element(find.byType(AboutDialog))).pop();
        await tester.pumpAndSettle();
        await tapText('Privacy Policy');
        expect(find.text('Destination /privacy'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        await tapText('Aman Singh');
        expect(find.text('Destination /account'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        await tapText('All Parent features');
        expect(find.text('Destination /features'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  test(
    'Notification opt-out persists and prevents automatic restore',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'vg_parent_push_opt_in': 'true',
      });
      final service = ParentPushService(FakeWorkspace())..active = true;
      await service.disable();
      expect(await service.storage.read(key: 'vg_parent_push_opt_in'), 'false');
      expect(service.active, isFalse);
      await service.restore();
      expect(service.ready, isFalse);
      service.dispose();
    },
  );
}
