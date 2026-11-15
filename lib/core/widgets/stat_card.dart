import 'package:flutter/material.dart';

import 'app_card.dart';
import '../theme/app_colors.dart';

/// Small stat tile (portal's stats row): value, label and optional icon.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  Color get _iconColor {
    if (valueColor == AppColors.onlineDark || valueColor == AppColors.online) {
      return AppColors.onlineDark;
    }
    if (valueColor == AppColors.sos) {
      return AppColors.sos;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _iconColor),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: valueColor ?? AppColors.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
