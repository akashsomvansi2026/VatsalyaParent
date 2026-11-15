import '../../data/models/child.dart';

/// Merge a complete authorized snapshot; null is authoritative (permission loss).
Child mergeLocationSnapshot(Child? previous, Child incoming, {DateTime? now}) {
  final clock = now ?? DateTime.now().toUtc();
  final next = incoming.latestLocation;
  if (next == null) return incoming;
  final old = previous?.id == incoming.id ? previous?.latestLocation : null;
  final sameDevice = previous?.deviceId == incoming.deviceId;
  final outOfOrder =
      sameDevice &&
      old?.recordedAtUtc != null &&
      (next.recordedAtUtc == null ||
          next.recordedAtUtc!.isBefore(old!.recordedAtUtc!));
  if (!next.isDisplayableAt(clock) || outOfOrder) {
    final retain = sameDevice && old?.isDisplayableAt(clock) == true;
    return incoming.copyWith(
      latestLocation: retain ? old : null,
      clearLatestLocation: !retain,
    );
  }
  return incoming;
}
