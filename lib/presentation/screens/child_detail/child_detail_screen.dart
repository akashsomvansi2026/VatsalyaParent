import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/battery_bar.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/status_views.dart';
import '../../../core/widgets/child_location_overview.dart';
import '../../../data/models/child.dart';
import '../../../data/models/sos_event.dart';
import '../../../data/remote/realtime_gateway.dart';
import '../../providers/child_detail_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/infra_providers.dart';
import '../../widgets/provisioning_sheet.dart';
import '../../widgets/safety_summary_card.dart';
import 'tabs/apps_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/usage_tab.dart';
import 'widgets/lock_settings_sheet.dart';

/// Per-child supervision hub (mirrors `/children/:id`): live map, app policy
/// and screen-time usage.
class ChildDetailScreen extends ConsumerStatefulWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final int childId;

  @override
  ConsumerState<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends ConsumerState<ChildDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(childDetailProvider(widget.childId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Real-time dispatch for this child (portal's ChildDetail behavior).
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeStreamProvider, (prev, next) {
      final event = next.value;
      if (event == null) return;
      ref
          .read(childDetailProvider(widget.childId).notifier)
          .onRealtimeEvent(event);
    });

    final state = ref.watch(childDetailProvider(widget.childId));
    final freshChild = state.child;

    if (state.error != null &&
        state.locations.isEmpty &&
        state.apps.isEmpty &&
        !state.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context, state.child?.displayName ?? 'Child'),
        body: ErrorView(
          message: state.error!,
          onRetry: () =>
              ref.read(childDetailProvider(widget.childId).notifier).load(),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, state.child?.displayName ?? 'Child'),
      body: _buildBody(context, state, freshChild),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        tooltip: 'Back to dashboard',
      ),
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(childDetailProvider(widget.childId).notifier).refresh(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ChildDetailState state,
    Child? child,
  ) {
    if (child == null) {
      return state.isLoading
          ? const LoadingView(message: 'Loading child…')
          : const EmptyState(
              icon: Icons.child_care_outlined,
              title: 'Child not found',
              subtitle: 'This child may have been unpaired from your account.',
            );
    }

    final activeSos = state.sosEvents.where((e) => e.isActive).toList();
    final deviceLine = [
      if (child.deviceName?.isNotEmpty == true) child.deviceName!,
      if (child.deviceModel?.isNotEmpty == true) child.deviceModel!,
      if (child.osVersion?.isNotEmpty == true) child.osVersion!,
    ].join(' · ');

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(childDetailProvider(widget.childId).notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(child, deviceLine, actionLoading: state.actionLoading),
          const SizedBox(height: 16),
          SafetySummaryCard(childId: widget.childId),
          const SizedBox(height: 16),
          if (activeSos.isNotEmpty) ...[
            _activeSosCard(activeSos),
            const SizedBox(height: 16),
          ],
          _TabSelector(
            selected: state.tab,
            available: {
              if (ref.watch(sessionProvider).parent?.can('location.view') ==
                  true)
                ChildTab.map,
              if (ref.watch(sessionProvider).parent?.can('app.view') == true)
                ChildTab.apps,
              if (ref.watch(sessionProvider).parent?.can('screen_time.view') ==
                  true)
                ChildTab.usage,
            },
            onSelected: (tab) => ref
                .read(childDetailProvider(widget.childId).notifier)
                .selectTab(tab),
          ),
          const SizedBox(height: 16),
          if (ref.watch(sessionProvider).parent?.can(switch (state.tab) {
                ChildTab.map => 'location.view',
                ChildTab.apps => 'app.view',
                ChildTab.usage => 'screen_time.view',
              }) ==
              true)
            switch (state.tab) {
              ChildTab.map => MapTab(
                child: child,
                locations: state.locations,
                activeSos: state.sosEvents,
              ),
              ChildTab.apps => AppsTab(childId: widget.childId),
              ChildTab.usage => UsageTab(childId: widget.childId),
            },
        ],
      ),
    );
  }

  Widget _headerCard(
    Child child,
    String deviceLine, {
    required bool actionLoading,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            (child.isOnline
                                    ? AppColors.online
                                    : AppColors.offline)
                                .withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: child.isOnline
                              ? AppColors.online
                              : AppColors.offline,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        child.displayName.isNotEmpty
                            ? child.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.displayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusPill(
                            child.isOnline ? 'Online' : 'Offline',
                            color: child.isOnline
                                ? AppColors.online
                                : AppColors.offline,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BatteryBar(battery: child.batteryLevel),
          const SizedBox(height: 8),
          Text(
            'Seen ${Formatters.relativeTime(child.lastSeenAtUtc)}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          if (deviceLine.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              deviceLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          ChildLocationOverview(child: child, compact: true),
          if (!child.protectionEnabled) ...[
            const SizedBox(height: 8),
            const Text('Attention: safety protection is not enabled.',
                style: TextStyle(color: AppColors.sos,
                    fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (ref.watch(sessionProvider).parent?.can('control.update') ==
                  true)
                _ActionButton(
                  icon: Icons.gps_fixed,
                  label: child.trackingEnabled
                      ? 'Tracking: on'
                      : 'Tracking: off',
                  primary: child.trackingEnabled,
                  onPressed: actionLoading ? null : () => _toggleTracking(),
                ),
              if (ref.watch(sessionProvider).parent?.can('control.update') ==
                  true)
                _ActionButton(
                  icon: child.protectionEnabled
                      ? Icons.shield
                      : Icons.shield_outlined,
                  label: actionLoading
                      ? '…'
                      : child.protectionEnabled
                      ? 'Tamper: Locked'
                      : 'Tamper: Allowed',
                  primary: child.protectionEnabled,
                  onPressed: actionLoading
                      ? null
                      : () => _toggleProtection(child),
                ),
              if (ref.watch(sessionProvider).parent?.can('web_filter.view') ==
                  true)
                _ActionButton(
                  icon: Icons.public,
                  label: 'Content filter',
                  onPressed: () =>
                      context.push('/child/${widget.childId}/content-filter'),
                ),
              if (ref.watch(sessionProvider).parent?.can('control.view') ==
                  true)
                _ActionButton(
                  icon: Icons.verified_user_outlined,
                  label: 'Device approvals',
                  onPressed: () =>
                      context.push('/child/${widget.childId}/safety'),
                ),
              _ActionButton(
                icon: Icons.help_outline,
                label: 'Setup guide',
                onPressed: () => showProvisioningSheet(context, childId: widget.childId),
              ),
              if (ref.watch(sessionProvider).parent?.can('control.update') ==
                  true)
                _ActionButton(
                  icon: Icons.lock_reset,
                  label: 'Lock screen',
                  onPressed: () =>
                      showLockSettingsSheet(context, widget.childId),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeSosCard(List<SosEvent> activeSos) {
    final lines = activeSos
        .map((e) => e.message ?? e.address ?? 'SOS Alert!')
        .toSet()
        .toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sosDark, AppColors.sos],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚨 SOS active on this device',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lines.isEmpty
                ? '${activeSos.length} alert(s) active'
                : lines.take(2).join('\n'),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTracking() async {
    final notifier = ref.read(childDetailProvider(widget.childId).notifier);
    final current =
        ref.read(childDetailProvider(widget.childId)).child?.trackingEnabled ??
        false;
    try {
      await notifier.setTracking(!current);
    } on AppException catch (error) {
      if (mounted) showAppMessage(context, error.message, isError: true);
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Could not update tracking.', isError: true);
      }
    }
  }

  Future<void> _toggleProtection(Child child) async {
    final notifier = ref.read(childDetailProvider(widget.childId).notifier);
    final enabling = !child.protectionEnabled;
    final confirmed = await showConfirmDialog(
      context,
      title: enabling ? 'Enable tamper protection?' : 'Allow tampering?',
      message: enabling
          ? 'The device will block uninstall, factory reset and guest mode. The child cannot disable this without the Parent PIN.'
          : 'Temporarily allow uninstalling the app, factory reset and guest mode on the child device.',
      confirmLabel: enabling ? 'Lock' : 'Allow',
      danger: !enabling,
    );
    if (!confirmed) return;
    try {
      await notifier.setProtection(enabling);
    } on AppException catch (error) {
      if (mounted) showAppMessage(context, error.message, isError: true);
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Could not update protection.', isError: true);
      }
    }
  }
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({
    required this.selected,
    required this.onSelected,
    required this.available,
  });
  final Set<ChildTab> available;

  final ChildTab selected;
  final ValueChanged<ChildTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFF4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final (tab, label, icon) in (const [
            (ChildTab.map, 'Location', Icons.map_outlined),
            (ChildTab.apps, 'Apps', Icons.apps_outlined),
            (ChildTab.usage, 'Usage', Icons.timelapse_outlined),
          ]).where((entry) => available.contains(entry.$1)))
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selected == tab ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected == tab
                      ? const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelected(tab),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: selected == tab
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected == tab
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selected == tab
                                  ? AppColors.text
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? Colors.white : AppColors.primary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: foreground),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: primary ? AppColors.primary : Colors.white,
        side: BorderSide(
          color: primary ? AppColors.primary : AppColors.cardBorder,
          width: 1.2,
        ),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

