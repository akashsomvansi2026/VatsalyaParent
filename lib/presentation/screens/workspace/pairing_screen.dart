import 'child_app_download_sheet.dart';
import 'pairing_setup_form.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/pairing_payload.dart';
import '../../../data/models/pairing_code.dart';
import '../../providers/infra_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/session_provider.dart';
import '../dashboard/widgets/pairing_qr_sheet.dart';
import 'workspace_widgets.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key, this.initialChildId});
  final int? initialChildId;
  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  List<PairingCode> codes = [];
  String server = AppConfig.apiBaseUrl;
  bool loading = true, busy = false;
  String? error, quotaError;
  Map<String, dynamic>? quota;
  bool can(String key) => ref.read(sessionProvider).parent?.can(key) == true;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final repo = ref.read(workspaceRepositoryProvider);
      final parentId = ref.read(sessionProvider).parent?.id;
      if (parentId != null) {
        try {
          final balance = await repo.get(
            '/api/parents/$parentId/enrollment-tokens',
          );
          if (mounted) {
            setState(() {
              quota = balance;
              quotaError = null;
            });
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              quota = null;
              quotaError =
                  'Token balance unavailable. You can retry refresh; the server will check your balance when generating a code.';
            });
          }
        }
      }
      final config = await repo.get('/api/parent/pairing-config');
      final rows = await repo.list('/api/parent/pairing-codes');
      if (mounted) {
        setState(() {
          server = config['apiUrl']?.toString() ?? server;
          codes = rows.map(PairingCode.fromJson).toList();
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> generate() async {
    if (busy ||
        !can('device.add') ||
        !can('device.assign') ||
        !can('child.create')) {
      return;
    }
    setState(() => busy = true);
    try {
      if (!await showChildAppDownload(context) || !mounted) return;
      final repo = ref.read(workspaceRepositoryProvider);
      final children = can('child.view')
          ? await repo.list('/api/children')
          : await repo.list('/api/device-child-options');
      if (!mounted) return;
      if (widget.initialChildId != null &&
          !children.any(
            (c) =>
                c['id'] == widget.initialChildId && c['status'] != 'Inactive',
          )) {
        workspaceMessage(
          context,
          'This child is unavailable for pairing. Refresh your children list and try again.',
        );
        return;
      }
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => PairingSetupForm(
          children: children.where((c) => c['status'] != 'Inactive').toList(),
          initialChildId: widget.initialChildId,
        ),
      );
      if (result == null || !mounted) return;
      // The backend derives Parent ownership from the authenticated session.
      final apiUrl = validatePairingServer(server);
      final row = await repo.save('/api/parent/pairing-codes', result);
      row['apiUrl'] = apiUrl;
      final code = PairingCode.fromJson(row);
      if (!mounted) return;
      ref.invalidate(dashboardProvider);
      await load();
      if (mounted) await showPairingQrSheet(context, code);
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> show(PairingCode code) async {
    try {
      pairingPayload(code, server);
      if (mounted) {
        await showPairingQrSheet(
          context,
          PairingCode(
            id: code.id,
            code: code.code,
            isActive: code.isActive,
            isUsed: code.isUsed,
            createdAtUtc: code.createdAtUtc,
            expiresAtUtc: code.expiresAtUtc,
            childName: code.childName,
            childEmail: code.childEmail,
            parent: code.parent,
            accessToken: code.accessToken,
            apiUrl: server,
          ),
        );
      }
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    }
  }

  Future<void> revoke(PairingCode code) async {
    if (!await confirmAction(
      context,
      'Revoke pairing code?',
      'This code will no longer pair a child phone.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .remove('/api/parent/pairing-codes/${code.id}');
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
    ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair child device'),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: can('device.assign') && can('child.create')
          ? FloatingActionButton.extended(
              onPressed: busy || quota?['availableTokens'] == 0
                  ? null
                  : generate,
              tooltip: 'Generate pairing code',
              icon: const Icon(Icons.qr_code_2),
              label: const Text('New code'),
            )
          : null,
      body: loading
          ? const Center(child: LoadingView(message: 'Loading pairing setup…'))
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Connect your family',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Parent: ${ref.watch(sessionProvider).parent?.name ?? 'Parent'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (quota != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.token_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${quota!['availableTokens']} available Â· ${quota!['usedTokens']} used of ${quota!['totalTokens']} total',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Text(
                          'Enrollment balance unavailable',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      if (quotaError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            quotaError!,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        '1. Generate a pairing code for your child.\n2. Open Vatsalya Child app and scan the QR.\n3. The device securely pairs with your family.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (can('device.assign') && can('child.create'))
                        FilledButton.icon(
                          onPressed: busy || quota?['availableTokens'] == 0
                              ? null
                              : generate,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            busy ? 'Please wait…' : 'Generate pairing code',
                          ),
                        )
                      else
                        const Text(
                          'Your account needs child creation and device assignment permissions to generate a code.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      if (quota?['availableTokens'] == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Ask your Distributor or Super Admin to allocate enrollment tokens.',
                            style: TextStyle(
                              color: AppColors.sos,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'A token is consumed only after successful pairing.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sosTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.sos.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: AppColors.sos,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dns_outlined,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    ),
                    title: const Text(
                      'Child-reachable server',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      server,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit server address for QR',
                      onPressed: () async {
                        final values = await editValues(
                          context,
                          'Pairing server',
                          [
                            EditorField(
                              'server',
                              'Server address',
                              required: true,
                              validate: (v) {
                                try {
                                  validatePairingServer(v);
                                  return null;
                                } catch (e) {
                                  return e.toString();
                                }
                              },
                            ),
                          ],
                          initial: {'server': server},
                        );
                        if (values != null && mounted) {
                          setState(
                            () => server = validatePairingServer(
                              values['server']!,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const AppSectionTitle('Active & previous pairing codes'),
                const SizedBox(height: 10),
                if (codes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: EmptyState(
                      icon: Icons.qr_code_2,
                      title: 'No pairing codes yet',
                      subtitle:
                          'Generate a code to link a child smartphone or tablet.',
                    ),
                  ),
                for (final code in codes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: code.isActive
                                ? AppColors.onlineTint
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.qr_code_2,
                            color: code.isActive
                                ? AppColors.onlineDark
                                : AppColors.muted,
                            size: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              code.childName ?? 'Child',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                code.code,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${code.isActive
                                ? 'Active'
                                : code.isUsed
                                ? 'Used'
                                : 'Inactive'} Â· Expires ${code.expiresAtUtc != null ? code.expiresAtUtc!.toLocal().toString().split('.').first : 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        onTap: code.isActive && !busy ? () => show(code) : null,
                        trailing: code.isActive
                            ? IconButton(
                                onPressed: busy ? null : () => revoke(code),
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.muted,
                                  size: 20,
                                ),
                                tooltip: 'Revoke code',
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
