import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FloatingMapControls extends StatelessWidget {
  const FloatingMapControls({
    super.key,
    required this.locating,
    required this.onLocate,
    required this.onFit,
  });

  final bool locating;
  final VoidCallback onLocate;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Fab(
          icon: locating ? null : Icons.my_location,
          busy: locating,
          tooltip: 'My location',
          onTap: locating ? null : onLocate,
        ),
        const SizedBox(height: 10),
        _Fab(
          icon: Icons.fit_screen_rounded,
          tooltip: 'Show everyone',
          onTap: onFit,
        ),
      ],
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.busy = false,
  });

  final IconData? icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(icon, color: AppColors.primary, size: 22),
          ),
        ),
      ),
    );
  }
}
