import '../../core/app_update/app_update.dart';
import '../providers/terms_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/terms_and_conditions_screen.dart';
import '../screens/auth/privacy_policy_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/workspace/content_filter_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/child_detail/child_detail_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/home_shell.dart';
import '../providers/session_provider.dart';
import '../screens/workspace/features_screen.dart';
import '../screens/workspace/sos_screen.dart';
import '../screens/workspace/device_safety_screen.dart';
import '../screens/workspace/records_screen.dart';
import '../screens/workspace/family_management_screen.dart';
import '../screens/workspace/account_screen.dart';
import '../screens/workspace/recovery_screen.dart';
import '../screens/workspace/pairing_screen.dart';
import '../screens/workspace/familymap/family_map_screen.dart';
import '../../core/config/parent_features.dart';
import 'package:flutter/material.dart';

import '../screens/splash/splash_screen.dart';

/// App navigator. Maps the portal's routes to mobile-friendly routes:
/// `/login`, `/` (dashboard), `/child/:id` (child detail).
///
/// First-time install sequence: Splash -> Terms & Conditions -> Login -> Dashboard.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: ref.read(appUpdateProvider),
    redirect: (context, state) {
      if (ref.read(appUpdateProvider).blocked) {
        return state.uri.path == '/app-update' ? null : '/app-update';
      }
      if (state.uri.path == '/app-update') return '/login';
      final session = ref.read(sessionProvider);
      final accepted = ref.read(termsProvider);

      // The privacy notice is readable before login or terms acceptance.
      if (state.uri.path == '/privacy') return null;

      // While restoring initial session and terms state
      if (session.isUnknown || accepted == null) return null;

      // 1. FIRST TIME INSTALLATION GUARD:
      // If terms have not been accepted yet, user MUST review and agree to terms first!
      if (!accepted) {
        return state.uri.path == '/terms' ? null : '/terms';
      }

      // 2. TERMS ACCEPTED & USER AUTHENTICATED:
      // If user is already logged in, redirect them directly to the Dashboard!
      if (session.isAuthenticated) {
        if (state.uri.path == '/login' ||
            state.uri.path == '/signup' ||
            state.uri.path == '/terms') {
          return '/';
        }
        return null;
      }

      // 3. TERMS ACCEPTED BUT UNAUTHENTICATED:
      // Allow public auth routes (/login, /signup, /forgot-password, etc.), otherwise redirect to /login.
      final allowedUnauthenticated = [
        '/login',
        '/signup',
        '/terms',
        '/forgot-password',
        '/recovery',
        '/admin/verify-email',
        '/admin/reset-password',
      ];
      if (allowedUnauthenticated.contains(state.uri.path)) {
        return null;
      }

      return '/login';
    },
    routes: [
      GoRoute(
        path: '/app-update',
        builder: (context, state) => const PopScope(
          canPop: false,
          child: Scaffold(body: SizedBox.expand()),
        ),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/child/:id/content-filter',
        builder: (context, state) => _guard(
          ref,
          ['child.view', 'web_filter.view'],
          ContentFilterScreen(
            childId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/child/:id/safety',
        builder: (context, state) => _guard(
          ref,
          ['child.view', 'control.view'],
          DeviceSafetyScreen(
            childId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/recovery',
        builder: (context, state) => const RecoveryScreen(),
      ),
      GoRoute(
        path: '/admin/verify-email',
        builder: (context, state) => RecoveryScreen(
          initialMode: 'verify-email',
          initialToken: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/admin/reset-password',
        builder: (context, state) => RecoveryScreen(
          initialMode: 'reset-password',
          initialToken: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/sos',
        builder: (context, state) =>
            _guard(ref, ['sos.view'], const SosScreen()),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/family-map',
        builder: (context, state) => _guard(ref, [
          'child.view',
          'location.view',
        ], const FamilyMapScreen()),
      ),
      GoRoute(
        path: '/pairing',
        builder: (context, state) => _guard(
          ref,
          ['device.add'],
          PairingScreen(
            initialChildId: int.tryParse(
              state.uri.queryParameters['childId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/family/:kind',
        builder: (context, state) {
          final devices = state.pathParameters['kind'] == 'devices';
          return _guard(
            ref,
            devices
                ? ['device.view', 'device.add']
                : ['child.view', 'child.create'],
            FamilyManagementScreen(
              devices: devices,
              initialCreate: state.uri.queryParameters['create'] == 'true',
            ),
            any: true,
          );
        },
      ),
      GoRoute(
        path: '/records/:module',
        builder: (context, state) {
          final module = state.pathParameters['module'];
          final features = ParentFeature.all.where((f) => f.key == module);
          if (features.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Feature not found.')),
            );
          }
          final feature = features.first;
          final permissions =
              ref.read(sessionProvider).parent?.permissions ?? <String>{};
          return feature.can(permissions, 'view') ||
                  feature.can(permissions, 'create') ||
                  module == 'report' && feature.can(permissions, 'export')
              ? RecordsScreen(module: module!)
              : _restricted();
        },
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/app-update',
            builder: (context, state) => const PopScope(
              canPop: false,
              child: Scaffold(body: SizedBox.expand()),
            ),
          ),
          GoRoute(
            path: '/child/:id/content-filter',
            builder: (context, state) => _guard(
              ref,
              ['child.view', 'web_filter.view'],
              ContentFilterScreen(
                childId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) =>
                _guard(ref, ['dashboard.view'], const DashboardScreen()),
          ),
          GoRoute(
            path: '/features',
            builder: (context, state) => const FeaturesScreen(),
          ),
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => _guard(ref, [
              'child.view',
              'location.view',
            ], const FamilyMapScreen()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/child/:id',
        name: 'childDetail',
        builder: (context, state) {
          final childId = int.tryParse(state.pathParameters['id'] ?? '');
          return _guard(ref, [
            'child.view',
          ], ChildDetailScreen(childId: childId ?? 0));
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Widget _guard(
  Ref ref,
  List<String> permissions,
  Widget child, {
  bool any = false,
}) {
  final parent = ref.read(sessionProvider).parent;
  final allowed = any
      ? permissions.any((p) => parent?.can(p) == true)
      : permissions.every((p) => parent?.can(p) == true);
  return allowed ? child : _restricted();
}

Widget _restricted() => Scaffold(
  appBar: AppBar(title: const Text('Access restricted')),
  body: const Center(
    child: Text('Your account does not have permission to open this feature.'),
  ),
);
