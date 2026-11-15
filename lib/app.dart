import 'core/app_update/app_update_manager.dart';
import 'presentation/providers/terms_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/remote/realtime_gateway.dart';
import 'presentation/providers/infra_providers.dart';
import 'presentation/providers/session_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/child_detail_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/screens/splash/splash_screen.dart';

/// App root. Restores the session, routes based on it, and keeps the
/// realtime gateway connected whenever the parent is signed in.
class VrajraniApp extends ConsumerStatefulWidget {
  const VrajraniApp({super.key});

  @override
  ConsumerState<VrajraniApp> createState() => _VrajraniAppState();
}

class _VrajraniAppState extends ConsumerState<VrajraniApp>
    with WidgetsBindingObserver {
  final _shownSafetyRequests = <int>{};
  Timer? _accountTimer;
  StreamSubscription? _pushEvents;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accountTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (ref.read(sessionProvider).isAuthenticated) {
        unawaited(
          ref.read(sessionProvider.notifier).reloadAccount().catchError((_) {}),
        );
      }
    });
    _pushEvents = ref.read(parentPushProvider).events.stream.listen((message) {
      if (ref.read(sessionProvider).isAuthenticated) {
        ref.invalidate(dashboardProvider);
        ref.invalidate(childDetailProvider);
        final title = message.notification?.title;
        if (title != null) {
          final context = ref
              .read(routerProvider)
              .routerDelegate
              .navigatorKey
              .currentContext;
          if (context != null && context.mounted) {
            ScaffoldMessenger.maybeOf(
              context,
            )?.showSnackBar(SnackBar(content: Text(title)));
          }
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Elegant splash display duration on launch
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      await Future.wait([
        ref.read(termsProvider.notifier).restore(),
        ref.read(sessionProvider.notifier).restore(),
      ]);
    });
  }

  @override
  void dispose() {
    _accountTimer?.cancel();
    _pushEvents?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(sessionProvider).isAuthenticated) {
      ref.read(realtimeGatewayProvider).connect();
      unawaited(
        ref.read(sessionProvider.notifier).reloadAccount().catchError((_) {}),
      );
      ref.invalidate(dashboardProvider);
      ref.invalidate(childDetailProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeStreamProvider, (_, next) {
      final event = next.value;
      if (event?.type != 'device_safety_request' ||
          !ref.read(sessionProvider).isAuthenticated) {
        return;
      }
      final pending = (event!.data['pendingIds'] as List? ?? [])
          .whereType<int>()
          .toSet();
      final fresh = pending.difference(_shownSafetyRequests);
      final router = ref.read(routerProvider);
      final context = router.routerDelegate.navigatorKey.currentContext;
      if (fresh.isNotEmpty && context != null && context.mounted) {
        _shownSafetyRequests.addAll(pending);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: const Text('Your child requested device permission.'),
            action: SnackBarAction(
              label: 'Review',
              onPressed: () => router.push('/child/${event.childId}/safety'),
            ),
          ),
        );
      }
    });
    ref.listen<SessionState>(sessionProvider, (previous, next) {
      if (next.isUnauthenticated) _shownSafetyRequests.clear();
      final router = ref.read(routerProvider);
      router.refresh();

      if (next.isAuthenticated &&
          (previous == null || !previous.isAuthenticated)) {
        ref.read(realtimeGatewayProvider).connect();
        unawaited(ref.read(parentPushProvider).restore().catchError((_) {}));
      } else if (next.isUnauthenticated &&
          (previous?.isAuthenticated ?? false)) {
        ref.read(realtimeGatewayProvider).disconnect();
      }
    });

    ref.listen<bool?>(termsProvider, (_, next) {
      ref.read(routerProvider).refresh();
    });
    final terms = ref.watch(termsProvider);
    final session = ref.watch(sessionProvider);
    if (session.isUnknown || terms == null) {
      return MaterialApp(
        title: 'Vatsalya',
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      );
    }

    return MaterialApp.router(
      key: ValueKey(
        '${ref.read(sessionProvider.notifier).revision}:${session.parent?.id}:${session.parent?.permissions.join(',')}',
      ),
      title: 'Vatsalya',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          AppUpdateManager(child: child ?? const SizedBox.shrink()),
    );
  }
}
