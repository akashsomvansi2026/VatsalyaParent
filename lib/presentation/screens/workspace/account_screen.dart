import 'package:vrajrani_tech_solution/branding/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/infra_providers.dart';
import '../../providers/session_provider.dart';
import 'workspace_widgets.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  Map<String, dynamic>? profile;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      if (ref.read(sessionProvider).parent?.can('profile.view') == true) {
        final data = await ref.read(workspaceRepositoryProvider).profile();
        if (mounted) {
          setState(() {
            profile = data;
            error = null;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> edit(bool password) async {
    final result = await editValues(
      context,
      password ? 'Change password' : 'Edit profile',
      password
          ? [
              const EditorField(
                'current',
                'Current password',
                required: true,
                secret: true,
              ),
              const EditorField(
                'password',
                'New password',
                required: true,
                secret: true,
                validate: passwordValidation,
              ),
              const EditorField(
                'confirm',
                'Confirm password',
                required: true,
                secret: true,
              ),
            ]
          : [
              EditorField(
                'name',
                'Name',
                required: true,
                validate: (v) =>
                    v.length > 120 ? 'Use at most 120 characters.' : null,
              ),
            ],
      initial: {'name': ref.read(sessionProvider).parent?.name},
      notice: password
          ? 'Changing your password signs you out of existing sessions.'
          : null,
    );
    if (result == null || !mounted) return;
    if (password && result['password'] != result['confirm']) {
      workspaceMessage(context, 'Passwords do not match.');
      return;
    }
    setState(() => busy = true);
    try {
      final repo = ref.read(workspaceRepositoryProvider);
      if (password) {
        await repo.changePassword(
          result['current']!,
          result['password']!,
          result['confirm']!,
        );
        await ref.read(sessionProvider.notifier).logout();
      } else {
        await repo.updateProfile(result['name']!);
        await ref.read(sessionProvider.notifier).reloadAccount();
        await load();
      }
      if (mounted) workspaceMessage(context, 'Account updated.');
    } catch (e) {
      if (mounted) workspaceMessage(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parent = ref.watch(sessionProvider).parent;
    final permissions = (parent?.permissions.toList() ?? [])..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [BrandMark(size: 24), SizedBox(width: 8), Text('My account')]),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sosTint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sos.withValues(alpha: 0.2)),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.sos, fontSize: 13),
                ),
              ),
            ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parent?.name ?? 'Parent Account',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            parent?.email ?? '',
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
                if (profile != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  RecordDetails(profile!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (parent?.can('profile.update') == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.icon(
                onPressed: busy ? null : () => edit(false),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit profile'),
              ),
            ),
          if (parent?.can('password.change') == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => edit(true),
                icon: const Icon(Icons.lock_reset_outlined, size: 18),
                label: const Text('Change password'),
              ),
            ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.security, size: 20, color: AppColors.primary),
                ),
                title: const Text(
                  'Assigned permissions',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    '${permissions.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final permission in permissions)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              permission,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
