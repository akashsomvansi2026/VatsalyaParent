import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/auth_colors.dart';
import '../../../core/theme/auth_typography.dart';

/// Footer link widget for navigation between auth flows
/// (e.g., "Don't have account? Sign up").
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.normalText,
    required this.actionText,
    required this.onActionPressed,
  });

  final String normalText;
  final String actionText;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: '$normalText ',
          style: AuthTypography.body(color: AuthColors.textSecondary),
          children: [
            TextSpan(
              text: actionText,
              style: AuthTypography.bodySemibold(color: AuthColors.textPrimary)
                  .copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AuthColors.textPrimary.withValues(
                      alpha: 0.4,
                    ),
                  ),
              recognizer: TapGestureRecognizer()..onTap = onActionPressed,
            ),
          ],
        ),
      ),
    );
  }
}
