import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/data/models/parent_user.dart';
import 'package:vrajrani_tech_solution/presentation/providers/dashboard_provider.dart';
import 'package:vrajrani_tech_solution/presentation/providers/infra_providers.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/screens/dashboard/dashboard_screen.dart';

class DashboardSession extends SessionNotifier {
  @override
  SessionState build() => SessionState.authenticated(
    const ParentUser(
      id: 1,
      name: 'Aman Singh',
      email: 'parent@example.test',
      permissions: {
        'parent.child.view',
        'parent.child.create',
        'parent.device.add',
        'parent.sos.view',
        'parent.location.view',
      },
    ),
  );
}

class ReadyDashboard extends DashboardNotifier {
  int refreshCalls = 0;
  @override
  DashboardState build() => const DashboardState(data: DashboardData());
  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Dashboard reference fits text scale $scale and preserves pairing navigation',
      (tester) async {
        tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final captureKey = GlobalKey();
        final notifier = ReadyDashboard();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => MediaQuery(
                data: MediaQueryData(
                  size: Size(scale == 1 ? 390 : 320, 1000),
                  textScaler: TextScaler.linear(scale),
                ),
                child: RepaintBoundary(
                  key: captureKey,
                  child: const DashboardScreen(),
                ),
              ),
            ),
            GoRoute(
              path: '/pairing',
              builder: (_, _) =>
                  const Scaffold(body: Text('Existing pairing route')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionProvider.overrideWith(DashboardSession.new),
              dashboardProvider.overrideWith(() => notifier),
              realtimeStreamProvider.overrideWith(
                (ref) => const Stream.empty(),
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: router,
            ),
          ),
        );
        if (const bool.fromEnvironment('CAPTURE_DASHBOARD')) {
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
            await precacheImage(
              const AssetImage('assets/illustrations/family_portrait.png'),
              captureKey.currentContext!,
            );
            await precacheImage(
              const AssetImage('assets/illustrations/dashboard_child.png'),
              captureKey.currentContext!,
            );
          });
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Hello, Aman Singh'), findsOneWidget);
        expect(find.text('No active SOS alerts'), findsOneWidget);
        await tester.tap(find.byTooltip('Refresh'));
        expect(notifier.refreshCalls, 1);
        if (scale == 1 && const bool.fromEnvironment('CAPTURE_DASHBOARD')) {
          await tester.runAsync(() async {
            final render =
                captureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final capture = await render.toImage(pixelRatio: 2);
            final bytes = await capture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('verification/dashboard').create(recursive: true);
            await File(
              'verification/dashboard/dashboard-preview.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            capture.dispose();
          });
        }
        await tester.scrollUntilVisible(find.text('Manage pairing codes'), 250);
        await tester.ensureVisible(find.text('Manage pairing codes'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Manage pairing codes'));
        await tester.pumpAndSettle();
        expect(find.text('Existing pairing route'), findsOneWidget);
      },
    );
  }
}
