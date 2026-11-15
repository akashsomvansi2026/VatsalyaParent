import 'package:flutter/material.dart';
import '../../../core/theme/auth_colors.dart';
import '../../providers/auth_ui_provider.dart';

/// Clean minimalist password strength indicator that provides immediate visual feedback.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.strength});

  final PasswordStrength strength;

  Color _getStrengthColor() {
    switch (strength) {
      case PasswordStrength.none:
        return Colors.transparent;
      case PasswordStrength.weak:
        return const Color(0xFFE57373);
      case PasswordStrength.medium:
        return const Color(0xFFFFB74D);
      case PasswordStrength.strong:
        return const Color(0xFF81C784);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.none) {
      return const SizedBox.shrink();
    }

    final color = _getStrengthColor();

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 1; i <= 3; i++)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color:
                          (i == 1 && strength != PasswordStrength.none) ||
                              (i == 2 &&
                                  (strength == PasswordStrength.medium ||
                                      strength == PasswordStrength.strong)) ||
                              (i == 3 && strength == PasswordStrength.strong)
                          ? color
                          : AuthColors.border.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strength.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const Text(
                'Min. 8 chars, 1 uppercase & 1 number',
                style: TextStyle(fontSize: 11, color: AuthColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
