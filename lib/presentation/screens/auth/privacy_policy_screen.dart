import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.push('/privacy'),
    icon: const Icon(Icons.privacy_tip_outlined, size: 18),
    label: const Text('Privacy Policy'),
  );
}

/// Public information page; opening it does not accept terms or enable tracking.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const sections = <({String title, String body})>[
    (
      title: 'About this policy',
      body:
          'Vatsalya Guard provides family safety tools through the Parent app, '
          'paired Child app and web portal. This policy explains the information '
          'these features process and the controls available to families. '
          'Use the service only for children and devices you are authorized to supervise. '
          'Explain location sharing and device supervision to your child in an age-appropriate way.',
    ),
    (
      title: 'Account and family information',
      body:
          'The service processes account details such as your name, email address '
          'and, when linked, mobile number. Child profiles, pairing information, '
          'device identifiers and family relationships associate a device with the '
          'correct Parent account. Passwords and access credentials are used to authenticate '
          'accounts; keep passwords, pairing codes and access tokens private.',
    ),
    (
      title: 'Location information',
      body:
          'When location sharing is enabled and the required permissions are granted, '
          'the Child app collects coordinates, capture time, reported accuracy and '
          'associated device information such as battery level. These reports support '
          'family maps, recorded location history, nearby configured places and safe-zone '
          'features. Location collection may continue while the app is in the background '
          'with a visible Android foreground-service notification, subject to platform restrictions. '
          'The Parent app may also request its own location for map and distance features.',
    ),
    (
      title: 'Location accuracy and offline operation',
      body:
          'A map marker represents a reported GPS fix, not a guarantee of a continuous '
          'live position. Accuracy and update frequency depend on permissions, GPS, '
          'network access, battery settings and device restrictions. The Child app may '
          'temporarily queue location reports on the device during a network interruption '
          'and upload them when connectivity returns. Their original capture times are retained. '
          'Nearby-place distances are approximate straight-line distances, not road distance or travel time.',
    ),
    (
      title: 'Device supervision and safety events',
      body:
          'Depending on enabled features and granted Android access, the service '
          'processes device model and software information, installed-app inventory, '
          'app usage summaries, control settings, permission and protection status, '
          'approval requests, and SOS or safe-zone events. This information supports '
          'the controls configured by an authorized Parent. Available protections vary '
          'by device and provisioning; installing the app does not guarantee every control is supported.',
    ),
    (
      title: 'Permissions and your choices',
      body:
          'Location permission supports location-based features. Camera access, where '
          'requested, supports QR pairing. Notification permission supports safety and '
          'account alerts. Child-device usage access and other special Android permissions '
          'support the specific supervision features explained during setup. '
          'You can review permissions in device settings and use available Parent controls '
          'to change tracking and notification settings. Managed-device restrictions may '
          'require the existing Parent approval process. A disconnected Child device '
          'cannot receive a newly changed Parent setting until it reconnects.',
    ),
    (
      title: 'Who can access family data',
      body:
          'Account roles, assigned permissions and family relationships determine '
          'which information an authenticated user can view or change. Parent, Distributor '
          'and administrator access is subject to these server-side checks; a role name '
          'alone does not give unrestricted access to child location. Avoid sharing '
          'screenshots, exported records or credentials with people who are not authorized to see them.',
    ),
    (
      title: 'Service providers and maps',
      body:
          'The service relies on hosting and database infrastructure. Where configured '
          'and enabled, Firebase Cloud Messaging processes device registration tokens '
          'and notification delivery information. Email or OTP providers process the '
          'information needed to deliver requested account messages. Map tile and '
          'geocoding and routing providers receive requests needed to display places '
          'or calculate routes, '
          'which may include network information and the map area or coordinates being requested. '
          'Route requests can include both the Parent and selected Child coordinates. '
          'Those providers apply their own privacy policies. Only enabled integrations are used.',
    ),
    (
      title: 'Storage and security',
      body:
          'Family records are stored by the configured backend. The apps also store '
          'session information, preferences, cached snapshots and pending updates on '
          'the device where needed. Storage protection depends on the platform; protect '
          'access to your device and browser profile. Use the intended HTTPS service '
          'address for network access. Authentication, permission checks and protected '
          'credential storage reduce risk, but no system can guarantee absolute security.',
    ),
    (
      title: 'Retention and deletion',
      body:
          'Some location history, caches and pending-update queues use rolling limits. '
          'These limits do not establish a fixed deletion period for all account data. '
          'Signing out, uninstalling an app, disabling tracking or removing a device '
          'does not by itself guarantee that historical backend records or backups are erased. '
          'For a data-access, correction or deletion request, contact the service operator '
          'through the support channel provided with your account. Request handling and '
          'any necessary retention must be confirmed by the operator.',
    ),
    (
      title: 'Children and responsible supervision',
      body:
          'Location and device information about children is sensitive. An authorized '
          'Parent or guardian should review the settings, explain what is collected and '
          'use only the features appropriate for their family. Do not use Vatsalya Guard '
          'for hidden surveillance, harassment or supervision of a person or device '
          'you are not authorized to manage. The app is not a substitute for direct '
          'care or emergency services.',
    ),
    (
      title: 'Questions and policy updates',
      body:
          'Use the Support feature available to your account, or the contact supplied '
          'by your service operator, for privacy questions and requests. Do not include '
          'passwords, OTPs or access tokens in support messages. This page may be updated '
          'as the service changes; review the date below and the current policy before '
          'enabling new features.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/terms');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your family’s information, explained',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Last updated: 14 October 2026'),
                const SizedBox(height: 24),
                for (final section in sections) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      section.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    section.body,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
