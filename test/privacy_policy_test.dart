import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/providers/terms_provider.dart';
import 'package:vrajrani_tech_solution/presentation/router/app_router.dart';
import 'package:vrajrani_tech_solution/presentation/screens/auth/privacy_policy_screen.dart';

class _PublicSession extends SessionNotifier {
  @override
  SessionState build() => const SessionState.unauthenticated();
}

class _UnacceptedTerms extends TermsNotifier {
  @override
  bool? build() => false;
}

void main() {
  testWidgets('privacy is public and does not accept terms or sign in', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(_PublicSession.new),
        termsProvider.overrideWith(_UnacceptedTerms.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    router.go('/privacy');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(container.read(termsProvider), isFalse);
    expect(container.read(sessionProvider).isUnauthenticated, isTrue);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/terms');
  });

  testWidgets(
    'policy remains readable on a compact screen with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const PrivacyPolicyScreen(),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Questions and policy updates'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 80,
      );
      expect(find.text('Questions and policy updates'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
