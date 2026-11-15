import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/places_service.dart';
import 'widgets/nearby_places_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:vrajrani_tech_solution/features/family_map/widgets/child_detail_sheet.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/child_selector_sheet.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/family_glance_card.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/family_map_app_bar.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/family_members_section.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/family_summary_strip.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/google_map_view.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/nearby_banner_card.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/quick_action_grid.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/selected_child_panel.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/skeleton_loader.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_content.dart';
import '../../data/models/child.dart';
import '../../core/utils/child_location_status.dart';
import '../../data/remote/realtime_gateway.dart';
import '../../presentation/providers/infra_providers.dart';
import '../../presentation/providers/session_provider.dart';
import '../../presentation/widgets/safety_summary_card.dart';
import 'providers/family_map_provider.dart';

class FamilyMapScreen extends ConsumerStatefulWidget {
  const FamilyMapScreen({super.key});

  @override
  ConsumerState<FamilyMapScreen> createState() => _FamilyMapScreenState();
}

class _FamilyMapScreenState extends ConsumerState<FamilyMapScreen>
    with WidgetsBindingObserver {
  final map = GlobalKey<GoogleMapViewState>();
  final details = ValueNotifier<Child?>(null);
  bool foreground = true;
  FamilyMapController get controller => ref.read(familyMapProvider.notifier);
  List<Child> get children => ref.read(familyMapProvider).children;
  Child? get selected => ref.read(familyMapProvider).selected;
  set selected(Child? value) => controller.selected = value;
  Position? get parent => ref.read(familyMapProvider).parent;
  set parent(Position? value) => controller.parent = value;
  String? get error => ref.read(familyMapProvider).error;
  DateTime? get cachedAtUtc => ref.read(familyMapProvider).cachedAtUtc;
  bool get busy => ref.read(familyMapProvider).busy;
  bool get locating => ref.read(familyMapProvider).locating;
  set locating(bool value) => controller.locating = value;
  DateTime? get lastSynchronizedAt =>
      ref.read(familyMapProvider).lastSynchronizedAt;
  int get dataRevision => ref.read(familyMapProvider).dataRevision;
  int refreshTicks = 0;
  Timer? timer;
  bool get synchronized => controller.synchronized;

  bool valid(Child c) =>
      c.latestLocation?.isDisplayableAt(DateTime.now().toUtc()) == true;

  LatLng point(Child c) =>
      LatLng(c.latestLocation!.latitude, c.latestLocation!.longitude);

  List<LatLng> get points => [
    if (parent != null) LatLng(parent!.latitude, parent!.longitude),
    for (final c in children)
      if (valid(c)) point(c),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(load);
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!foreground) return;
      setState(() {}); // Expire heartbeat/status even when no frame changes.
      details.value = details.value?.copyWith();
      if (++refreshTicks % 4 == 0 ||
          !ref.read(realtimeGatewayProvider).isConnected) {
        load();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    details.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) load();
  }

  void onEvent(RealtimeEvent event) {
    if (!mounted || !foreground) return;
    controller.onEvent(event);
    details.value = children
        .where((c) => c.id == details.value?.id)
        .firstOrNull
        ?.copyWith();
  }

  void fit([List<LatLng>? locations]) =>
      map.currentState?.fit(locations ?? points);

  Future<void> load() async {
    final firstLoad = children.isEmpty;
    await controller.load();
    if (!mounted) return;
    if (firstLoad) fit();
    details.value = children
        .where((c) => c.id == details.value?.id)
        .firstOrNull
        ?.copyWith();
  }

  Future<void> locate() async {
    if (locating) return;
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on your phone’s location service.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          'Enable location permission in phone settings to show your position.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() => parent = position);
      if (selected != null) {
        await select(selected);
      } else {
        fit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> select(Child? child) async {
    setState(() => selected = child);
    if (child != null && valid(child)) fit([point(child)]);
  }

  Future<void> chooseChild() async {
    if (children.isEmpty) {
      final account = ref.read(sessionProvider).parent;
      if (account?.can('child.create') == true) {
        context.push('/family/children?create=true');
      } else if (account?.can('device.add') == true) {
        context.push('/pairing');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ask your administrator to add a child to your account.',
            ),
          ),
        );
      }
      return;
    }
    final picked = await showChildSelectorSheet(
      context: context,
      children: children,
      selected: selected,
      synchronized: synchronized,
      isValid: valid,
    );
    if (picked != null) await select(picked);
  }

  void openChildDetails(Child child) {
    details.value = child;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ValueListenableBuilder<Child?>(
        valueListenable: details,
        builder: (context, current, _) => current == null
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Child no longer available.'),
              )
            : ChildTrackingDetails(child: current, synchronized: synchronized),
      ),
    );
  }

  Future<void> openNearby() async {
    if (parent == null) await locate();
    if (!mounted || parent == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NearbyPlacesSheet(
        origin: LatLng(parent!.latitude, parent!.longitude),
        service: ref.read(placesServiceProvider),
        onPlace: (place) {
          Navigator.pop(context);
          fit([place.position]);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${place.name} · ${place.address}')),
          );
        },
      ),
    );
  }

  String distanceLabel(double metres) => metres < 1000
      ? '${metres.round()} m'
      : '${(metres / 1000).toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeStreamProvider, (_, next) {
      final event = next.value;
      if (event != null) onEvent(event);
    });
    ref.watch(familyMapProvider);
    final account = ref.watch(sessionProvider).parent;
    final onlineCount = children.where((c) => c.isOnline).length;
    final toolbarHeight = (MediaQuery.textScalerOf(context).scale(23) + 57)
        .clamp(80.0, 140.0);
    final canAddDevice = account?.can('device.add') == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBodyBehindAppBar: true,
      appBar: FamilyMapAppBar(
        height: toolbarHeight,
        canAddDevice: canAddDevice,
        busy: busy,
        onRefresh: load,
        onPairDevice: () => context.push('/pairing'),
        locationName: selected?.displayName ?? 'Family location',
        onNotifications: () => context.push('/records/notification'),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF5722),
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            GoogleMapView(
              key: map,
              headerHeight: toolbarHeight,
              lastUpdated: lastSynchronizedAt,
              parent: parent,
              children: children,
              synchronized: synchronized,
              selected: selected,
              isValid: valid,
              pointOf: point,
              locating: locating,
              busy: busy,
              onMapReady: () {
                fit();
              },
              onFit: () => fit(),
              onLocate: locate,
              onChildTap: (child) async {
                if (!mounted) return;
                await select(child);
                if (mounted && selected?.id == child.id) {
                  openChildDetails(child);
                }
              },
              onNearby: openNearby,
              onChooseChild: chooseChild,
            ),
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: NearbyBannerCard(onTap: chooseChild),
                  ),
                  const SizedBox(height: 12),
                  FamilySummaryStrip(
                    onlineCount: onlineCount,
                    totalCount: children.length,
                    hasParentLocation:
                        parent != null &&
                        DateTime.now().difference(parent!.timestamp).abs() <=
                            const Duration(minutes: 2),
                    cachedAtUtc: cachedAtUtc,
                    synchronized: synchronized,
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  QuickActionGrid(
                    account: account,
                    onAddChild: chooseChild,
                    onOpenChildren: () => context.push('/family/children'),
                    onOpenPairing: () => context.push('/pairing'),
                    onOpenSos: () => context.push('/sos'),
                  ),
                  const SizedBox(height: 14),
                  FamilyGlanceCard(onTap: chooseChild),
                  if (busy && children.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SkeletonLoader(),
                    ),
                  if (selected != null) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SelectedChildPanel(
                        child: selected!,
                        synchronized: synchronized,
                        isValid: valid(selected!),
                        parent: parent,
                        routingBusy: false,
                        routeError: null,
                        distanceLabel: ChildLocationStatus.fromChild(
                          selected!,
                          synchronized: synchronized,
                        ).detail,
                        onTap: () => openChildDetails(selected!),
                        onLocate: locate,
                      ),
                    ),
                    if (account?.can('control.view') == true)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: SafetySummaryCard(
                          key: ValueKey(selected!.id),
                          childId: selected!.id,
                        ),
                      ),
                  ],
                  if (children.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    FamilyMembersSection(
                      children: children,
                      synchronized: synchronized,
                      selected: selected,
                      onSelect: select,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
