import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/core/widgets/stat_card.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/workspace_widgets.dart';

void main() {
  testWidgets(
    'Record details wrap long field names and preserve selectable values',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.reset());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: RecordDetails({
                  'veryLongDeviceInstallationIdentifier':
                      'installation-123456789012345678901234567890',
                  'nested': {
                    'description':
                        'A longer record description that should wrap naturally.',
                  },
                }),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SelectableText), findsWidgets);
    },
  );

  testWidgets(
    'Safety metrics fit compact widths with enlarged text and large counts',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 138,
                  height: 240,
                  child: StatCard(
                    label: 'Pairing codes',
                    value: '123456',
                    icon: Icons.qr_code_2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('123456'), findsOneWidget);
      expect(find.text('Pairing codes'), findsOneWidget);
    },
  );
}
