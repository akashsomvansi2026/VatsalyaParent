import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vrajrani_tech_solution/presentation/widgets/provisioning_sheet.dart';
import 'parent_screens_test.dart' show FakeWorkspace, mount;

class EnrollmentWorkspace extends FakeWorkspace {
  final saves = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> save(
    String path,
    Map<String, dynamic> data, {
    String method = 'POST',
  }) async {
    saves.add({'path': path, ...data});
    return {
      'managedEnrollment': true,
      'expiresAtUtc': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      'provisioningPayload': {
        'android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME':
            'com.skysoftsolutions.androidmdmpolicy/.admin.MdmAdminReceiver',
        'android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION':
            'https://downloads.example.test/mdm.apk',
        'android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_CHECKSUM':
            'A' * 43,
        'android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE': {
          'vatsalya.enrollmentCode': 'ABC123',
        },
      },
    };
  }
}

void main() {
  testWidgets(
    'managed invitation requires explicit consent and uses backend provisioning payload',
    (tester) async {
      final repo = EnrollmentWorkspace();
      await mount(
        tester,
        const Scaffold(body: ProvisioningSheet(childId: 7)),
        {'parent.device.add', 'parent.device.assign', 'parent.child.create'},
        repo,
        GlobalKey(),
      );
      final button = find.widgetWithText(
        FilledButton,
        'Generate managed enrollment QR',
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(find.byType(QrImageView), findsNothing);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        repo.saves.single['path'],
        '/api/parent/children/7/managed-enrollment',
      );
      expect(repo.saves.single['guardianConsent'], true);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'read-only Parent gets accurate ownership guidance without issuing invitation',
    (tester) async {
      final repo = EnrollmentWorkspace();
      await mount(
        tester,
        const Scaffold(body: ProvisioningSheet(childId: 7)),
        {'parent.child.view'},
        repo,
        GlobalKey(),
      );
      expect(find.text('Generate managed enrollment QR'), findsNothing);
      expect(
        find.textContaining('does not grant Device Owner'),
        findsOneWidget,
      );
      expect(repo.saves, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

