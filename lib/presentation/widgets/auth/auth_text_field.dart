import 'package:flutter/material.dart';
import '../../../core/theme/auth_colors.dart';
import '../../../core/theme/auth_typography.dart';

/// Pill-shaped text field (24px radius) matching the reference image.
/// Features clean white surface, soft elevation, active focus stroke,
/// and smooth inline validation / password toggle.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.autofillHints,
    this.autocorrect = false,
    this.focusNode,
    this.errorText,
    this.enabled = true,
  });

  final String hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final FocusNode? focusNode;
  final String? errorText;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _internalFocusNode;
  bool _isFocused = false;
  late bool _obscured;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _obscured = widget.isPassword ? true : widget.obscureText;
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  void didUpdateWidget(AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller?.text ?? widget.initialValue ?? '',
      validator: widget.validator,
      builder: (FormFieldState<String> state) {
        final hasError =
            (widget.errorText != null && widget.errorText!.isNotEmpty) ||
            state.hasError;
        final displayError = widget.errorText ?? state.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: AuthColors.inputBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasError
                      ? AuthColors.error
                      : _isFocused
                      ? AuthColors.borderFocused
                      : AuthColors.border.withValues(alpha: 0.7),
                  width: _isFocused || hasError ? 1.2 : 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isFocused
                        ? const Color(0x14242424)
                        : const Color(0x08000000),
                    blurRadius: _isFocused ? 12 : 8,
                    offset: const Offset(0, 3),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      if (widget.prefixIcon != null) ...[
                        widget.prefixIcon!,
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _effectiveFocusNode,
                          obscureText: widget.isPassword
                              ? _obscured
                              : widget.obscureText,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          autofillHints: widget.autofillHints,
                          autocorrect: widget.autocorrect,
                          enabled: widget.enabled,
                          cursorColor: AuthColors.textPrimary,
                          cursorWidth: 1.5,
                          cursorRadius: const Radius.circular(1),
                          style: AuthTypography.input(),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            labelText: widget.hintText,
                            hintStyle: AuthTypography.hint(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            state.didChange(val);
                            widget.onChanged?.call(val);
                          },
                          onSubmitted: widget.onFieldSubmitted,
                        ),
                      ),
                      if (widget.isPassword)
                        IconButton(
                          tooltip: _obscured
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () =>
                              setState(() => _obscured = !_obscured),
                          icon: Icon(
                            _obscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AuthColors.textSecondary,
                          ),
                        )
                      else if (widget.suffixIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: widget.suffixIcon!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasError && displayError != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: Text(
                  displayError,
                  style: const TextStyle(
                    color: AuthColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
