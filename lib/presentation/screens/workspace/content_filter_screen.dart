import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_views.dart';
import '../../providers/infra_providers.dart';
import '../../providers/session_provider.dart';

class ContentFilterScreen extends ConsumerStatefulWidget {
  const ContentFilterScreen({super.key, required this.childId});
  final int childId;
  @override
  ConsumerState<ContentFilterScreen> createState() =>
      _ContentFilterScreenState();
}

class _ContentFilterScreenState extends ConsumerState<ContentFilterScreen> {
  final fields = {
    for (final key in [
      'allowedDomains',
      'blockedDomains',
      'blockedKeywords',
      'approvedVideoIds',
    ])
      key: TextEditingController(),
  };
  bool loading = true, busy = false, enabled = false, allowlistOnly = false;
  bool networkFiltering = false, managedNetworkSettings = false;
  String youtubeMode = 'blocked';
  String? error;
  Map<String, dynamic>? networkStatus;
  String? networkStatusAtUtc;
  String get path => '/api/parent/children/${widget.childId}/content-filter';
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    try {
      final response = await ref.read(workspaceRepositoryProvider).get(path);
      if (!mounted) return;
      final policy = response['policy'] as Map;
      for (final entry in fields.entries) {
        entry.value.text = (policy[entry.key] as List? ?? []).join('\n');
      }
      setState(() {
        enabled = policy['enabled'] == true;
        allowlistOnly = policy['allowlistOnly'] == true;
        networkFiltering = policy['networkFilteringEnabled'] == true;
        managedNetworkSettings = policy['managedNetworkSettingsEnabled'] == true;
        youtubeMode = policy['youtubeMode'].toString();
        networkStatus = response['networkStatus'] is Map
            ? Map<String, dynamic>.from(response['networkStatus'] as Map)
            : null;
        networkStatusAtUtc = response['networkStatusAtUtc']?.toString();
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (busy ||
        ref.read(sessionProvider).parent?.can('web_filter.update') != true) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(workspaceRepositoryProvider).save(path, {
        'enabled': enabled,
        'allowlistOnly': allowlistOnly,
        'networkFilteringEnabled': networkFiltering,
        'managedNetworkSettingsEnabled': managedNetworkSettings,
        'youtubeMode': youtubeMode,
        for (final entry in fields.entries)
          entry.key: entry.value.text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
      }, method: 'PUT');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Rules saved. The Child applies them when Safe Browser connects.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final writable =
        ref.watch(sessionProvider).parent?.can('web_filter.update') == true &&
        !busy &&
        !loading &&
        error == null;
    return Scaffold(
      appBar: AppBar(title: const Text('Web & browser safety')),
      body: loading
          ? const Center(child: LoadingView(message: 'Loading safety rules…'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.public, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Web protection',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Safe Browser uses these rules. Optional network filtering needs Child VPN consent. Managed Chrome/network settings require a supported Device Owner setup. Neither option silently inspects private messages or guarantees every browser is filtered.',
                        style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (networkStatus != null)
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.onlineTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user_outlined, color: AppColors.onlineDark, size: 20),
                      ),
                      title: Text('Device report: ${networkStatus!['state'] ?? 'unknown'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text('Last report: ${networkStatusAtUtc ?? 'time unavailable'} · Managed settings: ${networkStatus!['managedSettingsState'] ?? 'unknown'}', style: const TextStyle(fontSize: 12)),
                    ),
                  )
                else
                  const AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(Icons.info_outline, color: AppColors.muted),
                      title: Text('No network filter report yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text('Saved rules are not proof of device enforcement.', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sosTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(color: AppColors.sos, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: busy ? null : load,
                          child: const Text('Reload rules'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Safe Browser protection', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Apply rules in the Child Safe Browser', style: TextStyle(fontSize: 12)),
                        value: enabled,
                        onChanged: writable
                            ? (value) => setState(() => enabled = value)
                            : null,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Only allow listed domains', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('All other domains will be blocked in the Safe Browser', style: TextStyle(fontSize: 12)),
                        value: allowlistOnly,
                        onChanged: writable
                            ? (value) => setState(() => allowlistOnly = value)
                            : null,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Network domain filtering', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Requires VPN consent on the Child device; check its report above', style: TextStyle(fontSize: 12)),
                        value: networkFiltering,
                        onChanged: writable
                            ? (value) => setState(() => networkFiltering = value)
                            : null,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Managed Chrome/network settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Requires supported Device Owner management', style: TextStyle(fontSize: 12)),
                        value: managedNetworkSettings,
                        onChanged: writable
                            ? (value) => setState(() => managedNetworkSettings = value)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Website rules',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter domains such as example.com, one per line. Blocks include subdomains and take priority over allows. URL/search keywords do not inspect page contents.',
                        style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.muted),
                      ),
                      const SizedBox(height: 14),
                      for (final entry in fields.entries.where(
                        (e) => e.key != 'approvedVideoIds',
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextField(
                            controller: entry.value,
                            enabled: writable,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: {
                                'allowedDomains': 'Allowed domains',
                                'blockedDomains': 'Blocked domains',
                                'blockedKeywords': 'Blocked URL/search keywords',
                              }[entry.key],
                              helperText: 'One per line',
                            ),
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        key: ValueKey(youtubeMode),
                        initialValue: youtubeMode,
                        decoration: const InputDecoration(
                          labelText: 'YouTube access',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'blocked',
                            child: Text('Block YouTube'),
                          ),
                          DropdownMenuItem(
                            value: 'approved_only',
                            child: Text('Parent-approved videos only'),
                          ),
                        ],
                        onChanged: writable
                            ? (value) => setState(() => youtubeMode = value!)
                            : null,
                      ),
                      if (youtubeMode == 'approved_only')
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: TextField(
                            controller: fields['approvedVideoIds'],
                            enabled: writable,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Approved video IDs',
                              helperText:
                                  '11-character YouTube video ID, one per line',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (ref
                        .watch(sessionProvider)
                        .parent
                        ?.can('web_filter.update') ==
                    true)
                  FilledButton(
                    onPressed: writable ? save : null,
                    child: Text(busy ? 'Saving…' : 'Save rules'),
                  ),
              ],
            ),
    );
  }
}
