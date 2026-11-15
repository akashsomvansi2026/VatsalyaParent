import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vrajrani_tech_solution/presentation/screens/dashboard/widgets/pairing_qr_sheet.dart';
import 'package:vrajrani_tech_solution/data/models/pairing_code.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/data/models/parent_user.dart';
import 'package:vrajrani_tech_solution/data/remote/api_client.dart';
import 'package:vrajrani_tech_solution/data/repositories/workspace_repository.dart';
import 'package:vrajrani_tech_solution/presentation/providers/infra_providers.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/features_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/records_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/family_management_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/recovery_screen.dart';

class FixedSession extends SessionNotifier {
  FixedSession(this.permissions);
  final Set<String> permissions;
  @override
  SessionState build() => SessionState.authenticated(
    ParentUser(
      id: 1,
      name: 'Parent',
      email: 'parent@example.test',
      permissions: permissions,
    ),
  );
}

class FakeWorkspace extends WorkspaceRepository {
  FakeWorkspace()
    : super(ApiClient(tokenProvider: () async => null, onUnauthorized: () {}));
  final calls = <String>[];
  @override
  Future<List<Map<String, dynamic>>> list(String path) async {
    calls.add(path);
    if (path == '/api/children') {
      return [
        {'id': 7, 'name': 'Riya', 'birthDate': '2015-03-12', 'isActive': true},
      ];
    }
    if (path == '/api/devices') {
      return [
        {
          'id': 1,
          'name': 'Riya phone',
          'platform': 'Android',
          'identifier': 'test-device',
          'childId': 7,
        },
      ];
    }
    return [
      {
        'id': 1,
        'name': 'Homework time',
        'status': 'Active',
        'childId': 7,
        'data': {'dailyMinutes': 90, 'notes': 'After school'},
      },
    ];
  }
}

Future<void> mount(
  WidgetTester tester,
  Widget page,
  Set<String> permissions,
  FakeWorkspace repo,
  GlobalKey boundary,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => FixedSession(permissions)),
        workspaceRepositoryProvider.overrideWithValue(repo),
      ],
      child: RepaintBoundary(
        key: boundary,
        child: MaterialApp(theme: AppTheme.light(), home: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> screenshot(GlobalKey key, String name) async {
  if (Platform.environment['PARENT_UI_CAPTURE'] != 'true') return;
  final image =
      await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
          .toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final directory = Directory('verification');
  directory.createSync();
  File(
    '${directory.path}/$name.png',
  ).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  setUpAll(() async {
    final fontDirectory = Platform.environment['PARENT_UI_FONT_DIR'];
    if (fontDirectory == null) return;
    for (final font in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('$fontDirectory/${font.value}').readAsBytesSync(),
            ),
          ),
        );
      await loader.load();
    }
  });
  testWidgets('Feature hub hides ungranted modules on a phone width', (
    tester,
  ) async {
    final key = GlobalKey();
    await mount(
      tester,
      const FeaturesScreen(),
      {
        'parent.child.view',
        'parent.device.view',
        'parent.device.add',
        'parent.location.view',
        'parent.screen_time.view',
        'parent.report.view',
      },
      FakeWorkspace(),
      key,
    );
    expect(find.text('Children & profiles'), findsOneWidget);
    expect(find.text('Payment requests'), findsNothing);
    expect(find.text('Family map & distance'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => screenshot(key, 'feature-hub'));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Children list loads and profile editor fits a phone', (
    tester,
  ) async {
    final key = GlobalKey();
    final repo = FakeWorkspace();
    await mount(
      tester,
      const FamilyManagementScreen(devices: false),
      {
        'parent.child.view',
        'parent.child.create',
        'parent.child.update',
        'parent.child.profile.view',
      },
      repo,
      key,
    );
    expect(find.text('Riya'), findsOneWidget);
    await tester.runAsync(() => screenshot(key, 'children'));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('1. Install Child app'), findsOneWidget);
    await tester.tap(find.text('Installed / Already installed — Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Birth date (YYYY-MM-DD)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => screenshot(key, 'child-editor'));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Readonly records hide mutations; allowed create opens validated form',
    (tester) async {
      final key = GlobalKey();
      await mount(
        tester,
        const RecordsScreen(module: 'screen_time'),
        {
          'parent.screen_time.view',
          'parent.screen_time.create',
          'parent.child.view',
        },
        FakeWorkspace(),
        key,
      );
      expect(find.text('Homework time'), findsOneWidget);
      await tester.runAsync(() => screenshot(key, 'screen-time'));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('daily minutes'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => screenshot(key, 'plan-editor'));
      await tester.pumpWidget(const SizedBox());
      await mount(
        tester,
        const RecordsScreen(module: 'payment'),
        {'parent.payment.view'},
        FakeWorkspace(),
        GlobalKey(),
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Recovery switches to password form without requiring a session',
    (tester) async {
      final key = GlobalKey();
      await mount(
        tester,
        RecoveryScreen(initialMode: 'reset-password', initialToken: 'a' * 64),
        {},
        FakeWorkspace(),
        key,
      );
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => screenshot(key, 'recovery'));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Pairing QR sheet scrolls on a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPairingQrSheet(
                context,
                PairingCode(
                  id: 1,
                  code: 'ABC234',
                  isActive: true,
                  isUsed: false,
                  createdAtUtc: DateTime.utc(2026),
                  apiUrl: 'https://example.test',
                  childName: 'Riya',
                  accessToken: 'one-time',
                ),
              ),
              child: const Text('Open QR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();
    expect(find.text('Share pairing QR'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
