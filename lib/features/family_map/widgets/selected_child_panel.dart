import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child.dart';
import '../../../core/utils/child_location_status.dart';

class SelectedChildPanel extends StatelessWidget {
  const SelectedChildPanel({
    super.key,
    this.synchronized = true,
    required this.child,
    required this.isValid,
    required this.parent,
    required this.routingBusy,
    required this.routeError,
    required this.distanceLabel,
    required this.onTap,
    required this.onLocate,
  });

  final bool synchronized;
  final Child child;
  final bool isValid;
  final Position? parent;
  final bool routingBusy;
  final String? routeError;
  final String? distanceLabel;
  final VoidCallback onTap;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(child: child),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _StatusLine(
                          child: child,
                          isValid: isValid,
                          synchronized: synchronized,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
              TextButton(
                onPressed: onTap,
                child: const Text('View child details'),
              ),
              if (isValid) ...[
                const SizedBox(height: 16),
                if (distanceLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            distanceLabel!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (parent == null)
                  _InlineAction(
                    icon: Icons.my_location_rounded,
                    label: 'Show my position',
                    onTap: onLocate,
                  ),
                if (routingBusy)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryTint,
                      ),
                    ),
                  ),
                if (routeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            routeError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Location unavailable right now.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.child});
  final Child child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.75),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            child.displayName.isEmpty
                ? '?'
                : child.displayName[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: child.isOnline ? AppColors.onlineDark : AppColors.muted,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.child,
    required this.isValid,
    required this.synchronized,
  });
  final bool synchronized;
  final Child child;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final text = ChildLocationStatus.fromChild(
      child,
      synchronized: synchronized,
    ).label;
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.muted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryTint.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
