import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/child.dart';
import '../../data/models/pairing_code.dart';
import '../../data/models/sos_event.dart';
import '../../data/repositories/parents_repository.dart';
import 'infra_providers.dart';
import 'session_provider.dart';
import '../../core/utils/load_section.dart';
import '../../core/utils/formatters.dart';

/// Dashboard aggregate fetched from the portal (same three lists the
/// portal's Dashboard loads in parallel).
class DashboardData {
  const DashboardData({
    this.children = const [],
    this.pairingCodes = const [],
    this.sosEvents = const [],
  });

  final List<Child> children;
  final List<PairingCode> pairingCodes;
  final List<SosEvent> sosEvents;

  int get activeSosCount => sosEvents.where((e) => e.isActive).length;
  int get onlineCount => children.where((c) => c.isOnline).length;

  DashboardData copyWith({
    List<Child>? children,
    List<PairingCode>? pairingCodes,
    List<SosEvent>? sosEvents,
  }) {
    return DashboardData(
      children: children ?? this.children,
      pairingCodes: pairingCodes ?? this.pairingCodes,
      sosEvents: sosEvents ?? this.sosEvents,
    );
  }
}

class DashboardState {
  const DashboardState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.data,
    this.pendingAction = false,
  });

  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DashboardData? data;
  final bool pendingAction;

  bool get hasData => data != null;

  DashboardState _copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? pendingAction,
    String? error,
    bool clearError = false,
    DashboardData? data,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pendingAction: pendingAction ?? this.pendingAction,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}

/// Loads the dashboard's children + pairing codes + SOS events, and exposes
/// mutations that mirror the portal (generate/revoke code, delete child,
/// resolve SOS).
class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() => const DashboardState();

  ParentsRepository get _repo => ref.read(parentsRepositoryProvider);

  Future<List<Child>> _childrenWithCache(List<String> warnings) async {
    final accountId = ref.read(sessionProvider).parent?.id;
    try {
      final rows = await _repo.getChildren();
      if (accountId != null) {
        try {
          await ref.read(childrenSnapshotCacheProvider).save(accountId, rows);
        } catch (_) {
          // A storage failure must not hide a successful server response.
        }
      }
      return rows;
    } catch (_) {
      if (accountId != null) {
        final cached = await ref.read(childrenSnapshotCacheProvider).read(accountId);
        if (cached != null) {
          warnings.add(
            'Offline copy: child locations were last synchronized ${Formatters.relativeTime(cached.savedAtUtc)}. They are not live.',
          );
          final canSeeLocation = ref.read(sessionProvider).parent?.can('location.view') == true;
          return canSeeLocation
              ? cached.children
              : cached.children
                  .map((child) => child.copyWith(clearLatestLocation: true))
                  .toList();
        }
      }
      rethrow;
    }
  }

  Future<void> load({bool silent = false}) async {
    if (state.isLoading || state.isRefreshing) return;
    if (silent && state.hasData) {
      state = state._copyWith(isRefreshing: true, clearError: true);
    } else if (!silent) {
      state = state._copyWith(isLoading: true, clearError: true);
    }

    try {
      final warnings = <String>[];
      final results = await Future.wait([
        loadSection(
          ref.read(sessionProvider).parent?.can('child.view') == true,
          () => _childrenWithCache(warnings),
          warnings,
          'Children',
        ),
        loadSection(
          ref.read(sessionProvider).parent?.can('device.add') == true,
          _repo.getPairingCodes,
          warnings,
          'Pairing',
        ),
        loadSection(
          ref.read(sessionProvider).parent?.can('sos.view') == true,
          _repo.getSosEvents,
          warnings,
          'SOS',
        ),
      ]);
      if (!ref.mounted) return;
      state = DashboardState(
        error: warnings.isEmpty ? null : warnings.join('\n'),
        data: DashboardData(
          children: results[0] as List<Child>,
          pairingCodes: results[1] as List<PairingCode>,
          sosEvents: results[2] as List<SosEvent>,
        ),
      );
    } on AppException catch (error) {
      if (!ref.mounted) return;
      state = state._copyWith(
        isLoading: false,
        isRefreshing: false,
        error: error.message,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state._copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> refresh() => load(silent: state.hasData);

  Future<void> revokePairingCode(int codeId) async {
    await _repo.revokePairingCode(codeId);
    await refresh();
  }

  Future<void> deleteChild(int childId) async {
    await _repo.deleteChild(childId);
    await refresh();
  }

  Future<void> resolveSos(int eventId) async {
    await _repo.resolveSos(eventId);
    await refresh();
  }

  // ---- Realtime event handling (mirrors the portal's useRealtime hook) ----

  /// `location` frame: portal patches only that child's battery, no reload.
  void applyLocationPatch(int? childId, int? batteryLevel) {
    if (childId == null || !state.hasData) return;
    final updated = state.data!.children.map((child) {
      return child.id == childId
          ? child.copyWith(batteryLevel: batteryLevel, isOnline: true)
          : child;
    }).toList();
    state = state._copyWith(data: state.data!.copyWith(children: updated));
  }

  /// Structural events cause a full background reload like the portal.
  void reloadFromEvent(String type) {
    if (![
      'child_paired',
      'sos',
      'sos_resolved',
      'child_updated',
      'child_deleted',
    ].contains(type)) {
      return;
    }
    load(silent: state.hasData);
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
