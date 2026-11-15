import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/features/family_map/family_map_screen.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/family_map_app_bar.dart';
import 'package:vrajrani_tech_solution/presentation/providers/dashboard_provider.dart';
import 'package:vrajrani_tech_solution/presentation/providers/infra_providers.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/shell/home_shell.dart';
import 'dashboard_reference_test.dart' show ReadyDashboard, DashboardSession;
import 'main_screen_flow_test.dart' show MapChildren;
import 'family_map_realtime_test.dart' show TestSnapshotCache;

void main() {
  for (final scenario in [
    (size: Size(320, 568), scale: 1.0),
    (size: Size(320, 568), scale: 3.0),
    (size: Size(390, 844), scale: 1.3),
    (size: Size(844, 390), scale: 2.0),
    (size: Size(768, 1024), scale: 2.0),
    (size: Size(1280, 800), scale: 1.0),
  ]) {
    testWidgets(
      'Both screens fit ${scenario.size} at ${scenario.scale}x and navigate',
      (tester) async {
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = GoRouter(
          routes: [
            ShellRoute(
              builder: (_, _, child) => HomeShell(child: child),
              routes: [
                GoRoute(path: '/', builder: (_, _) => const FamilyMapScreen()),
                GoRoute(
                  path: '/dashboard',
                  builder: (_, _) => const DashboardScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/pairing',
              builder: (_, _) =>
                  const Scaffold(body: Text('Pairing destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionProvider.overrideWith(DashboardSession.new),
              dashboardProvider.overrideWith(ReadyDashboard.new),
              parentsRepositoryProvider.overrideWithValue(MapChildren()),
              childrenSnapshotCacheProvider.overrideWithValue(
                TestSnapshotCache(),
              ),
              realtimeStreamProvider.overrideWith(
                (ref) => const Stream.empty(),
              ),
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
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Family Map header, controls and navigation',
        );
        final toolbar = tester.getRect(find.byType(FamilyMapAppBar));
        final pill = tester.getRect(find.text('Family Location'));
        expect(pill.top, greaterThanOrEqualTo(toolbar.bottom));
        await tester.scrollUntilVisible(
          find.text('Find child'),
          220,
          scrollable: find
              .descendant(
                of: find.byType(FamilyMapScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(find.text('Find child'));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Family Map lower content',
        );
        await tester.tap(find.byIcon(Icons.dashboard_outlined));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/dashboard');
        await tester.scrollUntilVisible(
          find.text('Hello, Aman Singh'),
          220,
          scrollable: find
              .descendant(
                of: find.byType(DashboardScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Hello, Aman Singh'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Dashboard header and greeting',
        );
        await tester.scrollUntilVisible(
          find.text('Manage pairing codes'),
          260,
          scrollable: find
              .descendant(
                of: find.byType(DashboardScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(find.text('Manage pairing codes'));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Dashboard metrics and pairing',
        );
        await tester.tap(find.text('Manage pairing codes'));
        await tester.pumpAndSettle();
        expect(find.text('Pairing destination'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
