import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/presentation/providers/terms_provider.dart';
import 'package:vrajrani_tech_solution/presentation/screens/splash/terms_screen.dart';

class FakeTerms extends TermsNotifier {
  int saves = 0;
  bool fail = false;
  @override
  bool? build() => false;
  @override
  Future<void> accept() async {
    saves++;
    if (fail) throw StateError('Storage unavailable');
    state = true;
  }
}

void main() {
  testWidgets('Terms require explicit agreement before acceptance', (
    tester,
  ) async {
    final terms = FakeTerms();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [termsProvider.overrideWith(() => terms)],
        child: const MaterialApp(home: TermsScreen()),
      ),
    );
    final button = find.widgetWithText(FilledButton, 'Agree & Continue');
    await tester.scrollUntilVisible(button, 200);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(terms.saves, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Acceptance storage failure leaves a retryable terms screen', (
    tester,
  ) async {
    final terms = FakeTerms()..fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [termsProvider.overrideWith(() => terms)],
        child: const MaterialApp(home: TermsScreen()),
      ),
    );
    final button = find.widgetWithText(FilledButton, 'Agree & Continue');
    await tester.scrollUntilVisible(button, 200);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save your acceptance. Please try again.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });
}

