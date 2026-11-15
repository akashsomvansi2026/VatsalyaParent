import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onAddChild});
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryTint,
                  AppColors.primaryTint.withValues(alpha: 0.4),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Add your first child',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pair a device to start tracking their location and get peace of mind.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddChild,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add a child',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
