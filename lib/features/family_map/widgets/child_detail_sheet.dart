import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/child_location_status.dart';
import '../../../data/models/child.dart';

class ChildTrackingDetails extends StatelessWidget {
  const ChildTrackingDetails({
    super.key,
    required this.child,
    this.synchronized = true,
  });
  final Child child;
  final bool synchronized;
  @override
  Widget build(BuildContext context) {
    final status = ChildLocationStatus.fromChild(
      child,
      synchronized: synchronized,
    );
    final fix = child.latestLocation;
    final battery = child.batteryLevel ?? fix?.batteryLevel;
    final report = child.trackingStatus;
    String capability(String key) => report?[key] == true
        ? 'Yes'
        : report?[key] == false
        ? 'No'
        : 'Not reported';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .65,
      minChildSize: .4,
      maxChildSize: .9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: ClipOval(
                  child: child.avatarUrl == null
                      ? const Icon(Icons.child_care, size: 36)
                      : Image.network(
                          child.avatarUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) =>
                              const Icon(Icons.child_care, size: 36),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  child.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            synchronized ? status.label : 'Live connection unavailable',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(status.detail),
          if (!synchronized)
            const Text(
              'Showing last synchronized information; status is not verified live.',
            ),
          const Divider(height: 32),
          Text(
            'Device: ${child.deviceName ?? child.deviceModel ?? "Paired device"}',
          ),
          Text(
            'Device status: ${status.state == TrackingState.offline
                ? "Offline"
                : child.isOnline
                ? "Online at last sync"
                : "Offline"}',
          ),
          Text(
            'Last contact: ${child.lastSeenAtUtc?.toLocal().toString() ?? "Not reported"}',
          ),
          Text(
            'Battery: ${battery != null && battery >= 0 && battery <= 100 ? "$battery%" : "Not reported"}',
          ),
          const SizedBox(height: 16),
          Text(
            status.isRecent && synchronized
                ? 'Latest reported position'
                : 'Last known position',
          ),
          Text(
            status.hasLocation
                ? '${fix!.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)}'
                : 'Unavailable',
          ),
          Text(
            'Location update: ${fix?.recordedAtUtc?.toLocal().toString() ?? "Unknown"}',
          ),
          Text(
            fix?.accuracy != null &&
                    fix!.accuracy!.isFinite &&
                    fix.accuracy! > 0
                ? 'Accuracy: ±${fix.accuracy!.round()} m${fix.accuracy! > 100 ? " (poor accuracy)" : ""}'
                : 'Accuracy: unknown',
          ),
          if (fix?.isMocked == true)
            const Text('Device reports a simulated location.'),
          const Divider(height: 32),
          Text(
            'Location permission: ${capability("locationPermissionGranted")}',
          ),
          Text('Location services: ${capability("locationServicesEnabled")}'),
          Text(
            'Background location permission: ${capability("backgroundLocationPermissionGranted")}',
          ),
          Text(
            'Background tracking running: ${capability("backgroundTrackingActive")}',
          ),
          Text('Device checks: ${report?["reportedAtUtc"] ?? "Not reported"}'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/child/${child.id}');
            },
            icon: const Icon(Icons.person_outline),
            label: const Text('View full profile'),
          ),
        ],
      ),
    );
  }
}
