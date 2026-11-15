import '../../data/models/child.dart';
import 'formatters.dart';

enum TrackingState { active, disabled, stale, offline, unavailable }

/// Derived from independent heartbeat, capture time and device capability reports.
class ChildLocationStatus {
  const ChildLocationStatus._(
    this.state,
    this.label,
    this.detail,
    this.hasLocation,
  );
  final TrackingState state;
  final String label, detail;
  final bool hasLocation;
  bool get isRecent => state == TrackingState.active;

  static ChildLocationStatus fromChild(
    Child child, {
    DateTime? now,
    bool synchronized = true,
  }) {
    final clock = now ?? DateTime.now().toUtc();
    final location = child.latestLocation;
    final valid = location?.isDisplayableAt(clock) == true;
    final report = child.trackingStatus;
    final captured = location?.recordedAtUtc;
    final age = captured == null ? null : clock.difference(captured);
    final reportTime = DateTime.tryParse(
      report?['reportedAtUtc']?.toString() ?? '',
    );
    final reportAge = reportTime == null ? null : clock.difference(reportTime);
    final verified =
        reportAge != null &&
        !reportAge.isNegative &&
        reportAge <= const Duration(minutes: 2);
    final last = valid
        ? captured == null
              ? 'Update time unavailable · not verified live'
              : 'Last known position · updated ${Formatters.relativeTime(captured)}'
        : 'No valid location has been reported.';
    ChildLocationStatus result(
      TrackingState state,
      String label,
      String detail,
    ) => ChildLocationStatus._(state, label, detail, valid);
    if (!child.trackingEnabled) {
      return result(
        TrackingState.disabled,
        'Tracking Disabled',
        'Location sharing is off. $last',
      );
    }
    if (!synchronized) {
      return result(
        TrackingState.unavailable,
        'Tracking temporarily unavailable',
        'Parent connection is unverified. $last',
      );
    }
    final seenAge = child.lastSeenAtUtc == null
        ? null
        : clock.difference(child.lastSeenAtUtc!);
    if (!child.isOnline ||
        seenAge == null ||
        seenAge.isNegative ||
        seenAge > const Duration(minutes: 2)) {
      return result(
        TrackingState.offline,
        'Device Offline',
        'Device heartbeat unavailable. $last',
      );
    }
    if (verified &&
        (report?['locationPermissionGranted'] == false ||
            report?['locationServicesEnabled'] == false)) {
      return result(
        TrackingState.disabled,
        'Tracking Disabled',
        'Location permission or location services are off. $last',
      );
    }
    if (!valid) {
      return result(TrackingState.unavailable, 'Location unavailable', last);
    }
    if (age == null ||
        age.isNegative ||
        age >
            Duration(
              seconds: child.locationStaleAfterSeconds.clamp(30, 86400),
            )) {
      return result(TrackingState.stale, 'Location Stale', last);
    }
    if (!verified ||
        report?['locationPermissionGranted'] != true ||
        report?['locationServicesEnabled'] != true ||
        report?['backgroundTrackingActive'] != true) {
      return result(
        TrackingState.unavailable,
        'Tracking temporarily unavailable',
        'Background tracking has not been verified. $last',
      );
    }
    if (location!.isMocked == true ||
        location.accuracy == null ||
        !location.accuracy!.isFinite ||
        location.accuracy! <= 0 ||
        location.accuracy! > 100) {
      return result(
        TrackingState.unavailable,
        'Location quality limited',
        'Accuracy is poor, unknown, or simulated. $last',
      );
    }
    return result(
      TrackingState.active,
      'Tracking Active',
      'Fresh device location · updated ${Formatters.relativeTime(captured)}',
    );
  }
}
