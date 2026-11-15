import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/device_safety_screen.dart';
import 'parent_screens_test.dart' show FakeWorkspace, mount;

class SafetyWorkspace extends FakeWorkspace {
  final saves = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> get(String path) async => {
    'policyRevision': 'pending-command',
    'requests': [
      {
        'id': 17,
        'deviceId': 2,
        'status': 'Pending',
        'requestedAtUtc': '2026-10-03T10:00:00Z',
        'data': {
          'action': 'location_off',
          'childName': 'Riya',
          'reason': 'Battery saving',
        },
      },
    ],
    'reports': [
      {
        'deviceId': 2,
        'reportedAtUtc': '2026-10-03T09:59:00Z',
        'data': {
          'deviceOwner': false,
          'locationEnabled': false,
          'locationGuardApplied': false,
          'airplaneModeEnabled': false,
          'airplaneGuardApplied': false,
          'shutdownGuardApplied': false,
          'policyRevision': 'old-command',
        },
      },
    ],
  };
  @override
  Future<Map<String, dynamic>> save(
    String path,
    Map<String, dynamic> data, {
    String method = 'POST',
  }) async {
    saves.add({'path': path, ...data});
    return {};
  }
}

void main() {
  testWidgets('Read-only Parent sees reports without approval controls', (
    tester,
  ) async {
    await mount(
      tester,
      const DeviceSafetyScreen(childId: 7),
      {'parent.control.view'},
      SafetyWorkspace(),
      GlobalKey(),
    );
    expect(find.text('Enable & protect location'), findsNothing);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Hardware shutdown guard: unavailable'), findsOneWidget);
    expect(
      find.text('Latest Parent command is awaiting device acknowledgement.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Parent approves fifteen minutes only after confirmation', (
    tester,
  ) async {
    final repo = SafetyWorkspace();
    await mount(
      tester,
      const DeviceSafetyScreen(childId: 7),
      {'parent.control.view', 'parent.control.update'},
      repo,
      GlobalKey(),
    );
    await tester.scrollUntilVisible(find.text('Approve'), 200);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(repo.saves, isEmpty);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(
      repo.saves.single['path'],
      '/api/parent/children/7/safety/requests/17/decision',
    );
    expect(repo.saves.single['decision'], 'approve');
    expect(repo.saves.single['minutes'], 15);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
