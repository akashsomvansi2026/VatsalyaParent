import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/child.dart';
import '../../../core/utils/child_location_status.dart';

Future<Child?> showChildSelectorSheet({
  required BuildContext context,
  required List<Child> children,
  required Child? selected,
  required bool Function(Child) isValid,
  bool synchronized = true,
}) {
  return showModalBottomSheet<Child>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChildSelectorSheet(
      children: children,
      selected: selected,
      isValid: isValid,
      synchronized: synchronized,
    ),
  );
}

class _ChildSelectorSheet extends StatefulWidget {
  const _ChildSelectorSheet({
    required this.children,
    required this.selected,
    required this.isValid,
    required this.synchronized,
  });

  final bool synchronized;
  final List<Child> children;
  final Child? selected;
  final bool Function(Child) isValid;

  @override
  State<_ChildSelectorSheet> createState() => _ChildSelectorSheetState();
}

class _ChildSelectorSheetState extends State<_ChildSelectorSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.children
        .where((c) => c.displayName.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.disabled,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Choose a child',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'Search children',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.muted,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: matches.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: AppColors.muted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No child matches your search.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final child = matches[i];
                      final isSel = widget.selected?.id == child.id;
                      return _ChildOption(
                        synchronized: widget.synchronized,
                        child: child,
                        isValid: widget.isValid(child),
                        isSelected: isSel,
                        onTap: () => Navigator.pop(context, child),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChildOption extends StatelessWidget {
  const _ChildOption({
    required this.child,
    required this.isValid,
    required this.isSelected,
    required this.synchronized,
    required this.onTap,
  });

  final Child child;
  final bool isValid;
  final bool isSelected;
  final bool synchronized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryTint : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  child.displayName.isEmpty
                      ? '?'
                      : child.displayName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
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
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: child.isOnline
                                ? AppColors.onlineDark
                                : AppColors.muted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            ChildLocationStatus.fromChild(
                              child,
                              synchronized: synchronized,
                            ).label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary)
              else
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
