import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/features_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/widgets/feature_hub_widgets.dart';
import 'package:vrajrani_tech_solution/presentation/screens/shell/home_shell.dart';
import 'parent_screens_test.dart' show FixedSession;

const grants = {
  'parent.child.view',
  'parent.device.view',
  'parent.device.add',
  'parent.location.view',
  'parent.control.view',
  'parent.sos.view',
  'parent.report.export',
};

void main() {
  for (final scenario in [
    (size: Size(390, 1100), scale: 1.0),
    (size: Size(320, 568), scale: 3.0),
    (size: Size(844, 390), scale: 2.0),
    (size: Size(1280, 800), scale: 1.0),
  ]) {
    testWidgets(
      'Features reference ${scenario.size} ${scenario.scale}x preserves granted routes',
      (tester) async {
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        if (const bool.fromEnvironment('CAPTURE_FEATURES')) {
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
        final boundary = GlobalKey();
        final destinations = [
          '/family/children',
          '/family/devices',
          '/pairing',
          '/family-map',
          '/sos',
          '/records/report',
          '/records/control',
        ];
        final router = GoRouter(
          initialLocation: '/features',
          routes: [
            ShellRoute(
              builder: (_, _, child) => HomeShell(child: child),
              routes: [
                GoRoute(
                  path: '/features',
                  builder: (_, _) => RepaintBoundary(
                    key: boundary,
                    child: const FeaturesScreen(),
                  ),
                ),
              ],
            ),
            for (final path in destinations)
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
              sessionProvider.overrideWith(() => FixedSession(grants)),
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
        if (const bool.fromEnvironment('CAPTURE_FEATURES')) {
          await tester.runAsync(() async {
            for (final path in [
              'family_portrait',
              'dashboard_child',
              'features_artwork',
            ]) {
              await precacheImage(
                AssetImage('assets/illustrations/$path.png'),
                boundary.currentContext!,
              );
            }
          });
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Care starts here'), findsOneWidget);
        expect(find.text('Payment requests'), findsNothing);
        expect(find.text('Reports & export'), findsOneWidget);
        if (scenario.scale == 1 &&
            scenario.size.width == 390 &&
            const bool.fromEnvironment('CAPTURE_FEATURES')) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('verification/features').create(recursive: true);
            await File(
              'verification/features/features-preview.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        final cards = tester
            .widgetList<FeatureHubCard>(find.byType(FeatureHubCard))
            .map((card) => card.item)
            .toList();
        for (final item in cards) {
          await tester.ensureVisible(find.text(item.title));
          await tester.pumpAndSettle();
          await tester.tap(find.text(item.title));
          await tester.pumpAndSettle();
          expect(find.text('Destination ${item.path}'), findsOneWidget);
          router.pop();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('No grants keeps every feature hidden', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => FixedSession({}))],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const FeaturesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FeatureHubCard), findsNothing);
    expect(
      find.textContaining('No Parent features are assigned'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
