import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/auth_colors.dart';
import '../../../core/theme/auth_theme.dart';
import '../../../core/theme/auth_typography.dart';
import '../../providers/auth_ui_provider.dart';
import '../../widgets/auth/auth_footer_link.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/circular_navigation_button.dart';
import '../../widgets/auth/primary_peach_button.dart';

/// Forgot Password screen following the minimalist iOS-inspired aesthetic.
/// Features input validation, smooth loading, and a success confirmation state.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final FocusNode _emailFocus = FocusNode();

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    final fpState = ref.read(forgotPasswordProvider);
    _emailController = TextEditingController(text: fpState.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    final notifier = ref.read(forgotPasswordProvider.notifier);
    notifier.setError(null);

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    FocusScope.of(context).unfocus();
    notifier.setLoading(true);

    try {
      // Simulate reset email dispatch
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      notifier.setSubmitted(true);
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (mounted) {
        notifier.setError('Unable to send reset email. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fpState = ref.watch(forgotPasswordProvider);
    final isSubmitting = fpState.isLoading;
    final isSubmitted = fpState.isSubmitted;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AuthTheme.lightSystemUiOverlay,
      child: Scaffold(
        backgroundColor: AuthColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AuthTheme.horizontalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: isSubmitted
                        ? _buildSuccessView(context, fpState.email)
                        : _buildFormView(context, isSubmitting, fpState),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    bool isSubmitting,
    ForgotPasswordState fpState,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Top Back Navigation
          Align(
            alignment: Alignment.centerLeft,
            child: CircularNavigationButton.back(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.pop();
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          // Header
          AuthHeader(
            title: 'Forgot password?',
            subtitle:
                'Enter your registered email address and we\'ll send you instructions to reset your password.',
          ),

          const SizedBox(height: 40),

          // Email Input Field
          AuthTextField(
            hintText: 'Email address',
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onChanged: (val) {
              ref.read(forgotPasswordProvider.notifier).updateEmail(val);
            },
            onFieldSubmitted: (_) {
              if (!isSubmitting) _handleSendResetLink();
            },
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return 'Email is required';
              }
              if (!_emailRegExp.hasMatch(email)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),

          if (fpState.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AuthColors.errorTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AuthColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AuthColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fpState.errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AuthColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),
          const SizedBox(height: 32),

          // Send Reset Link Button
          PrimaryPeachButton(
            text: 'Send Reset Link',
            isLoading: isSubmitting,
            onPressed: _handleSendResetLink,
          ),

          const SizedBox(height: 20),

          // Footer link to sign in
          AuthFooterLink(
            normalText: 'Remember your password?',
            actionText: 'Sign in',
            onActionPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.pop();
              }
            },
          ),

          const SizedBox(height: 16),

          // Bottom Indicator
          Center(
            child: Container(
              width: 135,
              height: 4.5,
              decoration: BoxDecoration(
                color: AuthColors.homeIndicator.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: CircularNavigationButton.back(
            onPressed: () {
              ref.read(forgotPasswordProvider.notifier).reset();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.pop();
              }
            },
          ),
        ),
        const Spacer(),

        // Success Card Container
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AuthColors.inputBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AuthColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AuthColors.primaryAccent,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 32,
                    color: AuthColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Check your email',
                style: AuthTypography.headingMedium(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'We\'ve dispatched instructions to reset your password to ',
                  style: AuthTypography.body(),
                  children: [
                    TextSpan(
                      text: email.isNotEmpty ? email : 'your email address',
                      style: AuthTypography.bodySemibold(),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  ref.read(forgotPasswordProvider.notifier).setSubmitted(false);
                },
                child: const Text(
                  'Didn\'t receive it? Try another email',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AuthColors.secondaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
        const SizedBox(height: 32),

        PrimaryPeachButton(
          text: 'Return to Sign in',
          onPressed: () {
            ref.read(forgotPasswordProvider.notifier).reset();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.pop();
            }
          },
        ),

        const SizedBox(height: 20),

        Center(
          child: Container(
            width: 135,
            height: 4.5,
            decoration: BoxDecoration(
              color: AuthColors.homeIndicator.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
