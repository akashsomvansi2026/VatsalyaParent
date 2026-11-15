import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/child_location_status.dart';
import '../../../data/models/child.dart';

class FamilyMembersSection extends StatelessWidget {
  const FamilyMembersSection({
    super.key,
    this.synchronized = true,
    required this.children,
    required this.selected,
    required this.onSelect,
  });

  final bool synchronized;
  final List<Child> children;
  final Child? selected;
  final ValueChanged<Child> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Family members',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${children.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _ChildTile(
              child: child,
              synchronized: synchronized,
              isSelected: selected?.id == child.id,
              onTap: () => onSelect(child),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({
    required this.child,
    required this.isSelected,
    required this.synchronized,
    required this.onTap,
  });

  final Child child;
  final bool isSelected;
  final bool synchronized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = ChildLocationStatus.fromChild(
      child,
      synchronized: synchronized,
    );
    return Material(
      color: isSelected ? AppColors.primaryTint : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: child.isOnline
                            ? AppColors.onlineDark
                            : AppColors.muted,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      child.displayName.isEmpty
                          ? '?'
                          : child.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: child.isOnline
                            ? AppColors.onlineDark
                            : AppColors.muted,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child.isOnline ? 'Online' : 'Offline'} · ${status.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
