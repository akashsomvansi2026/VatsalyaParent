import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/battery_bar.dart';
import '../../../../../core/widgets/dialogs.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../core/widgets/child_location_overview.dart';
import '../../../../../data/models/child.dart';
import '../../../../../data/models/sos_event.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/session_provider.dart';

/// Red SOS alert banner listing active events (portal's SOS banner) with a
/// per-event "Mark resolved" action.
class SosBanner extends ConsumerWidget {
  const SosBanner({super.key, required this.events});

  final List<SosEvent> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) return const SizedBox.shrink();

    final active = events.where((e) => e.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sosDark, AppColors.sos],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.sos.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'SOS Alert',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...active.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.childName} — ${event.message ?? event.address ?? 'SOS Alert!'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed:
                          ref
                                  .watch(sessionProvider)
                                  .parent
                                  ?.can('control.update') ==
                              true
                          ? () => _confirmResolve(context, ref, event)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Mark resolved'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResolve(
    BuildContext context,
    WidgetRef ref,
    SosEvent event,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Resolve SOS?',
      message: 'Mark the SOS alert from ${event.childName} as resolved?',
      confirmLabel: 'Resolve',
    );
    if (!confirmed) return;
    try {
      await ref.read(dashboardProvider.notifier).resolveSos(event.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

/// One child card in the dashboard grid.
class ChildCard extends ConsumerWidget {
  const ChildCard({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineColor = child.isOnline ? AppColors.online : AppColors.offline;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                initial: child.displayName.isNotEmpty
                    ? child.displayName[0].toUpperCase()
                    : '?',
                online: child.isOnline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    StatusPill(
                      child.isOnline ? 'Online' : 'Offline',
                      color: onlineColor,
                    ),
                  ],
                ),
              ),
              if (ref.watch(sessionProvider).parent?.can('child.delete') ==
                  true)
                _DeleteButton(child: child),
            ],
          ),
          const SizedBox(height: 12),
          ChildLocationOverview(child: child, compact: true),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Seen ${Formatters.relativeTime(child.lastSeenAtUtc)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BatteryBar(battery: child.batteryLevel),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.online});

  final String initial;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: online
                  ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                  : [const Color(0xFFF5F0EA), const Color(0xFFE5DDD5)],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: online ? AppColors.online : AppColors.cardBorder,
              width: 2,
            ),
            boxShadow: online
                ? [
                    BoxShadow(
                      color: AppColors.online.withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            initial,
            style: TextStyle(
              color: online ? AppColors.onlineDark : AppColors.offline,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: online ? AppColors.online : AppColors.offline,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _confirmDelete(context, ref),
      icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
      tooltip: 'Remove ${child.displayName}',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: const EdgeInsets.all(4),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove ${child.displayName}?',
      message:
          'The child device will be immediately notified and reset to the pairing screen. This cannot be undone.',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(dashboardProvider.notifier).deleteChild(child.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
