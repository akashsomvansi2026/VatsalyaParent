import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/auth_colors.dart';
import '../../../core/widgets/dialogs.dart';
import '../../providers/auth_ui_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/auth/auth_checkbox.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/auth_landing_layout.dart';
import '../../widgets/auth/primary_peach_button.dart';
import 'privacy_policy_screen.dart';

/// Sign-in form using the shared branded authentication composition.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    final signInState = ref.read(signInProvider);
    _emailController = TextEditingController(text: signInState.email);
    _passwordController = TextEditingController(text: signInState.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final notifier = ref.read(signInProvider.notifier);
    notifier.setError(null);

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    FocusScope.of(context).unfocus();
    notifier.setLoading(true);

    try {
      await ref
          .read(sessionProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      context.go('/');
    } on AppException catch (e) {
      if (mounted) {
        notifier.setError(e.message);
        showAppMessage(context, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        final message = 'Sign in failed. Please check your credentials.';
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
    final signInState = ref.watch(signInProvider);
    final isSubmitting = signInState.isLoading;

    return AuthLandingLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Sign in to continue',
              subtitle: 'Welcome back to Vatsalya.',
            ),
            const SizedBox(height: 28),
            // Email Input Field
            AuthTextField(
              hintText: 'Email',
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: (val) {
                ref.read(signInProvider.notifier).updateEmail(val);
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

            const SizedBox(height: 16),

            // Password Input Field
            AuthTextField(
              hintText: 'Password',
              controller: _passwordController,
              focusNode: _passwordFocus,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onChanged: (val) {
                ref.read(signInProvider.notifier).updatePassword(val);
              },
              onFieldSubmitted: (_) {
                if (!isSubmitting) _handleSignIn();
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

            const SizedBox(height: 18),

            // Row: Remember Me (Left) & Forgot Password? (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: isSubmitting
                      ? null
                      : () {
                          ref.read(signInProvider.notifier).toggleRememberMe();
                        },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      AuthCheckbox(
                        value: signInState.rememberMe,
                        onChanged: isSubmitting
                            ? null
                            : (_) {
                                ref
                                    .read(signInProvider.notifier)
                                    .toggleRememberMe();
                              },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AuthColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: isSubmitting
                      ? null
                      : () => context.push('/forgot-password'),
                  behavior: HitTestBehavior.opaque,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AuthColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            if (signInState.errorMessage != null) ...[
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
                        signInState.errorMessage!,
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

            const SizedBox(height: 32),

            // Soft Peach Sign In Button
            PrimaryPeachButton(
              text: 'Sign in',
              isLoading: isSubmitting,
              onPressed: _handleSignIn,
            ),

            const SizedBox(height: 20),

            // Footer: "Don't have an account? Sign up"
            /*        AuthFooterLink(
                            normalText: "Don't have an account?",
                            actionText: 'Sign up',
                            onActionPressed: () {
                              if (!isSubmitting) {
                                context.push('/signup');
                              }
                            },
                          ),
*/
            const SizedBox(height: 16),

            const PrivacyPolicyLink(),
          ],
        ),
      ),
    );
  }
}
