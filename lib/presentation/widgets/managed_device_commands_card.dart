import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_card.dart';
import '../providers/infra_providers.dart';
import '../providers/session_provider.dart';
import '../screens/workspace/workspace_widgets.dart';

class ManagedDeviceCommandsCard extends ConsumerStatefulWidget {
  const ManagedDeviceCommandsCard({super.key, required this.childId});
  final int childId;
  @override
  ConsumerState<ManagedDeviceCommandsCard> createState() =>
      _ManagedCommandsState();
}

class _ManagedCommandsState extends ConsumerState<ManagedDeviceCommandsCard> {
  List<Map<String, dynamic>> devices = [], commands = [];
  int? selected;
  String? error;
  bool loading = true, busy = false;
  Map<String, dynamic>? retry;
  final target = TextEditingController();
  Timer? timer;
  String get path =>
      '/api/parent/children/${widget.childId}/management/commands';
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
    target.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final account = ref.read(sessionProvider).parent?.id;
    try {
      final repo = ref.read(workspaceRepositoryProvider);
      final results = await Future.wait([
        repo.list('$path/devices'),
        repo.list(path),
      ]);
      if (!mounted || account != ref.read(sessionProvider).parent?.id) return;
      setState(() {
        devices = results[0];
        commands = results[1];
        selected = devices.any((d) => d['id'] == selected)
            ? selected
            : devices.firstOrNull?['id'] as int?;
        error = null;
      });
    } catch (e) {
      if (mounted && account == ref.read(sessionProvider).parent?.id) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String requestId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final s = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  Future<void> prepare(String action, bool enabled, {String? package}) async {
    if (busy ||
        selected == null ||
        retry != null ||
        ref.read(sessionProvider).parent?.can('control.update') != true) {
      return;
    }
    if (package != null &&
        !RegExp(
          r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
        ).hasMatch(package)) {
      workspaceMessage(context, 'Enter a valid application package.');
      return;
    }
    final body = <String, dynamic>{
      'requestId': requestId(),
      'deviceId': selected,
      'action': action,
      'enabled': enabled,
      'target': package,
      'validForMinutes': 15,
    };
    if (!await confirmAction(
          context,
          'Confirm managed-device action',
          'Send $action to the selected device? Actions require a supported management capability. The command expires in 15 minutes and success requires a device acknowledgement.',
        ) ||
        !mounted) {
      return;
    }
    await send(body);
  }

  Future<void> send(Map<String, dynamic> body) async {
    if (busy ||
        ref.read(sessionProvider).parent?.can('control.update') != true) {
      return;
    }
    setState(() {
      busy = true;
      retry = body;
      error = null;
    });
    try {
      await ref.read(workspaceRepositoryProvider).save(path, body);
      if (!mounted) return;
      setState(() => retry = null);
      workspaceMessage(
        context,
        'Command queued. Check its acknowledged device result.',
      );
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manage =
        ref.watch(sessionProvider).parent?.can('control.update') == true;
    final device = devices.where((d) => d['id'] == selected).firstOrNull;
    final report = device?['report'] as Map?;
    final disabled = busy || retry != null || selected == null || error != null;
    bool supports(String action) =>
        action == 'refresh' ||
        (device?['allowedActions'] as List?)?.contains(action) == true;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Managed device commands',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Refresh command history',
                onPressed: busy ? null : load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const Text(
            'Installation does not grant Device Owner. Queued actions are confirmed only after the child reports execution.',
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (retry != null) ...[
            const Text(
              'Delivery is uncertain. Retry the same request to avoid a duplicate.',
            ),
            TextButton(
              onPressed: busy ? null : () => send(retry!),
              child: const Text('Retry same command'),
            ),
          ],
          if (!loading && devices.isEmpty)
            const Text('No paired device is available.'),
          if (devices.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'Paired device'),
              items: [
                for (final d in devices)
                  DropdownMenuItem(
                    value: d['id'] as int,
                    child: Text('${d['name']}'),
                  ),
              ],
              onChanged: busy || retry != null
                  ? null
                  : (id) => setState(() => selected = id),
            ),
            Text(
              'Device Owner reported: ${report?['deviceOwner'] == true ? 'Yes' : 'Not reported'}',
            ),
            Text('Last report: ${device?['reportedAtUtc'] ?? 'Not available'}'),
            if (manage) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: disabled || !supports('lock')
                        ? null
                        : () => prepare('lock', true),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Lock device now'),
                  ),
                  OutlinedButton(
                    onPressed: disabled || !supports('camera')
                        ? null
                        : () => prepare('camera', true),
                    child: const Text('Disable camera'),
                  ),
                  OutlinedButton(
                    onPressed: disabled || !supports('camera')
                        ? null
                        : () => prepare('camera', false),
                    child: const Text('Enable camera'),
                  ),
                  OutlinedButton(
                    onPressed: disabled ? null : () => prepare('refresh', true),
                    child: const Text('Refresh device information'),
                  ),
                ],
              ),
              TextField(
                controller: target,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Application package',
                  hintText: 'com.organization.application',
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in [
                    ('Suspend application', 'suspend', true),
                    ('Unsuspend application', 'suspend', false),
                    ('Block uninstall', 'uninstall', true),
                    ('Allow uninstall', 'uninstall', false),
                  ])
                    OutlinedButton(
                      onPressed: disabled || !supports(item.$2)
                          ? null
                          : () => prepare(
                              item.$2,
                              item.$3,
                              package: target.text.trim(),
                            ),
                      child: Text(item.$1),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 12),
          const Text(
            'Command history',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (!loading && commands.isEmpty)
            const Text('No management commands yet.'),
          for (final c in commands.take(20))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c['data']?['request']?['action'] ?? 'Command'} · ${c['status'] ?? 'Unknown'}',
                  ),
                  Text(
                    'Result: ${c['data']?['acknowledgement']?['code'] ?? 'Awaiting acknowledgement'}',
                  ),
                  Text(
                    'Expires: ${c['data']?['expiresAtUtc'] ?? 'Unavailable'}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
