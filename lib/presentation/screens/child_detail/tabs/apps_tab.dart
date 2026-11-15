import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../providers/child_detail_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../widgets/real_app_icon.dart';
import '../../workspace/workspace_widgets.dart';

class AppsTab extends ConsumerStatefulWidget {
  const AppsTab({super.key, required this.childId});
  final int childId;
  @override
  ConsumerState<AppsTab> createState() => _AppsTabState();
}

class _AppsTabState extends ConsumerState<AppsTab> {
  String query = '', filter = 'all';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(childDetailProvider(widget.childId));
    final parent = ref.watch(sessionProvider).parent;
    final apps =
        state.apps.where((app) {
          final allowed = app.isAllowed && !app.isBlocked;
          return '${app.appName} ${app.packageName}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (filter == 'all' || (filter == 'allowed' ? allowed : !allowed));
        }).toList()..sort(
          (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search apps',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('All')),
            ButtonSegment(value: 'allowed', label: Text('Allowed')),
            ButtonSegment(value: 'blocked', label: Text('Blocked')),
          ],
          selected: {filter},
          onSelectionChanged: (v) => setState(() => filter = v.first),
        ),
        const SizedBox(height: 12),
        if (state.actionLoading) const LinearProgressIndicator(),
        if (apps.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No matching apps. Installed apps appear after the child device syncs.',
            ),
          ),
        for (final app in apps)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RealAppIcon(app: app, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.appName.isEmpty ? app.packageName : app.appName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              app.packageName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (app.isAllowed && !app.isBlocked)
                              ? AppColors.onlineTint
                              : AppColors.sosTint,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: (app.isAllowed && !app.isBlocked)
                                ? AppColors.online.withValues(alpha: 0.35)
                                : AppColors.sos.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          (app.isAllowed && !app.isBlocked)
                              ? 'Allowed'
                              : 'Blocked',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: (app.isAllowed && !app.isBlocked)
                                ? AppColors.onlineDark
                                : AppColors.sos,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Access allowed', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: app.isAllowed && !app.isBlocked,
                    onChanged:
                        !state.actionLoading &&
                            parent?.can('app.allow') == true &&
                            parent?.can('app.block') == true
                        ? (value) async {
                            try {
                              await ref
                                  .read(
                                    childDetailProvider(
                                      widget.childId,
                                    ).notifier,
                                  )
                                  .setAppPolicy(
                                    app.copyWith(
                                      isAllowed: value,
                                      isBlocked: !value,
                                    ),
                                  );
                            } catch (e) {
                              if (context.mounted) workspaceMessage(context, e);
                            }
                          }
                        : null,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.timer_outlined),
                    label: Text(
                      'Daily limit: ${Formatters.dailyLimit(app.dailyLimitMinutes)}',
                    ),
                    onPressed:
                        !state.actionLoading &&
                            parent?.can('app.restrict') == true
                        ? () async {
                            final values = await editValues(
                              context,
                              'Daily app limit',
                              [
                                EditorField(
                                  'minutes',
                                  'Minutes per day (0 = unlimited)',
                                  required: true,
                                  numeric: true,
                                  validate: (v) => int.tryParse(v) != null
                                      ? numberValidation(v, 0, 1440)
                                      : 'Enter whole minutes.',
                                ),
                              ],
                              initial: {'minutes': app.dailyLimitMinutes},
                            );
                            if (values == null || !mounted) return;
                            try {
                              await ref
                                  .read(
                                    childDetailProvider(
                                      widget.childId,
                                    ).notifier,
                                  )
                                  .setAppPolicy(
                                    app.copyWith(
                                      dailyLimitMinutes: int.parse(
                                        values['minutes']!,
                                      ),
                                    ),
                                  );
                            } catch (e) {
                              if (context.mounted) workspaceMessage(context, e);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        const Text(
          'Policies are saved to the shared backend. Enforcement depends on the child device connection and required Android permissions.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
