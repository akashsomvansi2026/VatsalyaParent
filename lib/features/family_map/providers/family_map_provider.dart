import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/location_snapshot.dart';
import '../../../data/models/child.dart';
import '../../../data/remote/realtime_gateway.dart';
import '../../../presentation/providers/infra_providers.dart';
import '../../../presentation/providers/session_provider.dart';

const _unchanged = Object();

/// Immutable account-scoped family map state. Widgets own only map/camera UI.
class FamilyMapState {
  const FamilyMapState({
    this.children = const [],
    this.selected,
    this.parent,
    this.error,
    this.cachedAtUtc,
    this.busy = false,
    this.locating = false,
    this.lastSynchronizedAt,
    this.dataRevision = 0,
  });
  final List<Child> children;
  final Child? selected;
  final Position? parent;
  final String? error;
  final DateTime? cachedAtUtc;
  final bool busy;
  final bool locating;
  final DateTime? lastSynchronizedAt;
  final int dataRevision;
  FamilyMapState copyWith({
    Object? children = _unchanged,
    Object? selected = _unchanged,
    Object? parent = _unchanged,
    Object? error = _unchanged,
    Object? cachedAtUtc = _unchanged,
    Object? busy = _unchanged,
    Object? locating = _unchanged,
    Object? lastSynchronizedAt = _unchanged,
    Object? dataRevision = _unchanged,
  }) => FamilyMapState(
    children: identical(children, _unchanged)
        ? this.children
        : children as List<Child>,
    selected: identical(selected, _unchanged)
        ? this.selected
        : selected as Child?,
    parent: identical(parent, _unchanged) ? this.parent : parent as Position?,
    error: identical(error, _unchanged) ? this.error : error as String?,
    cachedAtUtc: identical(cachedAtUtc, _unchanged)
        ? this.cachedAtUtc
        : cachedAtUtc as DateTime?,
    busy: identical(busy, _unchanged) ? this.busy : busy as bool,
    locating: identical(locating, _unchanged)
        ? this.locating
        : locating as bool,
    lastSynchronizedAt: identical(lastSynchronizedAt, _unchanged)
        ? this.lastSynchronizedAt
        : lastSynchronizedAt as DateTime?,
    dataRevision: identical(dataRevision, _unchanged)
        ? this.dataRevision
        : dataRevision as int,
  );
}

final familyMapProvider =
    NotifierProvider.autoDispose<FamilyMapController, FamilyMapState>(
      FamilyMapController.new,
    );

class FamilyMapController extends Notifier<FamilyMapState> {
  bool _disposed = false;
  bool get mounted => !_disposed;
  @override
  FamilyMapState build() {
    ref.onDispose(() => _disposed = true);
    ref.listen(sessionProvider.select((session) => session.parent?.id), (
      previous,
      next,
    ) {
      if (previous != next) state = const FamilyMapState();
    });
    return const FamilyMapState();
  }

  List<Child> get children => state.children;
  Child? get selected => state.selected;
  set selected(Child? value) => state = state.copyWith(selected: value);
  Position? get parent => state.parent;
  set parent(Position? value) => state = state.copyWith(parent: value);
  String? get error => state.error;
  DateTime? get cachedAtUtc => state.cachedAtUtc;
  bool get busy => state.busy;
  bool get locating => state.locating;
  set locating(bool value) => state = state.copyWith(locating: value);
  DateTime? get lastSynchronizedAt => state.lastSynchronizedAt;
  int get dataRevision => state.dataRevision;
  bool get synchronized =>
      error == null &&
      cachedAtUtc == null &&
      lastSynchronizedAt != null &&
      DateTime.now().toUtc().difference(lastSynchronizedAt!) <=
          const Duration(seconds: 45);

  void onEvent(RealtimeEvent event) {
    if (!mounted) return;
    if (event.type == 'pong') {
      if (cachedAtUtc == null && error == null) {
        state = state.copyWith(lastSynchronizedAt: DateTime.now().toUtc());
      }
      return;
    }
    if (event.type != 'child_updated') return;
    final raw = event.data['child'];
    if (raw is! Map<String, dynamic>) return;
    Child incoming;
    try {
      incoming = Child.fromJson(raw);
    } catch (_) {
      return;
    }
    if (event.childId != null && event.childId != incoming.id) return;
    final index = children.indexWhere((c) => c.id == incoming.id);
    if (index < 0) {
      load();
      return;
    }
    final updated = [...children];
    updated[index] = mergeLocationSnapshot(children[index], incoming);
    state = state.copyWith(
      children: List<Child>.unmodifiable(updated),
      selected: updated.where((c) => c.id == selected?.id).firstOrNull,
      dataRevision: dataRevision + 1,
      error: null,
      cachedAtUtc: null,
      lastSynchronizedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> load() async {
    if (busy || !mounted) return;
    final revision = dataRevision;
    final requestingAccountId = ref.read(sessionProvider).parent?.id;
    state = state.copyWith(busy: true);
    try {
      final rows = await ref.read(parentsRepositoryProvider).getChildren();
      if (!mounted ||
          revision != dataRevision ||
          requestingAccountId != ref.read(sessionProvider).parent?.id) {
        return;
      }
      final id = selected?.id;
      final updated = rows
          .map((row) {
            final old = children.where((c) => c.id == row.id).firstOrNull;
            return mergeLocationSnapshot(old, row);
          })
          .toList(growable: false);
      state = state.copyWith(
        children: List<Child>.unmodifiable(updated),
        selected: updated.where((c) => c.id == id).firstOrNull,
        error: null,
        cachedAtUtc: null,
        lastSynchronizedAt: DateTime.now().toUtc(),
      );
      final accountId = ref.read(sessionProvider).parent?.id;
      if (accountId != null) {
        try {
          await ref
              .read(childrenSnapshotCacheProvider)
              .save(accountId, children);
        } catch (_) {}
      }
    } catch (failure) {
      if (mounted &&
          requestingAccountId == ref.read(sessionProvider).parent?.id) {
        if (failure is AppException &&
            (failure.isUnauthorized || failure.statusCode == 403)) {
          state = state.copyWith(
            children: const <Child>[],
            selected: null,
            error: failure.message,
          );
          return;
        }
        final accountId = ref.read(sessionProvider).parent?.id;
        final cached = children.isEmpty && accountId != null
            ? await ref.read(childrenSnapshotCacheProvider).read(accountId)
            : null;
        if (!mounted ||
            requestingAccountId != ref.read(sessionProvider).parent?.id) {
          return;
        }
        final cachedChildren = cached?.children
            .map(
              (c) =>
                  ref.read(sessionProvider).parent?.can('location.view') == true
                  ? c
                  : c.copyWith(clearLatestLocation: true),
            )
            .toList(growable: false);
        state = state.copyWith(
          children: cachedChildren == null
              ? children
              : List<Child>.unmodifiable(cachedChildren),
          cachedAtUtc: cached?.savedAtUtc ?? cachedAtUtc,
          error:
              'Could not refresh locations. Showing the last synchronized information.',
        );
      }
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
  }
}
