import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/session_provider.dart';

/// Shared entry points always use the signed-in Parent's permissions.
class ParentActions extends ConsumerWidget {
  const ParentActions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = ref.watch(sessionProvider).parent;
    if (parent == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.family_restroom, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${parent.name}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Your family, connected',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (parent.can('child.create'))
                    FilledButton.icon(
                      onPressed: () =>
                          context.push('/family/children?create=true'),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Add child'),
                    ),
                  if (parent.can('device.add'))
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 50),
                      ),
                      onPressed: () => context.push('/pairing'),
                      icon: const Icon(Icons.qr_code_2, size: 18),
                      label: const Text('Pair device'),
                    ),
                  if (parent.can('child.view'))
                    ActionChip(
                      avatar: const Icon(Icons.people_outline, size: 18, color: AppColors.primary),
                      backgroundColor: AppColors.primaryTint.withValues(alpha: 0.5),
                      side: const BorderSide(color: AppColors.cardBorder),
                      label: const Text('My children', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () => context.push('/family/children'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
