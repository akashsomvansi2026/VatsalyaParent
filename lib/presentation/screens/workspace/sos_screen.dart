import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_views.dart';
import '../../../data/models/sos_event.dart';
import '../../providers/infra_providers.dart';
import '../../providers/session_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'workspace_widgets.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});
  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  List<SosEvent> events = [];
  String? error;
  bool loading = true, busy = false, activeOnly = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final rows = await ref.read(parentsRepositoryProvider).getSosEvents();
      if (mounted) {
        setState(() {
          events = rows;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resolve(SosEvent event) async {
    if (!await confirmAction(
          context,
          'Resolve SOS?',
          'Mark the alert from ${event.childName} as resolved?',
        ) ||
        !mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(parentsRepositoryProvider).resolveSos(event.id);
      if (!mounted) return;
      ref.invalidate(dashboardProvider);
      await load();
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = events.where((e) => !activeOnly || e.isActive).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS alerts & history'),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const LoadingView(message: 'Loading SOS history…')
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.sosTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.sos.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          error!,
                          style: const TextStyle(color: AppColors.sos, fontSize: 13),
                        ),
                      ),
                    ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text(
                        'Show active alerts only',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      value: activeOnly,
                      onChanged: (v) => setState(() => activeOnly = v),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: EmptyState(
                        icon: Icons.shield_outlined,
                        title: 'No SOS alerts reported',
                        subtitle: 'No emergency alerts match your current filter.',
                      ),
                    ),
                  for (final event in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        color: event.isActive ? const Color(0xFFFFFBFB) : Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: event.isActive ? AppColors.sosTint : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    event.isActive
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    size: 18,
                                    color: event.isActive ? AppColors.sos : AppColors.muted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.childName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      Text(
                                        Formatters.relativeTime(event.triggeredAtUtc),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: event.isActive ? AppColors.sosTint : AppColors.onlineTint,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: event.isActive
                                          ? AppColors.sos.withValues(alpha: 0.3)
                                          : AppColors.online.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    event.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: event.isActive ? AppColors.sos : AppColors.onlineDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              event.message ?? event.address ?? 'SOS alert triggered',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 14, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.latitude.toStringAsFixed(4)}, ${event.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                            if (event.isActive &&
                                ref
                                        .watch(sessionProvider)
                                        .parent
                                        ?.can('control.update') ==
                                    true) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: busy ? null : () => resolve(event),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.sos,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size(0, 42),
                                  ),
                                  child: const Text('Mark resolved'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
