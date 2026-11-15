import 'package:flutter/material.dart';
import '../../../core/theme/auth_typography.dart';
import 'circular_navigation_button.dart';

/// Top header section for authentication screens:
/// Displays top centered circular badge (+ or ->),
/// large serif title, and centered subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onBack,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget? badge;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CircularNavigationButton.back(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        if (badge != null) ...[badge!, const SizedBox(height: 24)],
        Text(
          title,
          style: AuthTypography.headingLarge(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            subtitle,
            style: AuthTypography.subtitle(),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
