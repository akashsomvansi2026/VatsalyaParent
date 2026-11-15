import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/child.dart';
import '../../../core/utils/child_location_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({
    super.key,
    this.synchronized = true,
    this.lastUpdated,
    this.headerHeight = 80,
    required this.parent,
    required this.children,
    required this.selected,
    required this.isValid,
    required this.pointOf,
    required this.locating,
    required this.busy,
    required this.onMapReady,
    required this.onFit,
    required this.onLocate,
    required this.onChildTap,
    required this.onNearby,
    required this.onChooseChild,
  });
  final bool synchronized;
  final DateTime? lastUpdated;
  final double headerHeight;
  final Position? parent;
  final List<Child> children;
  final Child? selected;
  final bool Function(Child) isValid;
  final LatLng Function(Child) pointOf;
  final bool locating, busy;
  final VoidCallback onMapReady, onFit, onLocate, onNearby, onChooseChild;
  final ValueChanged<Child> onChildTap;
  @override
  State<GoogleMapView> createState() => GoogleMapViewState();
}

class GoogleMapViewState extends State<GoogleMapView>
    with SingleTickerProviderStateMixin {
  late final AnimationController movement;
  final starts = <MarkerId, LatLng>{};
  final startRotations = <MarkerId, double>{};
  Set<Marker> targets = {};
  GoogleMapController? controller;
  MapType type = MapType.normal;
  Set<Marker> markers = {};
  int revision = 0;
  final icons = <String, BitmapDescriptor>{};
  @override
  void initState() {
    super.initState();
    movement =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..addListener(() {
          if (!mounted) return;
          final t = Curves.easeInOut.transform(movement.value);
          setState(
            () => markers = targets.map((target) {
              final start = starts[target.markerId];
              if (start == null) return target;
              return target.copyWith(
                rotationParam: startRotations.containsKey(target.markerId)
                    ? (startRotations[target.markerId]! +
                              ((target.rotation -
                                              startRotations[target.markerId]! +
                                              540) %
                                          360 -
                                      180) *
                                  t) %
                          360
                    : target.rotation,
                positionParam: LatLng(
                  start.latitude +
                      (target.position.latitude - start.latitude) * t,
                  start.longitude +
                      (target.position.longitude - start.longitude) * t,
                ),
              );
            }).toSet(),
          );
        });
    updateMarkers();
  }

  @override
  void didUpdateWidget(covariant GoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateMarkers(previous: oldWidget.children);
  }

  @override
  void dispose() {
    revision++;
    movement.dispose();
    controller?.dispose();
    super.dispose();
  }

  Future<BitmapDescriptor> avatar(Child? child, bool selected) async {
    final key = child == null
        ? 'parent'
        : '${child.displayName}:${ChildLocationStatus.fromChild(child, synchronized: widget.synchronized).state}:$selected';
    if (icons[key] != null) return icons[key]!;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(72, 72);
    final radius = child == null ? 20.0 : 42.0 * (selected ? 1.15 : 1);
    if (selected) {
      canvas.drawCircle(
        center,
        radius + 7,
        Paint()
          ..color = AppColors.primary.withValues(alpha: .35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    final status = child == null
        ? null
        : ChildLocationStatus.fromChild(
            child,
            synchronized: widget.synchronized,
          );
    final statusColor = child == null
        ? Colors.blue.withValues(alpha: .18)
        : status?.isRecent == true
        ? Colors.green
        : status?.state == TrackingState.disabled
        ? Colors.redAccent
        : status?.state == TrackingState.offline
        ? Colors.grey
        : Colors.orange;
    canvas.drawCircle(center, radius + 7, Paint()..color = statusColor);
    canvas.drawCircle(center, radius + 4, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(30, 30),
          const Offset(110, 110),
          child == null
              ? [Colors.blue, Colors.blue]
              : [AppColors.primary, Colors.deepPurple],
        ),
    );
    if (child != null) {
      final name = child.displayName.trim();
      final text = TextPainter(
        text: TextSpan(
          text: name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
      final dot = center + Offset(radius * .7, radius * .7);
      canvas.drawCircle(dot, 11, Paint()..color = Colors.white);
      canvas.drawCircle(dot, 8, Paint()..color = statusColor);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(144, 144);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 72,
      height: 72,
    );
    image.dispose();
    picture.dispose();
    if (icons.length > 128) icons.clear();
    icons[key] = icon;
    return icon;
  }

  Future<BitmapDescriptor> bearingIcon() async {
    if (icons['bearing'] != null) return icons['bearing']!;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final arrow = Path()
      ..moveTo(72, 3)
      ..lineTo(62, 19)
      ..lineTo(82, 19)
      ..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.primary);
    final picture = recorder.endRecording();
    final image = await picture.toImage(144, 144);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 72,
      height: 72,
    );
    image.dispose();
    picture.dispose();
    icons['bearing'] = icon;
    return icon;
  }

  Future<void> updateMarkers({List<Child> previous = const []}) async {
    final current = ++revision;
    final result = <Marker>{};
    if (widget.parent != null) {
      result.add(
        Marker(
          markerId: const MarkerId('parent'),
          position: LatLng(widget.parent!.latitude, widget.parent!.longitude),
          icon: await avatar(null, false),
          anchor: const Offset(.5, .5),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    }
    for (final child in widget.children.where(widget.isValid)) {
      final icon = await avatar(child, child.id == widget.selected?.id);
      if (!mounted || revision != current) return;
      result.add(
        Marker(
          markerId: MarkerId('child-${child.id}'),
          position: widget.pointOf(child),
          icon: icon,
          anchor: const Offset(.5, .5),
          onTap: () => widget.onChildTap(child),
        ),
      );
    }
    for (final child in widget.children.where(widget.isValid)) {
      if (child.latestLocation!.hasReliableHeading &&
          ChildLocationStatus.fromChild(
            child,
            synchronized: widget.synchronized,
          ).isRecent) {
        result.add(
          Marker(
            markerId: MarkerId('bearing-${child.id}'),
            position: widget.pointOf(child),
            rotation: child.latestLocation!.heading!,
            icon: await bearingIcon(),
            flat: true,
            anchor: const Offset(.5, .5),
            onTap: () => widget.onChildTap(child),
          ),
        );
      }
    }
    if (!mounted || revision != current) return;
    movement.stop();
    starts.clear();
    startRotations.clear();
    for (final child in widget.children.where(widget.isValid)) {
      final old = previous.where((c) => c.id == child.id).firstOrNull;
      final oldFix = old?.latestLocation;
      final fix = child.latestLocation!;
      final elapsed = oldFix?.recordedAtUtc == null || fix.recordedAtUtc == null
          ? null
          : fix.recordedAtUtc!.difference(oldFix!.recordedAtUtc!);
      final id = MarkerId('child-${child.id}');
      final displayed = markers.where((m) => m.markerId == id).firstOrNull;
      if (displayed != null &&
          oldFix?.isValid == true &&
          elapsed != null &&
          elapsed > Duration.zero &&
          elapsed <= const Duration(seconds: 30) &&
          ChildLocationStatus.fromChild(
            child,
            synchronized: widget.synchronized,
          ).isRecent &&
          (fix.longitude - displayed.position.longitude).abs() < 180 &&
          Geolocator.distanceBetween(
                displayed.position.latitude,
                displayed.position.longitude,
                fix.latitude,
                fix.longitude,
              ) <=
              100) {
        starts[id] = displayed.position;
        final bearingId = MarkerId('bearing-${child.id}');
        final bearing = markers
            .where((m) => m.markerId == bearingId)
            .firstOrNull;
        if (bearing != null) {
          starts[bearingId] = bearing.position;
          startRotations[bearingId] = bearing.rotation;
        }
      }
    }
    targets = result;
    setState(
      () => markers = result
          .map(
            (m) => starts.containsKey(m.markerId)
                ? m.copyWith(
                    positionParam: starts[m.markerId],
                    rotationParam: startRotations[m.markerId],
                  )
                : m,
          )
          .toSet(),
    );
    if (starts.isNotEmpty) movement.forward(from: 0);
  }

  Future<void> fit(List<LatLng> points) async {
    if (controller == null || points.isEmpty) return;
    final south = points.map((p) => p.latitude).reduce(math.min);
    final north = points.map((p) => p.latitude).reduce(math.max);
    final west = points.map((p) => p.longitude).reduce(math.min);
    final east = points.map((p) => p.longitude).reduce(math.max);
    try {
      await controller!.animateCamera(
        north - south < .0001 && east - west < .0001
            ? CameraUpdate.newLatLngZoom(points.first, 15)
            : CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east),
                ),
                64,
              ),
      );
    } catch (_) {
      /* Controller may detach during navigation. */
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height:
        (MediaQuery.sizeOf(context).width * .86 +
                MediaQuery.paddingOf(context).top)
            .clamp(widget.headerHeight + 275, 540.0),
    child: Stack(
      children: [
        Positioned.fill(
          child:
              defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS
              ? GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(26.8925, 80.9388), // Aliganj, Lucknow
                    zoom: 14,
                  ),
                  mapType: type,
                  markers: markers,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.paddingOf(context).top +
                        widget.headerHeight +
                        84,
                    bottom: 80,
                  ),
                  onMapCreated: (value) {
                    controller = value;
                    widget.onMapReady();
                  },
                  circles: {
                    for (final child in widget.children.where(widget.isValid))
                      if (child.latestLocation!.accuracy != null &&
                          child.latestLocation!.accuracy!.isFinite &&
                          child.latestLocation!.accuracy! > 0 &&
                          child.latestLocation!.accuracy! <= 10000)
                        Circle(
                          circleId: CircleId('accuracy-${child.id}'),
                          center: widget.pointOf(child),
                          radius: child.latestLocation!.accuracy!,
                          fillColor: Colors.blue.withValues(alpha: .08),
                          strokeColor: Colors.blue.withValues(alpha: .25),
                          strokeWidth: 1,
                        ),
                  },
                )
              : const ColoredBox(
                  color: Color(0xFFE8EDF3),
                  child: Center(
                    child: Text('Google Maps is available on Android and iOS.'),
                  ),
                ),
        ),
        Positioned(
          left: 16,
          bottom: 20,
          child: Row(
            children: [
              _MapFloatingButton(
                icon: Icons.people_alt_outlined,
                tooltip: 'Show family on map',
                onPressed: widget.onFit,
              ),
              const SizedBox(width: 8),
              _MapFloatingButton(
                icon: Icons.near_me_outlined,
                tooltip: 'Nearby places',
                onPressed: widget.onNearby,
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + widget.headerHeight + 18,
          left: 76,
          right: 76,
          child: Builder(
            builder: (context) {
              final fix = widget.selected?.latestLocation;
              final status = widget.selected == null
                  ? null
                  : ChildLocationStatus.fromChild(
                      widget.selected!,
                      synchronized: widget.synchronized,
                    );
              final live = status?.isRecent == true;
              return Material(
                color: Colors.white,
                elevation: 3,
                shadowColor: const Color(0x22000000),
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: widget.onChooseChild,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 11,
                          color: live
                              ? const Color(0xFF00B978)
                              : const Color(0xFFFF9B36),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                live
                                    ? 'Live Location'
                                    : status?.label ?? 'Family Location',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                fix != null
                                    ? Formatters.relativeTime(fix.recordedAtUtc)
                                    : widget.lastUpdated != null
                                    ? 'Data updated ${Formatters.relativeTime(widget.lastUpdated)}'
                                    : 'Waiting for location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF626878),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFF626878),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          top: MediaQuery.paddingOf(context).top + widget.headerHeight + 136,
          child: Material(
            color: Colors.white,
            elevation: 3,
            shadowColor: const Color(0x22000000),
            borderRadius: BorderRadius.circular(28),
            child: Column(
              children: [
                IconButton(
                  tooltip: 'Zoom in',
                  onPressed: () =>
                      controller?.animateCamera(CameraUpdate.zoomIn()),
                  icon: const Icon(Icons.add, color: Color(0xFF626878)),
                ),
                IconButton(
                  tooltip: 'Zoom out',
                  onPressed: () =>
                      controller?.animateCamera(CameraUpdate.zoomOut()),
                  icon: const Icon(Icons.remove, color: Color(0xFF626878)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + widget.headerHeight + 18,
          left: 16,
          child: _MapFloatingButton(
            icon: Icons.layers_rounded,
            iconColor: const Color(0xFFFF5715),
            tooltip: 'Map style',
            onPressed: () {
              setState(() {
                if (type == MapType.normal) {
                  type = MapType.satellite;
                } else if (type == MapType.satellite) {
                  type = MapType.terrain;
                } else {
                  type = MapType.normal;
                }
              });
            },
          ),
        ),
        Positioned(
          right: 16,
          top: MediaQuery.paddingOf(context).top + widget.headerHeight + 74,
          child: _MapFloatingButton(
            icon: Icons.my_location_rounded,
            iconColor: const Color(0xFFFF5722),
            tooltip: 'My location',
            busy: widget.locating,
            onPressed: widget.onLocate,
          ),
        ),
      ],
    ),
  );
}

class _MapFloatingButton extends StatelessWidget {
  const _MapFloatingButton({
    required this.icon,
    required this.onPressed,
    this.iconColor = const Color(0xFF1E293B),
    this.tooltip,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color iconColor;
  final String? tooltip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Tooltip(
          message: tooltip ?? '',
          child: InkWell(
            onTap: busy ? null : onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF5722),
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}
