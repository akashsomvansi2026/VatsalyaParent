import 'package:vrajrani_tech_solution/branding/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/app_update/app_update.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../providers/infra_providers.dart';
import '../../providers/session_provider.dart';
import '../workspace/workspace_widgets.dart';
import 'widgets/settings_reference_widgets.dart';

final settingsPackageInfoProvider = FutureProvider.autoDispose<PackageInfo>(
  (ref) => ref
      .read(appUpdateProvider)
      .packageInfo()
      .timeout(const Duration(seconds: 5)),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  String? pending;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  Future<void> _perform(String action, Future<void> Function() work) async {
    if (pending != null) return;
    setState(() => pending = action);
    try {
      await work();
    } catch (error) {
      if (mounted) workspaceMessage(context, error);
    } finally {
      if (mounted) setState(() => pending = null);
    }
  }

  Future<void> _checkUpdates() => _perform('update', () async {
    final updates = ref.read(appUpdateProvider);
    await updates.check(manual: true);
    if (mounted && !updates.visible) {
      workspaceMessage(
        context,
        !updates.enabled
            ? 'Update checks are available in the Android app.'
            : updates.error ?? 'You are on the latest version.',
      );
    }
  });

  Future<void> _setNotifications(bool enabled) => _perform('push', () async {
    final push = ref.read(parentPushProvider);
    if (enabled) {
      await push.enable();
    } else {
      await push.disable();
    }
    if (mounted) workspaceMessage(context, push.status);
  });

  Future<void> _refreshAccount() => _perform('account', () async {
    await ref.read(sessionProvider.notifier).reloadAccount();
    if (mounted) workspaceMessage(context, 'Account refreshed.');
  });

  Future<void> _signOut() async {
    if (pending != null) return;
    if (await confirmAction(
          context,
          'Sign out?',
          'You will need to sign in again. Family data stored in memory will be cleared.',
        ) &&
        mounted) {
      await _perform(
        'logout',
        () => ref.read(sessionProvider.notifier).logout(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parent = ref.watch(sessionProvider).parent;
    final push = ref.watch(parentPushProvider);
    final info = ref.watch(settingsPackageInfoProvider);
    final package = info.value;
    final version = package == null
        ? info.isLoading
              ? 'Loading app version…'
              : 'Version unavailable'
        : 'Version ${package.version}';
    final enabled = pending == null;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF9),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0, .35, 1],
            colors: [Color(0xFFFFE9D9), Color(0xFFFAFAF9), Color(0xFFFAFAF9)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              ResponsiveContent(
                maxWidth: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SettingsHero(),
                    SettingsProfileCard(
                      name: parent?.name ?? 'Parent Account',
                      email: parent?.email ?? 'View profile & permissions',
                      onTap: () => context.push('/account'),
                    ),
                    SettingsActionTile(
                      icon: Icons.system_update_rounded,
                      color: const Color(0xFFFF681A),
                      title: 'Check for Updates',
                      subtitle: pending == 'update'
                          ? 'Checking installed version…'
                          : 'Get the latest app improvements',
                      busy: pending == 'update',
                      onTap: enabled ? _checkUpdates : null,
                    ),
                    SettingsActionTile(
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF165FE6),
                      title: 'All Parent features',
                      subtitle: 'Tools, controls and monitoring services',
                      onTap: () => context.go('/features'),
                    ),
                    SettingsActionTile(
                      icon: Icons.notifications_none_rounded,
                      color: const Color(0xFF8053EF),
                      title: 'Push notifications',
                      subtitle: push.status,
                      busy: pending == 'push',
                      trailing: Semantics(
                        label: 'Push notifications',
                        child: Switch.adaptive(
                          value: push.active,
                          onChanged: enabled ? _setNotifications : null,
                          activeTrackColor: const Color(0xFF8053EF),
                        ),
                      ),
                      onTap: enabled
                          ? () => _setNotifications(!push.active)
                          : null,
                    ),
                    SettingsActionTile(
                      icon: Icons.sync_rounded,
                      color: const Color(0xFF00A985),
                      title: 'Refresh account permissions',
                      subtitle: 'Sync roles and active device assignments',
                      busy: pending == 'account',
                      onTap: enabled ? _refreshAccount : null,
                    ),
                    SettingsActionTile(
                      icon: Icons.logout_rounded,
                      color: const Color(0xFFDB3324),
                      title: 'Sign out',
                      titleColor: const Color(0xFFCA271B),
                      subtitle: 'Sign out from this parent device',
                      busy: pending == 'logout',
                      onTap: enabled ? _signOut : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 10, left: 8),
                      child: Text(
                        'About',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: settingsMuted,
                        ),
                      ),
                    ),
                    SettingsActionTile(
                      icon: Icons.info_outline_rounded,
                      color: const Color(0xFF7B8391),
                      title: 'App information',
                      subtitle: version,
                      onTap: () => showAboutDialog(
                        applicationIcon: const BrandMark(size: 48),
                        context: context,
                        applicationName: 'Vatsalya Guard',
                        applicationVersion: package == null
                            ? 'Version unavailable'
                            : '${package.version} (${package.buildNumber})',
                        children: const [
                          Text(
                            'Parent workspace for staying connected with your family.',
                          ),
                        ],
                      ),
                    ),
                    SettingsActionTile(
                      icon: Icons.privacy_tip_outlined,
                      color: const Color(0xFF7B8391),
                      title: 'Privacy Policy',
                      subtitle:
                          'Family data, location sharing and your choices',
                      onTap: () => context.push('/privacy'),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Vatsalya Guard · Parent workspace',
                        style: TextStyle(fontSize: 12, color: settingsMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
