import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/auth_colors.dart';
import '../../../core/theme/auth_theme.dart';
import '../../../core/theme/auth_typography.dart';
import '../../providers/terms_provider.dart';
import '../../widgets/auth/circular_navigation_button.dart';
import '../../widgets/auth/terms_acceptance_footer.dart';
import '../../widgets/auth/terms_section.dart';
import 'privacy_policy_screen.dart';

/// Premium Terms & Conditions Screen designed as a seamless, elegant
/// extension of the authentication flow.
class TermsAndConditionsScreen extends ConsumerStatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  ConsumerState<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState
    extends ConsumerState<TermsAndConditionsScreen> {
  bool _isAccepted = false;
  bool _isSaving = false;
  String? _saveError;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Pre-populate acceptance state if already stored
    final accepted = ref.read(termsProvider);
    if (accepted == true) {
      _isAccepted = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAgreeAndContinue() async {
    if (!_isAccepted || _isSaving) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await ref.read(termsProvider.notifier).accept();
      if (!mounted) return;
      // If opened from a screen that can pop (e.g. SignUpScreen), pop back with true.
      // If opened as the first-time installation screen, proceed directly to /login!
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        try {
          context.go('/login');
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _saveError = 'Could not save your acceptance. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AuthTheme.lightSystemUiOverlay,
      child: Scaffold(
        backgroundColor: AuthColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (canPop)
                                  CircularNavigationButton.back(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  )
                                else
                                  const CircularNavigationButton(
                                    size: 44,
                                    icon: Icon(
                                      Icons.description_outlined,
                                      size: 20,
                                      color: AuthColors.textPrimary,
                                    ),
                                    backgroundColor: AuthColors.primaryAccent,
                                    borderColor: Colors.transparent,
                                  ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AuthColors.primaryAccent.withValues(
                                      alpha: 0.4,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Legal Agreement',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AuthColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'VATSALYA GUARD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: AuthColors.secondaryAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Terms & Conditions',
                              style: AuthTypography.headingLarge(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Please review our terms before continuing.',
                              style: AuthTypography.subtitle(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: AuthColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Last updated: October 2026',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AuthColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const _ReadingGuide(),
                      const SizedBox(height: 20),
                      // Notice Card for Legal Sample
                      const _PlaceholderNoticeCard(),
                      SizedBox(height: 24),

                      TermsSection(
                        number: 1,
                        title: 'Introduction',
                        content:
                            'Welcome to our platform. These Terms and Conditions govern your use of the mobile application and associated parental supervision services. By accessing or utilizing any part of the service, you agree to be legally bound by these terms.',
                      ),
                      TermsSection(
                        number: 2,
                        title: 'Acceptance of Terms',
                        content:
                            'By creating an account, downloading the software, or clicking "Agree & Continue", you confirm that you are at least 18 years of age (or the legal age of majority in your jurisdiction) and possess full legal capacity to enter into this agreement.',
                      ),
                      TermsSection(
                        number: 3,
                        title: 'Account Registration',
                        content:
                            'You agree to provide accurate, current, and complete information during registration. You must promptly update your credentials if changes occur. You are solely responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account.',
                      ),
                      TermsSection(
                        number: 4,
                        title: 'User Responsibilities',
                        content:
                            'This service is designed strictly for family safety and lawful supervision of devices belonging to minors under your parental guardianship or explicit authorized consent. You agree never to use the application to unlawfully track, monitor, or harass any individual without proper legal authorization.',
                      ),
                      TermsSection(
                        number: 5,
                        title: 'Privacy and Data Protection',
                        content:
                            'Your privacy and your children\'s digital safety matter. Location and device data are sent over an encrypted connection to the service so an authorized parent can view them. The service processes this data to provide safety features. Review the Privacy Policy for storage, access and retention details.',
                      ),
                      PrivacyPolicyLink(),
                      TermsSection(
                        number: 6,
                        title: 'Account Security',
                        content:
                            'You agree to immediately notify us of any unauthorized access, security compromise, or credential breach. We reserve the right to suspend or terminate accounts that show indicators of fraudulent, compromised, or abusive behavior.',
                      ),
                      TermsSection(
                        number: 7,
                        title: 'Acceptable Use',
                        content:
                            'You agree not to reverse engineer, decompile, modify, or distribute any aspect of the application codebase. You shall not employ automated scrapers, bots, or malicious payloads that could impair system stability or compromise server infrastructure.',
                      ),
                      TermsSection(
                        number: 8,
                        title: 'Intellectual Property',
                        content:
                            'All logos, trademarks, artwork, software, typography, and visual assets are the exclusive intellectual property of the service provider and protected under international copyright and trademark legislation.',
                      ),
                      TermsSection(
                        number: 9,
                        title: 'Limitation of Liability',
                        content:
                            'The application is provided "as is" and "as available". Location services and safety notifications depend on mobile network access, battery levels, satellite visibility, and server availability. Under no circumstance shall the service provider be held liable for indirect, incidental, or consequential damages.',
                      ),
                      TermsSection(
                        number: 10,
                        title: 'Termination of Services',
                        content:
                            'We reserve the right to suspend or discontinue services at any time, with or without notice, in the event of contractual breach or statutory requirements. You may terminate your account at any time via your account settings.',
                      ),
                      TermsSection(
                        number: 11,
                        title: 'Changes to Terms',
                        content:
                            'We periodically update these terms to reflect new features, security protocols, or legal guidelines. Any material modifications will be announced via in-app notification. Your continued usage after updates constitutes acceptance of the amended terms.',
                      ),
                      TermsSection(
                        number: 12,
                        title: 'Contact and Support',
                        content:
                            'If you have inquiries, questions regarding our legal practices, or need assistance exercising your privacy rights, please reach out directly to our dedicated legal and support desk at legal@familyguardian.app.',
                      ),
                    ],
                  ),
                ),
              ),

              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _saveError!,
                    style: const TextStyle(color: AuthColors.error),
                  ),
                ),
              // Sticky Bottom Acceptance Panel
              TermsAcceptanceFooter(
                isAccepted: _isAccepted,
                isLoading: _isSaving,
                onChanged: (val) {
                  if (_isSaving) return;
                  HapticFeedback.selectionClick();
                  setState(() => _isAccepted = val);
                },
                onAgreeAndContinue: _handleAgreeAndContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderNoticeCard extends StatelessWidget {
  const _PlaceholderNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AuthColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AuthColors.secondaryAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sample placeholder legal content provided for UI review. Must be evaluated by qualified legal counsel prior to commercial release.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AuthColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingGuide extends StatelessWidget {
  const _ReadingGuide();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AuthColors.primaryAccent,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.shield_outlined,
          color: AuthColors.secondaryAccent,
          size: 30,
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A safer start for your family',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Review how to use the service responsibly, protect your account and understand your privacy.',
                style: TextStyle(height: 1.5, color: AuthColors.textSecondary),
              ),
              SizedBox(height: 12),
              Text(
                '12 sections � Read at your own pace',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AuthColors.secondaryAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
