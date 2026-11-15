import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/infra_providers.dart';
import '../providers/session_provider.dart';

Future<void> showProvisioningSheet(BuildContext context, {int? childId}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProvisioningSheet(childId: childId),
    );

class ProvisioningSheet extends ConsumerStatefulWidget {
  const ProvisioningSheet({super.key, this.childId});
  final int? childId;
  @override
  ConsumerState<ProvisioningSheet> createState() => _ProvisioningState();
}

class _ProvisioningState extends ConsumerState<ProvisioningSheet> {
  List<Map<String, dynamic>> children = [];
  int? childId;
  bool consent = false, busy = false, loading = true;
  String? error;
  Map<String, dynamic>? invitation;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    childId = widget.childId;
    Future.microtask(load);
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final expires = DateTime.tryParse(
        invitation?['expiresAtUtc']?.toString() ?? '',
      );
      if (expires != null &&
          !expires.isAfter(DateTime.now().toUtc()) &&
          mounted) {
        setState(() {
          invitation = null;
          error = 'Invitation expired. Generate a new QR before setup.';
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool get allowed {
    final parent = ref.read(sessionProvider).parent;
    return [
      'device.add',
      'device.assign',
      'child.create',
    ].every((permission) => parent?.can(permission) == true);
  }

  Future<void> load() async {
    try {
      if (childId == null &&
          ref.read(sessionProvider).parent?.can('child.view') == true) {
        final rows = await ref
            .read(workspaceRepositoryProvider)
            .list('/api/parent/children');
        if (mounted) {
          setState(() {
            children = rows.where((c) => c['deviceId'] == null).toList();
            childId = children.firstOrNull?['id'] as int?;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> create() async {
    if (busy || !consent || !allowed || childId == null) return;
    final account = ref.read(sessionProvider).parent?.id;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await ref.read(workspaceRepositoryProvider).save(
        '/api/parent/children/$childId/managed-enrollment',
        {'guardianConsent': true},
      );
      if (value['managedEnrollment'] != true ||
          value['provisioningPayload'] is! Map ||
          DateTime.tryParse(
                value['expiresAtUtc']?.toString() ?? '',
              )?.isAfter(DateTime.now().toUtc()) !=
              true) {
        throw const FormatException(
          'Managed enrollment response is unavailable or expired.',
        );
      }
      if (mounted && account == ref.read(sessionProvider).parent?.id) {
        setState(() => invitation = value);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .86,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Managed Device Owner setup',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close setup guide',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Installing an APK or activating Device Administrator does not grant Device Owner. There is no default Parent PIN that grants ownership. Use Android Setup Wizard on an eligible device that you own or are authorized to manage.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Use a clean eligible test device. Existing phone data, accounts and profiles must not be removed automatically. Managed enrollment may require a reset; arrange that separately with the authorized device owner.',
            ),
            const SizedBox(height: 12),
            const Text(
              'The backend supplies the exact signed APK URL, checksum, DPC component and a single-use invitation. This setup preserves the device home launcher. Profile Owner is a different management mode.',
            ),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (widget.childId == null && children.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: childId,
                decoration: const InputDecoration(labelText: 'Unpaired child'),
                items: [
                  for (final child in children)
                    DropdownMenuItem(
                      value: child['id'] as int,
                      child: Text('${child['name']}'),
                    ),
                ],
                onChanged: busy || invitation != null
                    ? null
                    : (id) => setState(() => childId = id),
              ),
            if (!loading && childId == null)
              const Text(
                'Create an unpaired child profile first, then generate its managed enrollment invitation.',
              ),
            if (!allowed)
              const Text(
                'Your account needs device enrollment and child creation permissions to issue this invitation.',
              ),
            if (allowed && childId != null) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: consent,
                onChanged: busy
                    ? null
                    : (value) => setState(() => consent = value ?? false),
                title: const Text(
                  'I own or am authorized to manage this device and consent to Device Owner enrollment.',
                ),
              ),
              FilledButton.icon(
                onPressed: !consent || busy ? null : create,
                icon: const Icon(Icons.qr_code),
                label: Text(
                  busy
                      ? 'Creating invitation…'
                      : 'Generate managed enrollment QR',
                ),
              ),
            ],
            if (invitation != null) ...[
              const SizedBox(height: 20),
              Center(
                child: QrImageView(
                  data: jsonEncode(invitation!['provisioningPayload']),
                  size: 280,
                  backgroundColor: Colors.white,
                ),
              ),
              Text('Expires: ${invitation!['expiresAtUtc']}'),
              const Text(
                'Sensitive single-use invitation: show only to the authorized device operator. Scan using supported Android Setup Wizard. Finish management disclosure and registration on the child phone, then verify its reported Device Owner state.',
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
