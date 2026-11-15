import 'package:flutter/material.dart';
import '../../../core/theme/auth_colors.dart';
import '../../../core/theme/auth_typography.dart';

/// Formatted legal terms section featuring a small peach circular badge for the number,
/// a semibold title, and comfortable, highly-readable body typography.
class TermsSection extends StatelessWidget {
  const TermsSection({
    super.key,
    required this.number,
    required this.title,
    required this.content,
    this.badgeSize = 28.0,
  });

  final int number;
  final String title;
  final String content;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AuthColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: const BoxDecoration(
                  color: AuthColors.primaryAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number.toString(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AuthColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: AuthTypography.sectionTitle()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: SelectableText(
              content,
              style: AuthTypography.body().copyWith(height: 1.65),
            ),
          ),
        ],
      ),
    );
  }
}
