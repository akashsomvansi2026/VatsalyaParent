import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../repositories/workspace_repository.dart';

Future<FirebaseApp> initializeParentFirebase() async {
  if (Firebase.apps.isNotEmpty) return Firebase.app();
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  if (apiKey.isEmpty) return Firebase.initializeApp();
  return Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: apiKey,
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> parentPushBackground(RemoteMessage message) async {
  await initializeParentFirebase();
  // Visible notification payloads are displayed by the OS. Mark local data for
  // refresh on resume; never store a previous family's sensitive payload here.
  await const FlutterSecureStorage().write(
    key: 'vg_parent_push_pending',
    value: 'true',
  );
}

class ParentPushService {
  ParentPushService(this.repo);
  final WorkspaceRepository repo;
  final storage = const FlutterSecureStorage();
  final events = StreamController<RemoteMessage>.broadcast();
  final List<StreamSubscription<dynamic>> subscriptions = [];
  bool ready = false, active = false;
  int epoch = 0;
  String status = 'Notifications are not enabled.';
  String? installation;
  Future<void> initialize() async {
    if (ready) return;
    try {
      await initializeParentFirebase();
      FirebaseMessaging.onBackgroundMessage(parentPushBackground);
      subscriptions.add(
        FirebaseMessaging.onMessage.listen((message) {
          if (active) events.add(message);
        }),
      );
      subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          if (active) events.add(message);
        }),
      );
      subscriptions.add(
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
          if (active) unawaited(register(token).catchError((_) {}));
        }),
      );
      ready = true;
    } catch (_) {
      status =
          'Firebase configuration is required for this Parent app package.';
    }
  }

  Future<void> restore() async {
    if (await storage.read(key: 'vg_parent_push_opt_in') != 'true') return;
    await enable(requestPermission: false);
  }

  Future<void> enable({bool requestPermission = true}) async {
    final currentEpoch = epoch;
    await initialize();
    if (!ready) return;
    final permission = requestPermission
        ? await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
        : await FirebaseMessaging.instance.getNotificationSettings();
    if (currentEpoch != epoch) return;
    if (![
      AuthorizationStatus.authorized,
      AuthorizationStatus.provisional,
    ].contains(permission.authorizationStatus)) {
      status =
          'Notification permission was denied. Enable it in phone settings.';
      return;
    }
    await storage.write(key: 'vg_parent_push_opt_in', value: 'true');
    if (currentEpoch != epoch) return;
    active = true;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      status =
          'Push token unavailable. Check Google Play services / APNs setup.';
      return;
    }
    if (currentEpoch != epoch) return;
    await register(token);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && active) events.add(initial);
  }

  Future<void> register(String token) async {
    final currentEpoch = epoch;
    installation ??= await storage.read(key: 'vg_parent_installation');
    installation ??= base64UrlEncode(
      List.generate(24, (_) => Random.secure().nextInt(256)),
    );
    await storage.write(key: 'vg_parent_installation', value: installation);
    if (!active || currentEpoch != epoch) return;
    await repo.save('/api/notifications/tokens', {
      'installationId': installation,
      'token': token,
    });
    if (currentEpoch == epoch) {
      status = 'Notifications enabled for this account.';
    }
  }

  /// Explicit user opt-out persists across sign-in and app restarts.
  Future<void> disable() async {
    await storage.write(key: 'vg_parent_push_opt_in', value: 'false');
    await stop();
  }

  Future<void> stop({bool revoke = true}) async {
    epoch++;
    active = false;
    if (revoke && installation != null) {
      try {
        await repo.remove(
          '/api/notifications/tokens/${Uri.encodeComponent(installation!)}',
        );
      } catch (_) {
        /* Account invalidation also prevents delivery on the server. */
      }
    }
    if (ready) {
      // Delete local FCM token as well, so a failed server revoke cannot keep
      // delivering the old account's notifications on this installation.
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
    }
    status = 'Notifications are not enabled.';
  }

  void dispose() {
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(events.close());
  }
}
