import 'package:flutter/material.dart';
import '../../../core/theme/auth_colors.dart';
import '../../../core/theme/auth_typography.dart';
import 'auth_checkbox.dart';
import 'primary_peach_button.dart';

/// Sticky bottom acceptance panel for the Terms & Conditions screen.
/// Includes top divider, agreement checkbox, "Agree & Continue" button,
/// and privacy reassurance note.
class TermsAcceptanceFooter extends StatelessWidget {
  const TermsAcceptanceFooter({
    super.key,
    required this.isAccepted,
    required this.onChanged,
    required this.onAgreeAndContinue,
    this.isLoading = false,
  });

  final bool isAccepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onAgreeAndContinue;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuthColors.background,
        border: const Border(
          top: BorderSide(color: AuthColors.border, width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => onChanged(!isAccepted),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AuthCheckbox(value: isAccepted, onChanged: onChanged),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I have read and agree to the Terms & Conditions.',
                        style: AuthTypography.body(
                          color: AuthColors.textPrimary,
                        ).copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryPeachButton(
                text: 'Agree & Continue',
                isEnabled: isAccepted,
                isLoading: isLoading,
                onPressed: onAgreeAndContinue,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AuthColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your privacy matters to us.',
                    style: AuthTypography.caption(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
