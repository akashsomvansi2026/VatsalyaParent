import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/auth_colors.dart';
import '../../../core/theme/auth_theme.dart';
import '../../../core/theme/auth_typography.dart';
import '../../../core/widgets/dialogs.dart';
import '../../providers/auth_ui_provider.dart';
import '../../widgets/auth/auth_checkbox.dart';
import '../../widgets/auth/auth_footer_link.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/circular_navigation_button.dart';
import '../../widgets/auth/password_strength_bar.dart';
import '../../widgets/auth/primary_peach_button.dart';

/// Premium iOS-inspired Sign Up Screen closely matching the reference design.
/// Preserves entered inputs and terms agreement across screen transitions.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    final signUpState = ref.read(signUpProvider);
    _nameController = TextEditingController(text: signUpState.fullName);
    _emailController = TextEditingController(text: signUpState.email);
    _passwordController = TextEditingController(text: signUpState.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    // Preserve current state before pushing
    ref.read(signUpProvider.notifier)
      ..updateFullName(_nameController.text)
      ..updateEmail(_emailController.text)
      ..updatePassword(_passwordController.text);

    final agreed = await context.push<bool>('/terms');
    if (agreed == true && mounted) {
      ref.read(signUpProvider.notifier).setTermsAccepted(true);
    }
  }

  Future<void> _handleCreateAccount() async {
    final notifier = ref.read(signUpProvider.notifier);
    notifier.setError(null);

    // Save field text
    notifier
      ..updateFullName(_nameController.text)
      ..updateEmail(_emailController.text)
      ..updatePassword(_passwordController.text);

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    final currentState = ref.read(signUpProvider);
    if (!currentState.isTermsAccepted) {
      HapticFeedback.mediumImpact();
      notifier.setError('Please agree to the Terms and Conditions to continue.');
      return;
    }

    FocusScope.of(context).unfocus();
    notifier.setLoading(true);

    try {
      // Simulate account creation & validation flow
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;
      showAppMessage(
        context,
        'Account created successfully! Welcome to the family.',
      );
      // Navigate to main application or login
      context.go('/');
    } catch (_) {
      if (mounted) {
        final message = 'Account creation failed. Please try again.';
        notifier.setError(message);
        showAppMessage(context, message, isError: true);
      }
    } finally {
      if (mounted) {
        notifier.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUpState = ref.watch(signUpProvider);
    final isSubmitting = signUpState.isLoading;

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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),

                          // Top Circular Badge (+) + Serif Title + Subtitle
                          AuthHeader(
                            badge: CircularNavigationButton.signUpBadge(),
                            title: 'Create account',
                            subtitle:
                                'Create your account and get started with us.',
                          ),

                          const SizedBox(height: 32),

                          // Full Name Input Field
                          AuthTextField(
                            hintText: 'Full Name',
                            controller: _nameController,
                            focusNode: _nameFocus,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            onChanged: (val) {
                              ref
                                  .read(signUpProvider.notifier)
                                  .updateFullName(val);
                            },
                            onFieldSubmitted: (_) {
                              _emailFocus.requestFocus();
                            },
                            validator: (value) {
                              final name = value?.trim() ?? '';
                              if (name.isEmpty) {
                                return 'Full name is required';
                              }
                              if (name.length < 2) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Email Input Field
                          AuthTextField(
                            hintText: 'Email',
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            onChanged: (val) {
                              ref
                                  .read(signUpProvider.notifier)
                                  .updateEmail(val);
                            },
                            onFieldSubmitted: (_) {
                              _passwordFocus.requestFocus();
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

                          const SizedBox(height: 14),

                          // Password Input Field with Visibility Toggle
                          AuthTextField(
                            hintText: 'Password',
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onChanged: (val) {
                              ref
                                  .read(signUpProvider.notifier)
                                  .updatePassword(val);
                            },
                            onFieldSubmitted: (_) {
                              if (!isSubmitting) _handleCreateAccount();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          // Password Strength Bar
                          PasswordStrengthBar(
                            strength: signUpState.passwordStrength,
                          ),

                          const SizedBox(height: 18),

                          // Checkbox & Terms clickable link
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: AuthCheckbox(
                                  value: signUpState.isTermsAccepted,
                                  onChanged: isSubmitting
                                      ? null
                                      : (val) {
                                          ref
                                              .read(signUpProvider.notifier)
                                              .setTermsAccepted(val);
                                        },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'I agree with our ',
                                    style: AuthTypography.body(
                                      color: AuthColors.textSecondary,
                                    ).copyWith(fontSize: 13),
                                    children: [
                                      TextSpan(
                                        text: 'Terms',
                                        style: AuthTypography.bodySemibold(
                                          color: AuthColors.textPrimary,
                                        ).copyWith(
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AuthColors
                                              .textPrimary
                                              .withValues(alpha: 0.4),
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _openTerms,
                                      ),
                                      TextSpan(
                                        text: ' and ',
                                        style: AuthTypography.body(
                                          color: AuthColors.textSecondary,
                                        ).copyWith(fontSize: 13),
                                      ),
                                      TextSpan(
                                        text: 'Conditions',
                                        style: AuthTypography.bodySemibold(
                                          color: AuthColors.textPrimary,
                                        ).copyWith(
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AuthColors
                                              .textPrimary
                                              .withValues(alpha: 0.4),
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _openTerms,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (signUpState.errorMessage != null) ...[
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
                                      signUpState.errorMessage!,
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

                          // Flexible spacer pushing the button towards bottom
                          const Spacer(),
                          const SizedBox(height: 32),

                          // Soft Peach Create Account Button
                          PrimaryPeachButton(
                            text: 'Create account',
                            isLoading: isSubmitting,
                            onPressed: _handleCreateAccount,
                          ),

                          const SizedBox(height: 20),

                          // Footer: "Already have an account? Sign in"
                          AuthFooterLink(
                            normalText: 'Already have account?',
                            actionText: 'Sign in',
                            onActionPressed: () {
                              if (!isSubmitting) {
                                context.pop();
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          // Subtle iOS Home Indicator bar
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
