import 'package:flutter/material.dart';

/// Uses the same accessible Material interaction states as workspace actions.
class PrimaryPeachButton extends StatelessWidget {
  const PrimaryPeachButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.height = 54,
    this.width = double.infinity,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading, isEnabled;
  final double height, width;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: height),
    child: SizedBox(
      width: width,
      child: FilledButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: isLoading
              ? Semantics(
                  label: '$text in progress',
                  liveRegion: true,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Text(text, textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}
