import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/presentation/widgets/managed_device_commands_card.dart';
import 'parent_screens_test.dart' show FakeWorkspace, mount;

class CommandsWorkspace extends FakeWorkspace {
  CommandsWorkspace({
    this.allowedActions = const ['refresh', 'lock', 'camera'],
  });
  final List<String> allowedActions;
  final saves = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> list(String path) async =>
      path.endsWith('/devices')
      ? [
          {
            'id': 22,
            'name': 'Riya MDM phone',
            'allowedActions': allowedActions,
            'report': {'deviceOwner': true},
            'reportedAtUtc': '2026-10-23T12:00:00Z',
          },
        ]
      : [
          {
            'id': 13,
            'status': 'Applied',
            'data': {
              'request': {'action': 'camera'},
              'acknowledgement': {'code': 'APPLIED'},
              'expiresAtUtc': '2026-10-23T12:15:00Z',
            },
          },
        ];
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
  testWidgets('reported owner without server capability cannot send lock', (
    tester,
  ) async {
    final repo = CommandsWorkspace(allowedActions: ['refresh']);
    await mount(
      tester,
      const SingleChildScrollView(child: ManagedDeviceCommandsCard(childId: 7)),
      {'parent.control.view', 'parent.control.update'},
      repo,
      GlobalKey(),
    );
    final lock = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Lock device now'),
    );
    expect(lock.onPressed, isNull);
    final refresh = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Refresh device information'),
    );
    expect(refresh.onPressed, isNotNull);
    expect(repo.saves, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'read-only Parent sees acknowledgements without native action controls',
    (tester) async {
      await mount(
        tester,
        const SingleChildScrollView(
          child: ManagedDeviceCommandsCard(childId: 7),
        ),
        {'parent.control.view'},
        CommandsWorkspace(),
        GlobalKey(),
      );
      expect(find.text('Lock device now'), findsNothing);
      expect(find.text('Result: APPLIED'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Parent lock requires confirmation and queues existing scoped contract',
    (tester) async {
      final repo = CommandsWorkspace();
      await mount(
        tester,
        const SingleChildScrollView(
          child: ManagedDeviceCommandsCard(childId: 7),
        ),
        {'parent.control.view', 'parent.control.update'},
        repo,
        GlobalKey(),
      );
      await tester.ensureVisible(find.text('Lock device now'));
      await tester.tap(find.text('Lock device now'));
      await tester.pumpAndSettle();
      expect(repo.saves, isEmpty);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(
        repo.saves.single['path'],
        '/api/parent/children/7/management/commands',
      );
      expect(repo.saves.single['deviceId'], 22);
      expect(repo.saves.single['action'], 'lock');
      expect(
        repo.saves.single['requestId'],
        matches(RegExp(r'^[a-f0-9-]{36}$')),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
