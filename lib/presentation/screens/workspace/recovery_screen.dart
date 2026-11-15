import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/infra_providers.dart';
import 'workspace_widgets.dart';

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({
    super.key,
    this.initialToken = '',
    this.initialMode = 'forgot-password',
  });
  final String initialToken, initialMode;
  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      token = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  late String mode = widget.initialMode;
  bool busy = false;
  String? message;
  @override
  void initState() {
    super.initState();
    token.text = widget.initialToken;
  }

  @override
  void dispose() {
    email.dispose();
    token.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  bool get consume => ['verify-email', 'reset-password'].contains(mode);
  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (mode == 'reset-password' && password.text != confirm.text) {
      setState(() => message = 'Passwords do not match.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final value = token.text.trim();
      final uri = Uri.tryParse(value);
      final actualToken = uri?.queryParameters['token'] ?? value;
      final result = await ref
          .read(workspaceRepositoryProvider)
          .save(
            '/admin/auth/$mode',
            consume
                ? {
                    'token': actualToken,
                    if (mode == 'reset-password') 'password': password.text,
                    if (mode == 'reset-password')
                      'confirmPassword': confirm.text,
                  }
                : {'email': email.text.trim().toLowerCase()},
          );
      if (mounted) {
        setState(
          () => message = result['message']?.toString() ?? 'Request complete.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account recovery')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Account Recovery',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reset your password or confirm account verification',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Action'),
                      items: const [
                        DropdownMenuItem(
                          value: 'forgot-password',
                          child: Text('Request password reset email'),
                        ),
                        DropdownMenuItem(
                          value: 'resend-verification',
                          child: Text('Request verification email'),
                        ),
                        DropdownMenuItem(
                          value: 'verify-email',
                          child: Text('Verify email link'),
                        ),
                        DropdownMenuItem(
                          value: 'reset-password',
                          child: Text('Set new password'),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              mode = v!;
                              message = null;
                            }),
                    ),
                    const SizedBox(height: 18),
                    if (!consume)
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => emailValidation((v ?? '').trim()),
                      ),
                    if (consume)
                      TextFormField(
                        controller: token,
                        decoration: const InputDecoration(
                          labelText: 'Paste email link or 64-character token',
                          prefixIcon: Icon(Icons.key_outlined),
                        ),
                        validator: (v) {
                          final raw = (v ?? '').trim();
                          final value =
                              Uri.tryParse(raw)?.queryParameters['token'] ?? raw;
                          return value.length == 64
                              ? null
                              : 'Paste the full email link or token.';
                        },
                      ),
                    if (mode == 'reset-password') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (v) => passwordValidation(v ?? ''),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (v) =>
                            v == password.text ? null : 'Passwords do not match.',
                      ),
                    ],
                    if (message != null)
                      Container(
                        margin: const EdgeInsets.only(top: 18),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message!.contains('do not match') ||
                                  message!.toLowerCase().contains('error') ||
                                  message!.toLowerCase().contains('failed')
                              ? AppColors.errorBg
                              : AppColors.successBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: message!.contains('do not match') ||
                                    message!.toLowerCase().contains('error') ||
                                    message!.toLowerCase().contains('failed')
                                ? AppColors.error.withAlpha(40)
                                : AppColors.success.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              message!.contains('do not match') ||
                                      message!.toLowerCase().contains('error') ||
                                      message!.toLowerCase().contains('failed')
                                  ? Icons.error_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: message!.contains('do not match') ||
                                      message!.toLowerCase().contains('error') ||
                                      message!.toLowerCase().contains('failed')
                                  ? AppColors.error
                                  : AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                message!,
                                semanticsLabel: message,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: message!.contains('do not match') ||
                                          message!.toLowerCase().contains('error') ||
                                          message!.toLowerCase().contains('failed')
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Text(busy ? 'Please wait…' : 'Continue'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: busy ? null : () => context.go('/login'),
                      child: const Text('Back to sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
