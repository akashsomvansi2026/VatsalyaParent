import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/collections.dart';
import '../../data/models/app_info.dart';
import '../../data/models/child.dart';
import '../../data/models/location_point.dart';
import '../../data/models/sos_event.dart';
import '../../data/models/usage_record.dart';
import '../../data/remote/realtime_gateway.dart';
import '../../data/repositories/parents_repository.dart';
import 'dashboard_provider.dart';
import 'infra_providers.dart';
import 'session_provider.dart';
import '../../core/utils/load_section.dart';

enum ChildTab { map, apps, usage }

class ChildDetailState {
  const ChildDetailState({
    this.isLoading = false,
    this.error,
    this.child,
    this.locations = const [],
    this.apps = const [],
    this.usage = const [],
    this.sosEvents = const [],
    this.tab = ChildTab.map,
    this.usageDays = 7,
    this.usageLoading = false,
    this.actionLoading = false,
  });

  final bool isLoading;
  final String? error;
  final Child? child;
  final List<LocationPoint> locations;
  final List<AppInfo> apps;
  final List<UsageRecord> usage;
  final List<SosEvent> sosEvents;
  final ChildTab tab;
  final int usageDays;
  final bool usageLoading;
  final bool actionLoading;

  ChildDetailState _copyWith({
    bool? isLoading,
    bool? usageLoading,
    bool? actionLoading,
    String? error,
    bool clearError = false,
    Child? child,
    bool clearChild = false,
    List<LocationPoint>? locations,
    List<AppInfo>? apps,
    List<UsageRecord>? usage,
    List<SosEvent>? sosEvents,
    ChildTab? tab,
    int? usageDays,
  }) {
    return ChildDetailState(
      isLoading: isLoading ?? this.isLoading,
      usageLoading: usageLoading ?? this.usageLoading,
      actionLoading: actionLoading ?? this.actionLoading,
      error: clearError ? null : (error ?? this.error),
      child: clearChild ? null : (child ?? this.child),
      locations: locations ?? this.locations,
      apps: apps ?? this.apps,
      usage: usage ?? this.usage,
      sosEvents: sosEvents ?? this.sosEvents,
      tab: tab ?? this.tab,
      usageDays: usageDays ?? this.usageDays,
    );
  }
}

/// Per-child supervision state: map history, app policy and screen-time.
class ChildDetailNotifier extends Notifier<ChildDetailState> {
  ChildDetailNotifier(this.childId);

  final int childId;

  @override
  ChildDetailState build() {
    final parent = ref.read(sessionProvider).parent;
    return ChildDetailState(
      child: _childFromDashboard(),
      tab: parent?.can('location.view') == true
          ? ChildTab.map
          : parent?.can('app.view') == true
          ? ChildTab.apps
          : ChildTab.usage,
    );
  }

  ParentsRepository get _repo => ref.read(parentsRepositoryProvider);

  Child? _childFromDashboard() {
    final dashboard = ref.read(dashboardProvider);
    return firstWhereOrNull(
      dashboard.data?.children ?? const <Child>[],
      (c) => c.id == childId,
    );
  }

  /// Syncs the child snapshot with the dashboard list (keeps header fresh).
  void _syncChild() {
    final fromDashboard = _childFromDashboard();
    if (fromDashboard != null) {
      state = state._copyWith(child: fromDashboard);
    }
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state._copyWith(isLoading: true, clearError: true);
    try {
      final child = await _repo.getChild(childId);
      if (!ref.mounted) return;
      state = state._copyWith(child: child);
      final warnings = <String>[];
      final results = await Future.wait([
        loadSection(
          ref.read(sessionProvider).parent?.can('location.view') == true,
          () => _repo.getLocations(
            childId,
            limit:
                ref
                        .read(sessionProvider)
                        .parent
                        ?.can('location.history.view') ==
                    true
                ? 100
                : 1,
          ),
          warnings,
          'Locations',
        ),
        loadSection(
          ref.read(sessionProvider).parent?.can('app.view') == true,
          () => _repo.getApps(childId),
          warnings,
          'Apps',
        ),
        loadSection(
          ref.read(sessionProvider).parent?.can('sos.view') == true,
          _repo.getSosEvents,
          warnings,
          'SOS',
        ),
      ]);
      if (!ref.mounted) return;
      state = state._copyWith(
        isLoading: false,
        error: warnings.isEmpty ? null : warnings.join('\n'),
        locations: results[0] as List<LocationPoint>,
        apps: results[1] as List<AppInfo>,
        sosEvents: (results[2] as List<SosEvent>)
            .where((e) => e.childId == childId)
            .toList(),
      );
      if (state.tab == ChildTab.usage &&
          ref.read(sessionProvider).parent?.can('screen_time.view') == true) {
        await loadUsage();
      }
    } on AppException catch (error) {
      if (!ref.mounted) return;
      state = state._copyWith(isLoading: false, error: error.message);
    } catch (_) {
      if (!ref.mounted) return;
      state = state._copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> refresh() async {
    _syncChild();
    await load();
  }

  void selectTab(ChildTab tab) {
    if (tab == state.tab) return;
    state = state._copyWith(tab: tab);
    if (tab == ChildTab.usage && state.usage.isEmpty) {
      loadUsage();
    }
  }

  Future<void> loadUsage({int? days}) async {
    if (ref.read(sessionProvider).parent?.can('screen_time.view') != true) {
      return;
    }
    final targetDays = days ?? state.usageDays;
    state = state._copyWith(usageLoading: true, usageDays: targetDays);
    try {
      final usage = await _repo.getUsage(childId, days: targetDays);
      if (!ref.mounted) return;
      state = state._copyWith(usageLoading: false, usage: usage);
    } on AppException catch (error) {
      if (!ref.mounted) return;
      state = state._copyWith(usageLoading: false, error: error.message);
    } catch (_) {
      if (!ref.mounted) return;
      state = state._copyWith(
        usageLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> setTracking(bool enabled) async {
    state = state._copyWith(actionLoading: true);
    try {
      final updated = await _repo.setTracking(childId, enabled);
      if (!ref.mounted) return;
      state = state._copyWith(actionLoading: false, child: updated);
    } on AppException catch (error) {
      if (!ref.mounted) return;
      if (!ref.mounted) return;
      state = state._copyWith(actionLoading: false, error: error.message);
      rethrow;
    }
  }

  Future<void> setProtection(bool enabled) async {
    state = state._copyWith(actionLoading: true);
    try {
      await _repo.setProtection(childId, enabled);
      final current = state.child;
      state = state._copyWith(
        actionLoading: false,
        child: current?.copyWith(protectionEnabled: enabled) ?? current,
      );
    } on AppException catch (error) {
      if (!ref.mounted) return;
      if (!ref.mounted) return;
      state = state._copyWith(actionLoading: false, error: error.message);
      rethrow;
    }
  }

  /// Applies a policy patch to a single app row and pushes it, replacing the
  /// app list with the server's authoritative response (portal behavior).
  Future<void> setAppPolicy(AppInfo patch) async {
    if (state.actionLoading) return;
    state = state._copyWith(actionLoading: true);
    try {
      final updated = await _repo.setAppPolicy(childId, [patch]);
      if (!ref.mounted) return;
      state = state._copyWith(apps: updated, actionLoading: false);
    } catch (_) {
      if (ref.mounted) state = state._copyWith(actionLoading: false);
      rethrow;
    }
  }

  /// Pushes a new Android keyguard password to the child device (locks now).
  Future<void> setDeviceLockPin(String pin) async {
    state = state._copyWith(actionLoading: true);
    try {
      await _repo.setDeviceLock(childId, pin);
      if (!ref.mounted) return;
      state = state._copyWith(actionLoading: false);
    } on AppException catch (error) {
      if (!ref.mounted) return;
      if (!ref.mounted) return;
      state = state._copyWith(actionLoading: false, error: error.message);
      rethrow;
    }
  }

  /// Pushes a new launcher parent-area PIN to the child device.
  Future<void> setParentAreaPin(String pin) async {
    state = state._copyWith(actionLoading: true);
    try {
      await _repo.setParentLock(childId, pin);
      if (!ref.mounted) return;
      state = state._copyWith(actionLoading: false);
    } on AppException catch (error) {
      if (!ref.mounted) return;
      if (!ref.mounted) return;
      state = state._copyWith(actionLoading: false, error: error.message);
      rethrow;
    }
  }

  /// Handles realtime frames relevant to this child.
  void onRealtimeEvent(RealtimeEvent event) {
    switch (event.type) {
      case 'location':
        if (event.childId != childId) return;
        _syncChild();
        load(); // reload locations + apps + sos, keeping header fresh
      case 'child_updated':
        if (event.data['child'] is Map<String, dynamic>) {
          final child = Child.fromJson(
            event.data['child'] as Map<String, dynamic>,
          );
          if (child.id == childId) {
            state = state._copyWith(child: child);
          }
        }
      case 'app_policy':
        if (event.childId != childId) return;
        load();
      case 'sos':
      case 'sos_resolved':
        load();
    }
  }
}

final childDetailProvider =
    NotifierProvider.family<ChildDetailNotifier, ChildDetailState, int>(
      (childId) => ChildDetailNotifier(childId),
    );
