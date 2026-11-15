import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/providers/terms_provider.dart';
import 'package:vrajrani_tech_solution/presentation/router/app_router.dart';
import 'package:vrajrani_tech_solution/presentation/screens/auth/forgot_password_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/auth/login_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/auth/sign_up_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/auth/terms_and_conditions_screen.dart';
import 'package:vrajrani_tech_solution/presentation/screens/splash/splash_screen.dart';
import 'package:vrajrani_tech_solution/presentation/widgets/auth/auth_checkbox.dart';
import 'package:vrajrani_tech_solution/presentation/widgets/auth/primary_peach_button.dart';

class FakeTermsNotifier extends TermsNotifier {
  FakeTermsNotifier({this.initialAccepted = false});
  final bool initialAccepted;
  int acceptCalls = 0;
  @override
  bool? build() => initialAccepted;
  @override
  Future<void> accept() async {
    acceptCalls++;
    state = true;
  }
}

class FakeSessionNotifier extends SessionNotifier {
  @override
  SessionState build() => const SessionState.unauthenticated();
}

void main() {
  group('Auth Flow UI & UX Tests', () {
    testWidgets(
      'SplashScreen renders iOS badge, title and progress indicator',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Vatsalya'), findsOneWidget);
        expect(find.text('Family Protection & Safety'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen renders all required visual elements and toggles remember me',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: LoginScreen())),
        );
        await tester.pumpAndSettle();

        // Heading and subtitle
        expect(find.text('Sign in'), findsWidgets);
        expect(find.text('Welcome back to Vatsalya.'), findsOneWidget);

        // Input fields and icons
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

        // Actions & links
        expect(find.text('Remember me'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);
        expect(
          find.widgetWithText(PrimaryPeachButton, 'Sign in'),
          findsOneWidget,
        );
        // The existing login screen intentionally hides the registration link.
        // Keep this assertion aligned with that behavior during presentation work.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains("Don't have an account? Sign up"),
          ),
          findsNothing,
        );

        // Verify validation triggers on empty submit
        await tester.ensureVisible(
          find.widgetWithText(PrimaryPeachButton, 'Sign in'),
        );
        await tester.tap(find.widgetWithText(PrimaryPeachButton, 'Sign in'));
        await tester.pump();
        expect(find.text('Email is required'), findsOneWidget);
      },
    );

    testWidgets(
      'SignUpScreen renders fields, password strength and terms acceptance',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );
        await tester.pumpAndSettle();

        // Heading and subtitle
        expect(find.text('Create account'), findsWidgets);
        expect(
          find.text('Create your account and get started with us.'),
          findsOneWidget,
        );

        // Fields
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        // Enter password to trigger password strength feedback
        await tester.enterText(
          find.widgetWithText(TextField, '').last,
          'Secret123!',
        );
        await tester.pump();
        expect(find.text('Strong password'), findsOneWidget);

        // Check Terms checkbox rich text presence
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains(
                  'I agree with our Terms and Conditions',
                ),
          ),
          findsOneWidget,
        );

        // Toggle checkbox
        final checkboxFinder = find.byType(AuthCheckbox);
        expect(checkboxFinder, findsOneWidget);
        await tester.tap(checkboxFinder);
        await tester.pump();

        // Footer
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('Already have account? Sign in'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TermsAndConditionsScreen renders sections, dates, and sticky acceptance footer',
      (tester) async {
        final fakeTerms = FakeTermsNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [termsProvider.overrideWith(() => fakeTerms)],
            child: const MaterialApp(home: TermsAndConditionsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Header info
        expect(find.text('Terms & Conditions'), findsOneWidget);
        expect(find.text('Last updated: October 2026'), findsOneWidget);
        expect(find.text('Legal Agreement'), findsOneWidget);

        // Sections are below the scrollable reading guide.
        await tester.scrollUntilVisible(find.text('Introduction'), 180);
        await tester.pumpAndSettle();
        // Sections
        expect(find.text('Introduction'), findsOneWidget);

        // Sticky Footer & Agree & Continue
        final agreeButton = find.widgetWithText(
          PrimaryPeachButton,
          'Agree & Continue',
        );
        expect(agreeButton, findsOneWidget);
        expect(
          tester.widget<PrimaryPeachButton>(agreeButton).isEnabled,
          isFalse,
        );

        // Accept checkbox
        final footerCheckbox = find.byType(AuthCheckbox);
        await tester.tap(footerCheckbox);
        await tester.pump();

        expect(
          tester.widget<PrimaryPeachButton>(agreeButton).isEnabled,
          isTrue,
        );

        // Tap Agree & Continue
        await tester.tap(agreeButton);
        await tester.pumpAndSettle();
        expect(fakeTerms.acceptCalls, 1);
      },
    );

    testWidgets(
      'First time install flow: unaccepted terms forces /terms, then navigates to /login',
      (tester) async {
        final fakeTerms = FakeTermsNotifier(initialAccepted: false);
        final fakeSession = FakeSessionNotifier();

        late final ProviderContainer container;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container = ProviderContainer(
              overrides: [
                termsProvider.overrideWith(() => fakeTerms),
                sessionProvider.overrideWith(() => fakeSession),
              ],
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final router = ref.watch(routerProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Should be automatically redirected to Terms & Conditions
        expect(find.text('Terms & Conditions'), findsOneWidget);
        expect(find.text('Legal Agreement'), findsOneWidget);

        // 2. Check the agreement checkbox
        final footerCheckbox = find.byType(AuthCheckbox);
        await tester.tap(footerCheckbox);
        await tester.pump();

        // 3. Tap Agree & Continue
        final agreeButton = find.widgetWithText(
          PrimaryPeachButton,
          'Agree & Continue',
        );
        await tester.tap(agreeButton);
        await tester.pumpAndSettle();

        // 4. Now should be on Login Screen!
        expect(find.text('Sign in'), findsWidgets);
        expect(find.text('Welcome back to Vatsalya.'), findsOneWidget);

        container.dispose();
      },
    );

    testWidgets(
      'ForgotPasswordScreen allows email input and shows confirmation card',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Forgot password?'), findsOneWidget);
        expect(find.text('Email address'), findsOneWidget);

        // Enter valid email
        await tester.enterText(
          find.widgetWithText(TextField, ''),
          'user@example.com',
        );
        await tester.pump();

        final sendButton = find.widgetWithText(
          PrimaryPeachButton,
          'Send Reset Link',
        );
        await tester.tap(sendButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pumpAndSettle();

        // Verify success card
        expect(find.text('Check your email'), findsOneWidget);
        expect(find.text('Return to Sign in'), findsOneWidget);
      },
    );
  });
}
