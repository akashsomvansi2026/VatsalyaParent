import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/presentation/providers/infra_providers.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/family_management_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/widgets/family_management_widgets.dart';
import 'parent_screens_test.dart' show FakeWorkspace, FixedSession;

class FamilyReferenceRepository extends FakeWorkspace {
  bool empty = true, fail = false;
  @override
  Future<List<Map<String, dynamic>>> list(String path) async {
    if (fail) throw Exception('Test refresh unavailable');
    if (empty) {
      calls.add(path);
      return [];
    }
    return super.list(path);
  }
}

const grants = {
  'parent.child.view',
  'parent.child.create',
  'parent.child.update',
  'parent.device.view',
  'parent.device.add',
  'parent.device.rename',
};

void main() {
  for (final scenario in [
    (size: Size(390, 1000), scale: 1.0),
    (size: Size(320, 568), scale: 3.0),
    (size: Size(844, 390), scale: 2.0),
    (size: Size(1280, 800), scale: 1.0),
  ]) {
    for (final devices in [false, true]) {
      testWidgets(
        'Family management devices=$devices ${scenario.size} ${scenario.scale}x retains search and refresh',
        (tester) async {
          tester.view.physicalSize = scenario.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          if (const bool.fromEnvironment('CAPTURE_FAMILY_MANAGEMENT')) {
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
          final repo = FamilyReferenceRepository();
          final boundary = GlobalKey();
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => RepaintBoundary(
                  key: boundary,
                  child: FamilyManagementScreen(devices: devices),
                ),
              ),
              GoRoute(
                path: '/child/:id',
                builder: (_, state) => Scaffold(
                  body: Text('Supervision ${state.pathParameters['id']}'),
                ),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionProvider.overrideWith(() => FixedSession(grants)),
                workspaceRepositoryProvider.overrideWithValue(repo),
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
          if (const bool.fromEnvironment('CAPTURE_FAMILY_MANAGEMENT')) {
            await tester.runAsync(
              () => precacheImage(
                const AssetImage('assets/illustrations/family_portrait.png'),
                boundary.currentContext!,
              ),
            );
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text(devices ? 'No Devices Found' : 'No Children Found'),
            findsOneWidget,
          );
          expect(find.byType(FloatingActionButton), findsOneWidget);
          if (!devices &&
              scenario.size.width == 390 &&
              const bool.fromEnvironment('CAPTURE_FAMILY_MANAGEMENT')) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(
                'verification/family-management',
              ).create(recursive: true);
              await File(
                'verification/family-management/children-preview.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          repo.empty = false;
          await tester.tap(find.byTooltip('Refresh'));
          await tester.pumpAndSettle();
          final title = devices ? 'Riya phone' : 'Riya';
          expect(find.text(title), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byType(TextField));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'not-matching');
          await tester.pumpAndSettle();
          expect(
            find.text('No matching ${devices ? 'devices' : 'children'}'),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Clear search'));
          await tester.pumpAndSettle();
          expect(find.text(title), findsOneWidget);
          expect(tester.takeException(), isNull);
          repo.fail = true;
          await tester.tap(find.byTooltip('Refresh'));
          await tester.pumpAndSettle();
          expect(find.text('Unable to load information'), findsOneWidget);
          expect(
            find.text(devices ? 'No Devices Found' : 'No Children Found'),
            findsNothing,
          );
          repo.fail = false;
          await tester.tap(find.byTooltip('Refresh'));
          await tester.pumpAndSettle();
          expect(find.text(title), findsOneWidget);
          if (!devices) {
            await tester.ensureVisible(find.text(title));
            await tester.pumpAndSettle();
            await tester.tap(find.text(title));
            await tester.pumpAndSettle();
            expect(find.text('Supervision 7'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets('Read-only family empty state hides creation controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            () => FixedSession({'parent.child.view'}),
          ),
          workspaceRepositoryProvider.overrideWithValue(
            FamilyReferenceRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const FamilyManagementScreen(devices: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(FamilyAddButton), findsNothing);
    expect(find.text('No Children Found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
