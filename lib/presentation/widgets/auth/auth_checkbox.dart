import 'package:flutter/material.dart';
import '../../../core/theme/auth_colors.dart';

/// Minimalist iOS-inspired checkbox with smooth selection animation.
class AuthCheckbox extends StatelessWidget {
  const AuthCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 20.0,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? AuthColors.secondaryAccent : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: value
                ? AuthColors.secondaryAccent
                : AuthColors.border.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x08000000),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: AnimatedScale(
            scale: value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Icon(
              Icons.check_rounded,
              size: size * 0.75,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
