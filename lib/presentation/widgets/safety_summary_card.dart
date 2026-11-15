import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/infra_providers.dart';
import '../providers/session_provider.dart';

/// A report-based summary: it never treats an old device report as live state.
class SafetySummaryCard extends ConsumerStatefulWidget {
  const SafetySummaryCard({super.key, required this.childId});
  final int childId;

  @override
  ConsumerState<SafetySummaryCard> createState() => _SafetySummaryCardState();
}

class _SafetySummaryCardState extends ConsumerState<SafetySummaryCard> {
  Map<String, dynamic>? report;
  DateTime? reportedAt;
  int pendingCount = 0;
  bool loading = true;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => load());
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (ref.read(sessionProvider).parent?.can('control.view') != true) return;
    try {
      final data = await ref.read(workspaceRepositoryProvider)
          .get('/api/parent/children/${widget.childId}/safety');
      if (!mounted) return;
      final reports = (data['reports'] as List? ?? [])
          .whereType<Map>()
          .toList();
      reports.sort((a, b) => (b['reportedAtUtc'] ?? '').toString()
          .compareTo((a['reportedAtUtc'] ?? '').toString()));
      final latest = reports.firstOrNull;
      setState(() {
        report = latest?['data'] is Map
            ? Map<String, dynamic>.from(latest!['data'] as Map)
            : null;
        reportedAt = DateTime.tryParse(
            latest?['reportedAtUtc']?.toString() ?? '');
        pendingCount = (data['requests'] as List? ?? [])
            .whereType<Map>()
            .where((row) => row['status'] == 'Pending')
            .length;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(sessionProvider).parent?.can('control.view') != true) {
      return const SizedBox.shrink();
    }
    final age = reportedAt == null
        ? null
        : DateTime.now().toUtc().difference(reportedAt!.toUtc());
    final recent = age != null && !age.isNegative &&
        age <= const Duration(minutes: 5);
    final critical = report?['airplaneModeEnabled'] == true ||
        report?['locationEnabled'] == false;
    final title = report == null
        ? 'Safety status not verified'
        : critical
            ? 'Safety setting needs attention'
            : recent
                ? 'Recent device report'
                : 'Device report is out of date';
    final color = critical ? AppColors.sos :
        recent ? AppColors.onlineDark : AppColors.warning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(critical ? Icons.warning_amber : Icons.shield_outlined,
                  color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title,
                  style: TextStyle(fontWeight: FontWeight.w700,
                      color: color, fontSize: 16))),
            ]),
            const SizedBox(height: 6),
            if (loading) const LinearProgressIndicator()
            else if (report == null)
              const Text('No device status report is available yet.')
            else ...[
              Text('Last reported ${Formatters.relativeTime(reportedAt)} · status may have changed since then.'),
              Text('Location: ${_flag(report!['locationEnabled'])} · Airplane mode: ${_flag(report!['airplaneModeEnabled'])}'),
              Text('Managed protection: ${report!['deviceOwner'] == true ? 'Device Owner reported' : 'Not reported as Device Owner'}'),
            ],
            if (pendingCount > 0)
              Text('$pendingCount approval request${pendingCount == 1 ? '' : 's'} awaiting review',
                  style: const TextStyle(color: AppColors.warning,
                      fontWeight: FontWeight.w700)),
            TextButton.icon(
              onPressed: () => context.push('/child/${widget.childId}/safety'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Device details & approvals'),
            ),
          ],
        ),
      ),
    );
  }

  String _flag(Object? value) => value == true
      ? 'On at last report'
      : value == false
          ? 'Off at last report'
          : 'Unknown';
}
