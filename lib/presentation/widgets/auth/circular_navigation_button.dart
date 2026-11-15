import 'package:flutter/material.dart';
import '../../../core/theme/auth_colors.dart';

/// Circular icon badge or navigation button matching the reference design.
/// - When used as an app/screen badge (non-clickable header icon):
///   features soft peach fill with thin outline and thin icon (+ or ->).
/// - When used as a navigation back button:
///   provides smooth tactile tap feedback with peach fill.
class CircularNavigationButton extends StatefulWidget {
  const CircularNavigationButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 46.0,
    this.backgroundColor = AuthColors.primaryAccent,
    this.borderColor = AuthColors.iconBadgeBorder,
    this.iconColor = AuthColors.textPrimary,
    this.iconSize = 20.0,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final double iconSize;
  final String? tooltip;

  /// Factory for the Sign In header badge (Right arrow ->)
  factory CircularNavigationButton.signInBadge({double size = 48.0}) {
    return CircularNavigationButton(
      size: size,
      icon: const Icon(
        Icons.arrow_forward,
        size: 20,
        color: AuthColors.textPrimary,
      ),
      backgroundColor: AuthColors.primaryAccent,
      borderColor: AuthColors.iconBadgeBorder,
    );
  }

  /// Factory for the Create Account header badge (Plus +)
  factory CircularNavigationButton.signUpBadge({double size = 48.0}) {
    return CircularNavigationButton(
      size: size,
      icon: const Icon(Icons.add, size: 22, color: AuthColors.textPrimary),
      backgroundColor: AuthColors.primaryAccent,
      borderColor: AuthColors.iconBadgeBorder,
    );
  }

  /// Factory for a Back navigation button with iOS-inspired arrow
  factory CircularNavigationButton.back({
    required VoidCallback onPressed,
    double size = 44.0,
  }) {
    return CircularNavigationButton(
      size: size,
      onPressed: onPressed,
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 18,
        color: AuthColors.textPrimary,
      ),
      backgroundColor: AuthColors.primaryAccent,
      borderColor: Colors.transparent,
      tooltip: 'Back',
    );
  }

  @override
  State<CircularNavigationButton> createState() =>
      _CircularNavigationButtonState();
}

class _CircularNavigationButtonState extends State<CircularNavigationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.onPressed != null;

    Widget badgeContent = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        shape: BoxShape.circle,
        border: widget.borderColor != Colors.transparent
            ? Border.all(color: widget.borderColor, width: 1.0)
            : null,
        boxShadow: isClickable
            ? const [
                BoxShadow(
                  color: Color(0x18242424),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(child: widget.icon),
    );

    if (!isClickable) {
      return badgeContent;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: widget.tooltip != null
            ? Tooltip(message: widget.tooltip!, child: badgeContent)
            : badgeContent,
      ),
    );
  }
}
