import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/status_views.dart';
import '../../../../../data/models/location_point.dart';
import '../../../../../data/models/child.dart';
import '../../../../../core/widgets/child_location_overview.dart';
import '../../../../../data/models/sos_event.dart';

/// Google map with path polyline, latest position marker and
/// active SOS markers (mirrors the portal's Leaflet map tab).
class MapTab extends StatelessWidget {
  const MapTab({
    super.key,
    required this.child,
    required this.locations,
    required this.activeSos,
  });

  final Child child;
  final List<LocationPoint> locations;
  final List<SosEvent> activeSos;

  LocationPoint? get _latest =>
      locations.isEmpty ? child.latestLocation : locations.last;

  @override
  Widget build(BuildContext context) {
    if (_latest == null) {
      return const EmptyState(
        icon: Icons.place_outlined,
        title: 'No location yet',
        subtitle:
            'Once the child device reports its location, you will see it here on the map.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 320,
            child: _MapView(
              locations: locations,
              latest: _latest!,
              activeSos: activeSos.where((e) => e.isActive).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ChildLocationOverview(child: child.copyWith(latestLocation: _latest)),
        const SizedBox(height: 16),
        AppSectionTitle('SOS history'),
        const SizedBox(height: 8),
        _SosHistoryList(events: activeSos),
      ],
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView({
    required this.locations,
    required this.latest,
    required this.activeSos,
  });

  final List<LocationPoint> locations;
  final LocationPoint latest;
  final List<SosEvent> activeSos;

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  @override
  Widget build(BuildContext context) => GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(widget.latest.latitude, widget.latest.longitude),
      zoom: 15,
    ),
    markers: {
      Marker(
        markerId: const MarkerId('latest'),
        position: LatLng(widget.latest.latitude, widget.latest.longitude),
      ),
      for (final event in widget.activeSos)
        Marker(
          markerId: MarkerId('sos-${event.id}'),
          position: LatLng(event.latitude, event.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'SOS'),
        ),
    },
    polylines: {
      Polyline(
        polylineId: const PolylineId('history'),
        points: widget.locations
            .map((l) => LatLng(l.latitude, l.longitude))
            .toList(),
        color: AppColors.primary,
        width: 5,
      ),
    },
  );
}

class _SosHistoryList extends StatelessWidget {
  const _SosHistoryList({required this.events});

  final List<SosEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(16),
        child: Text(
          'No SOS alerts for this child.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    return Column(
      children: events
          .map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      event.isActive
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: event.isActive
                          ? AppColors.sos
                          : AppColors.onlineDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.message ?? 'SOS Alert!',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.address ?? 'Emergency Location',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.dateTime(event.triggeredAtUtc),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppStatusPill(
                      event.isActive ? 'Active' : 'Resolved',
                      color: event.isActive
                          ? AppColors.sos
                          : AppColors.onlineDark,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class AppStatusPill extends StatelessWidget {
  const AppStatusPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
