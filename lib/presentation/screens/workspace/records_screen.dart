import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/parent_features.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_views.dart';
import '../../providers/infra_providers.dart';
import '../../providers/session_provider.dart';
import 'workspace_widgets.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key, required this.module});
  final String module;
  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  List<Map<String, dynamic>> rows = [];
  String? error;
  String search = '';
  bool loading = true, busy = false;
  ParentFeature get feature =>
      ParentFeature.all.firstWhere((f) => f.key == widget.module);
  bool can(String action) =>
      feature.can(ref.read(sessionProvider).parent?.permissions ?? {}, action);
  String get path => '/api/resources/${widget.module}';
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = can('view')
          ? await ref.read(workspaceRepositoryProvider).list(path)
          : <Map<String, dynamic>>[];
      if (mounted) setState(() => rows = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) {
        workspaceMessage(context, 'Saved.');
        await load();
      }
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    if (!can(row == null ? 'create' : 'update')) return;
    final repo = ref.read(workspaceRepositoryProvider);
    try {
      final parent = ref.read(sessionProvider).parent!;
      final children = parent.can('child.view')
          ? await repo.list('/api/children')
          : <Map<String, dynamic>>[];
      final devices = parent.can('device.view')
          ? await repo.list('/api/devices')
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      final initialData = Map<String, dynamic>.from(row?['data'] as Map? ?? {});
      final result = await editValues(
        context,
        '${row == null ? 'Add' : 'Edit'} ${feature.title}',
        [
          const EditorField(
            'name',
            'Name',
            required: true,
            validate: _nameValidation,
          ),
          if (children.isNotEmpty)
            EditorField(
              'childId',
              'Child (optional)',
              choices: {
                '': 'Whole family',
                for (final c in children) '${c['id']}': '${c['name']}',
              },
            ),
          if (devices.isNotEmpty)
            EditorField(
              'deviceId',
              'Device (optional)',
              choices: {
                '': 'No specific device',
                for (final d in devices) '${d['id']}': '${d['name']}',
              },
            ),
          for (final field in feature.fields)
            EditorField(
              field,
              fieldLabel(field),
              multiline: ['notes', 'body'].contains(field),
              numeric: [
                'latitude',
                'longitude',
                'radiusMetres',
                'dailyMinutes',
                'amount',
              ].contains(field),
              required: [
                'latitude',
                'longitude',
                'radiusMetres',
                'amount',
                'url',
              ].contains(field),
              validate: (value) => validateField(field, value),
            ),
        ],
        initial: {...initialData, ...?row},
        notice: feature.notice,
      );
      if (result == null || !mounted) return;
      final data = {
        ...initialData,
        for (final f in feature.fields)
          f:
              [
                    'latitude',
                    'longitude',
                    'radiusMetres',
                    'dailyMinutes',
                    'amount',
                  ].contains(f) &&
                  result[f]!.isNotEmpty
              ? num.parse(result[f]!)
              : result[f],
      };
      await run(() async {
        await repo.save(
          row == null ? path : '$path/${row['id']}',
          {
            'name': result['name'],
            'childId': int.tryParse(
              result['childId'] ?? '${row?['childId'] ?? ''}',
            ),
            'deviceId': int.tryParse(
              result['deviceId'] ?? '${row?['deviceId'] ?? ''}',
            ),
            'data': data,
          },
          method: row == null ? 'POST' : 'PATCH',
        );
      });
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    }
  }

  static String? _nameValidation(String value) =>
      value.length > 160 ? 'Use at most 160 characters.' : null;
  static String? validateField(String field, String value) {
    if (field == 'latitude') return numberValidation(value, -90, 90);
    if (field == 'longitude') return numberValidation(value, -180, 180);
    if (field == 'radiusMetres') return numberValidation(value, 1, 100000);
    if (field == 'amount') return numberValidation(value, 0.01, 100000000);
    if (field == 'dailyMinutes' && value.isNotEmpty) {
      return numberValidation(value, 0, 1440);
    }
    if (field == 'url' &&
        (!['http', 'https'].contains(Uri.tryParse(value)?.scheme) ||
            Uri.tryParse(value)?.host.isEmpty != false)) {
      return 'Use an HTTP or HTTPS website URL.';
    }
    if (field == 'body' && value.length > 500) {
      return 'Use at most 500 characters.';
    }
    if (['startTime', 'endTime'].contains(field) &&
        value.isNotEmpty &&
        !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
      return 'Use HH:MM (24-hour time).';
    }
    return null;
  }

  Future<void> export() async {
    try {
      final data = await ref
          .read(workspaceRepositoryProvider)
          .get('/api/resources/report/export');
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(
                utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
              ),
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: ['family-report.json'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    }
  }

  Future<void> action(Map<String, dynamic> row, String operation) async {
    if (operation == 'details') {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(row['name'].toString()),
          content: SingleChildScrollView(child: RecordDetails(row)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    if (operation == 'edit') {
      await edit(row);
      return;
    }
    if (!can(operation)) return;
    if (!await confirmAction(
      context,
      '$operation record?',
      operation == 'delete'
          ? 'Archive this record? Audit history is retained.'
          : 'Save $operation for ${row['name']}? ${feature.notice ?? ''}',
    )) {
      return;
    }
    if (!mounted) return;
    await run(() async {
      if (operation == 'delete') {
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
    ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(feature.title),
        actions: [
          if (widget.module == 'report' && can('export'))
            IconButton(
              onPressed: busy ? null : export,
              icon: const Icon(Icons.ios_share),
              tooltip: 'Export family report',
            ),
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: can('create')
          ? FloatingActionButton(
              onPressed: busy ? null : edit,
              tooltip: 'Add record',
              child: const Icon(Icons.add),
            )
          : null,
      body: loading
          ? LoadingView(message: 'Loading ${feature.title}...')
          : error != null
          ? ErrorView(message: error!, onRetry: load)
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (feature.notice != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withAlpha(50)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature.notice!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search records',
                      hintText: 'Search ${feature.title.toLowerCase()}...',
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                    onChanged: (v) => setState(() => search = v.toLowerCase()),
                  ),
                  const SizedBox(height: 16),
                  if (rows.isEmpty)
                    EmptyState(
                      title: 'No ${feature.title}',
                      message: 'No records found for ${feature.title.toLowerCase()}.',
                      icon: Icons.folder_open_rounded,
                      actionLabel: can('create') ? 'Add Record' : null,
                      onAction: can('create') ? edit : null,
                    ),
                  for (final row in rows.where(
                    (r) => '${r['name']} ${r['status']} ${r['data']}'
                        .toLowerCase()
                        .contains(search),
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.neutralBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '${row['name']}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (row['status'] != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryTint,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${row['status']}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (row['childId'] != null)
                                      Text(
                                        'Child #${row['childId']}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                                if ((row['data'] as Map?)?['notes'] != null &&
                                    ((row['data'] as Map)['notes'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${(row['data'] as Map)['notes']}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          onTap: () => action(row, 'details'),
                          trailing: PopupMenuButton<String>(
                            enabled: !busy,
                            onSelected: (v) => action(row, v),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'details',
                                child: Text('View details'),
                              ),
                              if (can('update'))
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                              for (final operation in [
                                'allow',
                                'block',
                                'restrict',
                                'manage',
                                'delete',
                              ].where(can))
                                PopupMenuItem(
                                  value: operation,
                                  child: Text(operation),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
