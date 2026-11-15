import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Horizontal battery bar + "🔋 N%" label, matching the portal.
class BatteryBar extends StatelessWidget {
  const BatteryBar({super.key, required this.battery});

  final int? battery;

  static Color _color(int? battery) {
    final value = battery ?? 0;
    if (value >= 50) return AppColors.batteryGreen;
    if (value >= 20) return AppColors.batteryAmber;
    return AppColors.batteryRed;
  }

  static IconData _icon(int? battery) {
    if (battery == null) return Icons.battery_unknown_rounded;
    if (battery >= 80) return Icons.battery_full_rounded;
    if (battery >= 50) return Icons.battery_5_bar_rounded;
    if (battery >= 20) return Icons.battery_3_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(battery);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: Formatters.batteryFraction(battery),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(_icon(battery), size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          Formatters.batteryLabel(battery),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
