import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/parent_user.dart';
import '../../core/errors/app_exception.dart';
import 'infra_providers.dart';
import 'dashboard_provider.dart';
import 'child_detail_provider.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionState {
  const SessionState._(this.status, this.parent);
  const SessionState.unknown() : this._(SessionStatus.unknown, null);
  const SessionState.authenticated(ParentUser? parent)
    : this._(SessionStatus.authenticated, parent);
  const SessionState.unauthenticated()
    : this._(SessionStatus.unauthenticated, null);
  final SessionStatus status;
  final ParentUser? parent;
  bool get isUnknown => status == SessionStatus.unknown;
  bool get isAuthenticated => status == SessionStatus.authenticated;
  bool get isUnauthenticated => status == SessionStatus.unauthenticated;
}

class SessionNotifier extends Notifier<SessionState> {
  int revision = 0;
  Future<void>? _cleanup;
  @override
  SessionState build() => const SessionState.unknown();
  void _clearFamily() {
    revision++;
    ref.read(realtimeGatewayProvider).disconnect();
    ref.invalidate(dashboardProvider);
    ref.invalidate(childDetailProvider);
  }

  Future<void> reloadAccount() async {
    final epoch = revision;
    final json = await ref.read(workspaceRepositoryProvider).me();
    if (epoch != revision || !ref.mounted) return;
    if (json['scopeKind'] != 'PARENT') {
      await logout();
      throw const AppException('Sign in with a Parent account.');
    }
    final parent = ParentUser.fromJson(json);
    final previous = state.parent;
    if (previous != null &&
        (previous.id != parent.id ||
            previous.permissions.length != parent.permissions.length ||
            !previous.permissions.containsAll(parent.permissions))) {
      _clearFamily();
      unawaited(ref.read(realtimeGatewayProvider).connect());
    }
    state = SessionState.authenticated(parent);
  }

  Future<void> restore() async {
    final token = await ref.read(authRepositoryProvider).restoreToken();
    if (token == null || token.isEmpty) {
      state = const SessionState.unauthenticated();
      return;
    }
    try {
      await reloadAccount();
    } catch (_) {
      if (ref.mounted) state = const SessionState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    await _cleanup;
    await ref.read(parentPushProvider).stop();
    _clearFamily();
    await ref.read(authRepositoryProvider).clearSession();
    await ref.read(authRepositoryProvider).login(email, password);
    await reloadAccount();
  }

  Future<void> logout() async {
    await ref.read(parentPushProvider).stop();
    _clearFamily();
    await ref.read(authRepositoryProvider).clearSession();
    if (ref.mounted) state = const SessionState.unauthenticated();
  }

  void handleUnauthorized() {
    unawaited(ref.read(parentPushProvider).stop(revoke: false));
    _clearFamily();
    _cleanup = ref.read(authRepositoryProvider).clearSession();
    unawaited(_cleanup);
    state = const SessionState.unauthenticated();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);
