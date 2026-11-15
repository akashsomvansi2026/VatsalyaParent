import 'child_app_download_sheet.dart';
import '../../../core/utils/pairing_payload.dart';
import '../../../data/models/pairing_code.dart';
import '../dashboard/widgets/pairing_qr_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/responsive_content.dart';
import 'widgets/family_management_widgets.dart';
import '../../../core/widgets/status_views.dart';
import '../../providers/infra_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/session_provider.dart';
import 'workspace_widgets.dart';
class FamilyManagementScreen extends ConsumerStatefulWidget {
  const FamilyManagementScreen({
    super.key,
    required this.devices,
    this.initialCreate = false,
  });
  final bool devices;
  final bool initialCreate;
  @override
  ConsumerState<FamilyManagementScreen> createState() =>
      _FamilyManagementScreenState();
}
class _FamilyManagementScreenState
    extends ConsumerState<FamilyManagementScreen> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true, busy = false;
  String? error;
  String search = '';
  final searchController = TextEditingController();
  String get module => widget.devices ? 'device' : 'child';
  String get path => widget.devices ? '/api/devices' : '/api/children';
  bool can(String action) =>
      ref.read(sessionProvider).parent?.can('$module.$action') == true;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
    if (widget.initialCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) edit();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void clearSearch() {
    searchController.clear();
    setState(() => search = '');
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = can('view')
          ? await ref.read(workspaceRepositoryProvider).list(path)
          : <Map<String, dynamic>>[];
      if (mounted) setState(() => rows = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> run(Future<void> Function() mutation) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await mutation();
      if (!mounted) return;
      ref.invalidate(dashboardProvider);
      workspaceMessage(context, 'Saved.');
      await load();
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit([Map<String, dynamic>? row, bool profile = false]) async {
    final permission = row == null
        ? (widget.devices ? 'add' : 'create')
        : profile
        ? 'profile.update'
        : widget.devices
        ? 'rename'
        : 'update';
    if (!can(permission)) return;
    final pairNewChild =
        row == null &&
        !widget.devices &&
        ref.read(sessionProvider).parent?.can('device.add') == true &&
        ref.read(sessionProvider).parent?.can('device.assign') == true;
    if (row == null && !widget.devices) {
      if (!await showChildAppDownload(context) || !mounted) return;
    }
    final result = await editValues(
      context,
      '${row == null ? 'Add' : 'Edit'} ${widget.devices ? 'device' : 'child'}',
      [
        EditorField(
          'name',
          'Name',
          required: true,
          validate: (v) =>
              v.length > 120 ? 'Use at most 120 characters.' : null,
        ),
        if (pairNewChild)
          const EditorField(
            'childEmail',
            'Child email',
            required: true,
            validate: emailValidation,
          ),
        if (!widget.devices)
          const EditorField(
            'birthDate',
            'Birth date (YYYY-MM-DD)',
            validate: dateValidation,
          ),
        if (widget.devices && row == null)
          const EditorField('identifier', 'Device identifier', required: true),
        if (widget.devices && row == null)
          const EditorField(
            'platform',
            'Platform',
            required: true,
            choices: {
              'Android': 'Android',
              'iOS': 'iOS',
              'Windows': 'Windows',
              'Other': 'Other',
            },
          ),
      ],
      initial: row ?? {'platform': 'Android'},
      notice: widget.devices && row == null
          ? 'This adds a device profile. Pair the Child app separately to receive telemetry and enforce controls.'
          : null,
      submitLabel: pairNewChild ? 'Save & generate pairing QR' : 'Save',
    );
    if (result == null || !mounted) return;
    Map<String, dynamic>? created;
    await run(() async {
      final data = <String, dynamic>{...result}..remove('childEmail');
      if (!widget.devices) {
        data['birthDate'] = result['birthDate']!.isEmpty
            ? null
            : result['birthDate'];
      }
      final url = row == null
          ? path
          : widget.devices
          ? '$path/${row['id']}/rename'
          : '$path/${row['id']}${profile ? '/profile' : ''}';
      final saved = await ref
          .read(workspaceRepositoryProvider)
          .save(
            url,
            data,
            method: row == null
                ? 'POST'
                : profile
                ? 'PUT'
                : 'PATCH',
          );
      if (row == null && !widget.devices) created = saved;
    });
    if (!mounted || created == null) return;
    if (pairNewChild) {
      while (mounted) {
        try {
          final repo = ref.read(workspaceRepositoryProvider);
          final config = await repo.get('/api/parent/pairing-config');
          final server = validatePairingServer(
            config['apiUrl']?.toString() ?? '',
          );
          final code = await repo.save('/api/parent/pairing-codes', {
            'childId': created!['id'],
            'childName': created!['name'],
            'childEmail': result['childEmail']!.trim().toLowerCase(),
            'validForHours': 24,
          });
          code['apiUrl'] = server;
          if (!mounted) return;
          await showPairingQrSheet(context, PairingCode.fromJson(code));
          return;
        } catch (e) {
          if (!mounted) return;
          final retry = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Child saved'),
              content: Text(
                'Pairing QR could not be generated. Your child profile is saved.\n$e',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Pair later'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Retry pairing QR'),
                ),
              ],
            ),
          );
          if (retry != true) return;
        }
      }
    }
  }

  Future<void> action(Map<String, dynamic> row, String operation) async {
    if (operation == 'pair') {
      await context.push('/pairing?childId=${row['id']}');
      return;
    }
    if (operation == 'supervise') {
      context.push('/child/${row['id']}');
      return;
    }
    if (operation == 'edit') {
      await edit(row);
      return;
    }
    if (operation == 'profile-edit') {
      await edit(row, true);
      return;
    }
    if (operation == 'details' ||
        operation == 'profile' ||
        ['status', 'location', 'battery', 'network'].contains(operation)) {
      try {
        final details = operation == 'details'
            ? row
            : await ref
                  .read(workspaceRepositoryProvider)
                  .get('$path/${row['id']}/$operation');
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              operation == 'details' ? '${row['name']}' : fieldLabel(operation),
            ),
            content: SingleChildScrollView(child: RecordDetails(details)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (mounted) workspaceMessage(context, e);
      }
      return;
    }
    if (!can(operation)) return;
    if (operation == 'assign') {
      try {
        final children = await ref
            .read(workspaceRepositoryProvider)
            .list('/api/device-child-options');
        if (!mounted) return;
        final result = await editValues(
          context,
          'Assign device',
          [
            EditorField(
              'childId',
              'Child',
              required: true,
              choices: {for (final c in children) '${c['id']}': '${c['name']}'},
            ),
          ],
          initial: row,
          notice:
              'Changing assignment invalidates the device pairing credential. Pair the Child app again afterward.',
        );
        if (result == null || !mounted) return;
        await run(() async {
          await ref.read(workspaceRepositoryProvider).save(
            '$path/${row['id']}/assign',
            {'childId': int.parse(result['childId']!)},
          );
        });
      } catch (e) {
        if (mounted) workspaceMessage(context, e);
      }
      return;
    }
    if (!await confirmAction(
      context,
      '$operation ${row['name']}?',
      ['remove', 'delete', 'unassign'].contains(operation)
          ? 'This disconnects or archives the selected family record. Device pairing may need to be repeated. Audit history is retained.'
          : 'Change this child account status? Inactive children cannot report from their paired device.',
    )) {
      return;
    }
    if (!mounted) return;
    await run(() async {
      if (operation == 'delete' || operation == 'remove') {
        await ref
            .read(workspaceRepositoryProvider)
            .remove('$path/${row['id']}');
      } else {
        await ref
            .read(workspaceRepositoryProvider)
            .save('$path/${row['id']}/$operation', {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final parent = ref.watch(sessionProvider).parent;
    final visibleRows = rows
        .where(
          (row) => '${row['name']} ${row['identifier'] ?? ''}'
              .toLowerCase()
              .contains(search),
        )
        .toList(growable: false);
    final allowAdd = can(widget.devices ? 'add' : 'create');
    final subtitle = loading
        ? 'Loading ${widget.devices ? 'devices' : 'children'}…'
        : error != null
        ? 'Could not refresh family information'
        : '${rows.length} ${widget.devices ? 'devices' : 'children'} · ${parent?.name ?? 'Your family'}';
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFCFB),
        toolbarHeight: (MediaQuery.textScalerOf(context).scale(22) + 40).clamp(
          64.0,
          120.0,
        ),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFF0E6),
              ),
              tooltip: 'Back',
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: familyOrange,
                size: 30,
              ),
              onPressed: () {
                final router = GoRouter.maybeOf(context);
                if (router?.canPop() == true) {
                  router!.pop();
                } else if (router != null) {
                  router.go('/features');
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
          ),
        ),
        title: Text(
          widget.devices ? 'Devices' : 'Children',
          style: const TextStyle(
            color: familyInk,
            fontWeight: FontWeight.w800,
            fontSize: 23,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFF0E6),
              ),
              onPressed: busy || loading ? null : load,
              icon: const Icon(
                Icons.refresh_rounded,
                color: familyOrange,
                size: 27,
              ),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      floatingActionButton: allowAdd
          ? FloatingActionButton(
              onPressed: busy ? null : edit,
              tooltip: 'Add ${widget.devices ? 'device' : 'child'}',
              backgroundColor: familyOrange,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 5,
              child: const Icon(Icons.add_rounded, size: 33),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: load,
          color: familyOrange,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ResponsiveContent(
                maxWidth: 960,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FamilyManagementHero(
                      devices: widget.devices,
                      subtitle: subtitle,
                    ),
                    FamilySearchField(
                      devices: widget.devices,
                      controller: searchController,
                      onChanged: (value) =>
                          setState(() => search = value.toLowerCase()),
                      onClear: clearSearch,
                    ),
                    const SizedBox(height: 18),
                    if (loading)
                      LoadingView(
                        message:
                            'Loading ${widget.devices ? 'devices' : 'children'}...',
                      )
                    else if (error != null)
                      ErrorView(message: error!, onRetry: load)
                    else if (visibleRows.isEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 250).clamp(
                            300.0,
                            600.0,
                          ),
                        ),
                        child: Center(
                          child: FamilyEmptyState(
                            devices: widget.devices,
                            filtered: search.isNotEmpty && rows.isNotEmpty,
                            onClear: clearSearch,
                            onAdd: allowAdd && !busy ? edit : null,
                          ),
                        ),
                      )
                    else
                      for (final row in visibleRows)
                        FamilyRecordCard(
                          devices: widget.devices,
                          title: '${row['name']}',
                          status: widget.devices
                              ? '${row['platform'] ?? 'Device'}'
                              : '${row['status'] ?? 'Active'}',
                          detail: widget.devices
                              ? row['childId'] == null
                                    ? 'Unassigned'
                                    : 'Child #${row['childId']}'
                              : 'Birth: ${row['birthDate'] ?? 'Not set'}',
                          inactive:
                              !widget.devices && row['status'] == 'Inactive',
                          onTap: () => action(
                            row,
                            widget.devices ? 'details' : 'supervise',
                          ),
                          menu: _rowMenu(row),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowMenu(Map<String, dynamic> row) => PopupMenuButton<String>(
    enabled: !busy,
    onSelected: (v) => action(row, v),
    itemBuilder: (_) => [
      if (!widget.devices &&
          ref.read(sessionProvider).parent?.can('device.add') == true)
        const PopupMenuItem(
          value: 'pair',
          child: Text('Pair this child’s device'),
        ),
      const PopupMenuItem(value: 'details', child: Text('View details')),
      if (!widget.devices)
        const PopupMenuItem(
          value: 'supervise',
          child: Text('Apps, usage & location'),
        ),
      if (!widget.devices && can('profile.view'))
        const PopupMenuItem(value: 'profile', child: Text('Child profile')),
      if (!widget.devices && can('profile.update'))
        const PopupMenuItem(
          value: 'profile-edit',
          child: Text('Edit child profile'),
        ),
      if (can(widget.devices ? 'rename' : 'update'))
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
      if (widget.devices) ...[
        for (final op in ['assign', 'unassign', 'remove'].where(can))
          PopupMenuItem(value: op, child: Text(fieldLabel(op))),
        for (final kind in [
          'status',
          'location',
          'battery',
          'network',
        ].where((k) => can('$k.view')))
          PopupMenuItem(value: kind, child: Text('View $kind')),
      ] else ...[
        for (final op in [
          row['status'] == 'Active' ? 'deactivate' : 'activate',
          'delete',
        ].where(can))
          PopupMenuItem(value: op, child: Text(fieldLabel(op))),
      ],
    ],
  );
}
