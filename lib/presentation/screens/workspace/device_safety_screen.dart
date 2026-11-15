import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/infra_providers.dart';
import '../../providers/session_provider.dart';
import 'workspace_widgets.dart';
import '../../widgets/managed_device_commands_card.dart';

class DeviceSafetyScreen extends ConsumerStatefulWidget {
  const DeviceSafetyScreen({super.key, required this.childId});
  final int childId;
  @override
  ConsumerState<DeviceSafetyScreen> createState() => _DeviceSafetyScreenState();
}

class _DeviceSafetyScreenState extends ConsumerState<DeviceSafetyScreen> {
  Map<String, dynamic> state = {};
  String? error;
  bool loading = true, busy = false;
  int minutes = 15;
  Timer? timer;
  String get path => '/api/parent/children/${widget.childId}/safety';
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!busy) load();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await ref.read(workspaceRepositoryProvider).get(path);
      if (mounted) {
        setState(() {
          state = data;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> act(
    String endpoint,
    Map<String, dynamic> body,
    String title,
    String message,
  ) async {
    if (busy ||
        ref.read(sessionProvider).parent?.can('control.update') != true) {
      return;
    }
    if (!await confirmAction(context, title, message) || !mounted) return;
    setState(() => busy = true);
    try {
      await ref.read(workspaceRepositoryProvider).save('$path/$endpoint', body);
      if (!mounted) return;
      workspaceMessage(
        context,
        'Saved. Device enforcement is confirmed only after the child syncs and reports its state.',
      );
      await load();
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manage =
        ref.watch(sessionProvider).parent?.can('control.update') == true;
    final requests = (state['requests'] as List? ?? []).cast<Map>();
    final reports = (state['reports'] as List? ?? []).cast<Map>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device approvals'),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'A child can request shutdown, location off or airplane mode. Approvals are temporary. Managed Device Owner mode is needed to enforce location/airplane controls. Hardware shutdown cannot be reliably blocked by this app. If the phone is offline, commands wait until it reconnects.',
                          style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.text),
                        ),
                      ),
                    ],
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sosTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sos.withValues(alpha: 0.2)),
                      ),
                      child: Text(error!, style: const TextStyle(color: AppColors.sos, fontSize: 13)),
                    ),
                  ),
                if (busy) const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                if (manage) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: minutes,
                    decoration: const InputDecoration(
                      labelText: 'Approval duration',
                    ),
                    items: [5, 15, 30, 60]
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m minutes'),
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (m) => setState(() => minutes = m!),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => act(
                            'restore',
                            {'action': 'location'},
                            'Enable location?',
                            'Revoke location-off approvals and request location ON with location changes guarded on supported managed phones.',
                          ),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Enable & protect location'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => act(
                            'restore',
                            {'action': 'airplane'},
                            'Disable airplane mode?',
                            'Revoke airplane-mode approvals and request airplane mode OFF. An offline phone must reconnect before it can receive this command.',
                          ),
                    icon: const Icon(Icons.airplanemode_inactive),
                    label: const Text('Disable & protect airplane mode'),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'Latest device reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No device report yet. Install the updated Child app and connect it to the server.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                for (final report in reports)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device ${report['deviceId']} · ${report['reportedAtUtc']}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Managed Device Owner: ${report['data']['deviceOwner'] == true ? 'Yes' : 'No'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            'Location: ${report['data']['locationEnabled'] == true ? 'ON' : 'OFF'} · Guard applied: ${report['data']['locationGuardApplied'] == true ? 'Yes' : 'No'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            'Airplane: ${report['data']['airplaneModeEnabled'] == true ? 'ON' : 'OFF'} · Guard applied: ${report['data']['airplaneGuardApplied'] == true ? 'Yes' : 'No'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Text('Hardware shutdown guard: unavailable', style: TextStyle(fontSize: 13)),
                          if (report['data']['policyRevision'] !=
                              state['policyRevision'])
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Latest Parent command is awaiting device acknowledgement.',
                                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          if ((report['data']['error'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${report['data']['error']}', style: const TextStyle(color: AppColors.sos, fontSize: 13)),
                            ),
                          const SizedBox(height: 6),
                          const Text(
                            'Reports show the last observed state; they are not a live guarantee.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Requests & decisions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No device permission requests.', style: TextStyle(color: AppColors.muted)),
                  ),
                for (final row in requests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${safetyLabel(row['data']['action'].toString())} · ${row['status']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${row['data']['childName'] ?? 'Child'} · device ${row['deviceId']}',
                            style: const TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                          if ((row['data']['reason'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Reason: ${row['data']['reason']}', style: const TextStyle(fontSize: 13)),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Requested: ${row['requestedAtUtc']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          ),
                          if (row['data']['approvedUntilUtc'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Approved until: ${row['data']['approvedUntilUtc']}',
                                style: const TextStyle(fontSize: 12, color: AppColors.onlineDark, fontWeight: FontWeight.w600),
                              ),
                            ),
                          if (manage &&
                              ['Pending', 'Approved'].contains(row['status'])) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (row['status'] == 'Pending')
                                  FilledButton(
                                    onPressed: busy
                                        ? null
                                        : () => act(
                                            'requests/${row['id']}/decision',
                                            {
                                              'decision': 'approve',
                                              'minutes': minutes,
                                            },
                                            'Approve device action?',
                                            'Allow ${safetyLabel(row['data']['action'].toString())} for $minutes minutes? Location/airplane approval may interrupt telemetry and connectivity.',
                                          ),
                                    child: const Text('Approve'),
                                  ),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => act(
                                          'requests/${row['id']}/decision',
                                          {
                                            'decision': 'deny',
                                            'minutes': minutes,
                                          },
                                          'Deny/revoke request?',
                                          'Remove permission for this action. Managed settings return to protected state on the next sync.',
                                        ),
                                  child: Text(
                                    row['status'] == 'Approved'
                                        ? 'Revoke'
                                        : 'Deny',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ManagedDeviceCommandsCard(childId: widget.childId),
                ],
              ),
            ),
    );
  }
}

String safetyLabel(String action) => switch (action) {
  'shutdown' => 'Phone shutdown',
  'location_off' => 'Location OFF',
  'airplane_on' => 'Airplane mode ON',
  _ => action,
};

