import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/family_management_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/pairing_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/pairing_setup_form.dart';
import 'parent_screens_test.dart' show FakeWorkspace, mount;

class FamilyWorkspace extends FakeWorkspace {
  final writes = <Map<String, dynamic>>[];
  int available = 2;
  bool failPairing = false;
  @override
  Future<Map<String, dynamic>> get(String path) async {
    calls.add(path);
    if (path.endsWith('enrollment-tokens')) {
      return {'availableTokens': available, 'usedTokens': 1, 'totalTokens': 3};
    }
    if (path.endsWith('pairing-config')) {
      return {'apiUrl': 'https://example.test'};
    }
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> list(String path) async {
    if (path.endsWith('pairing-codes')) return [];
    return super.list(path);
  }

  @override
  Future<Map<String, dynamic>> save(
    String path,
    Map<String, dynamic> data, {
    String method = 'POST',
  }) async {
    writes.add({'path': path, 'method': method, ...data});
    if (path.endsWith('pairing-codes') && failPairing) {
      failPairing = false;
      throw Exception('Temporary pairing failure');
    }
    if (path == '/api/children') return {'id': 8, 'name': data['name']};
    return {
      'id': 9,
      'code': 'ABC234',
      'isActive': true,
      'isUsed': false,
      'createdAtUtc': '2026-10-06T10:00:00Z',
      'expiresAtUtc': '2099-01-01T00:00:00Z',
      'childName': data['childName'],
      'childEmail': data['childEmail'],
      'parent': {'id': 1, 'name': 'Parent'},
      'accessToken': 'one-time-test-token',
    };
  }
}

const permissions = {
  'parent.child.view',
  'parent.child.create',
  'parent.device.add',
  'parent.device.assign',
};
void main() {
  testWidgets(
    'Create child downloads first, uses authenticated ownership and shows pairing QR',
    (tester) async {
      final repo = FamilyWorkspace();
      await mount(
        tester,
        const FamilyManagementScreen(devices: false),
        permissions,
        repo,
        GlobalKey(),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(repo.writes, isEmpty);
      expect(find.text('1. Install Child app'), findsOneWidget);
      await tester.tap(find.text('Installed / Already installed — Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Child email *'),
        'aarav@example.test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name *'),
        'Aarav',
      );
      await tester.tap(find.text('Save & generate pairing QR'));
      await tester.pumpAndSettle();
      expect(repo.writes.first['path'], '/api/children');
      expect(repo.writes.first['name'], 'Aarav');
      expect(repo.writes.first.containsKey('parentUserId'), isFalse);
      expect(repo.writes.length, 2);
      expect(repo.writes.last['childId'], 8);
      expect(repo.writes.last['childEmail'], 'aarav@example.test');
      expect(repo.writes.first.containsKey('childEmail'), isFalse);
      expect(find.text('ABC234'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Pairing QR retry preserves the saved child without duplicate creation',
    (tester) async {
      final repo = FamilyWorkspace()..failPairing = true;
      await mount(
        tester,
        const FamilyManagementScreen(devices: false),
        permissions,
        repo,
        GlobalKey(),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Installed / Already installed — Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name *'),
        'Aarav',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Child email *'),
        'aarav@example.test',
      );
      await tester.tap(find.text('Save & generate pairing QR'));
      await tester.pumpAndSettle();
      expect(find.text('Child saved'), findsOneWidget);
      await tester.tap(find.text('Retry pairing QR'));
      await tester.pumpAndSettle();
      expect(
        repo.writes.where((write) => write['path'] == '/api/children').length,
        1,
      );
      expect(repo.writes.last['childId'], 8);
      expect(find.text('ABC234'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Pairing preselects child and uses Parent-scoped API', (
    tester,
  ) async {
    final repo = FamilyWorkspace();
    await mount(
      tester,
      const PairingScreen(initialChildId: 7),
      permissions,
      repo,
      GlobalKey(),
    );
    expect(repo.calls, contains('/api/parents/1/enrollment-tokens'));
    await tester.tap(
      find.widgetWithText(FilledButton, 'Generate pairing code'),
    );
    await tester.pumpAndSettle();
    expect(repo.writes, isEmpty);
    await tester.tap(find.text('Installed / Already installed — Continue'));
    await tester.pumpAndSettle();
    final name = find.widgetWithText(TextFormField, 'Child name');
    expect(tester.widget<TextFormField>(name).controller!.text, 'Riya');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Child email'),
      'riya@example.test',
    );
    await tester.tap(find.text('Generate code'));
    await tester.pumpAndSettle();
    expect(repo.writes.single['childId'], 7);
    expect(repo.writes.single['path'], '/api/parent/pairing-codes');
    expect(repo.writes.single.containsKey('parentUserId'), isFalse);
    expect(find.byType(PairingSetupForm), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('No allocation disables code generation', (tester) async {
    final repo = FamilyWorkspace()..available = 0;
    await mount(tester, const PairingScreen(), permissions, repo, GlobalKey());
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Generate pairing code'),
          )
          .onPressed,
      isNull,
    );
    expect(repo.writes, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Read-only pairing account cannot generate codes', (
    tester,
  ) async {
    await mount(
      tester,
      const PairingScreen(),
      {'parent.device.add'},
      FamilyWorkspace(),
      GlobalKey(),
    );
    expect(
      find.widgetWithText(FilledButton, 'Generate pairing code'),
      findsNothing,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
