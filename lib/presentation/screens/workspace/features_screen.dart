import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/parent_features.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../providers/session_provider.dart';
import 'widgets/feature_hub_widgets.dart';

class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = ref.watch(sessionProvider).parent;
    final permissions = parent?.permissions ?? <String>{};
    final items = <FeatureHubItem>[
      if (parent?.can('child.view') == true ||
          parent?.can('child.create') == true)
        const FeatureHubItem(
          title: 'Children & profiles',
          description: 'Manage profiles, safety controls and device activity.',
          icon: Icons.family_restroom_rounded,
          path: '/family/children',
          color: Color(0xFFFF681A),
          art: FeatureArt.profiles,
        ),
      if (parent?.can('device.view') == true ||
          parent?.can('device.add') == true)
        const FeatureHubItem(
          title: 'Devices',
          description: 'View and manage all connected family devices.',
          icon: Icons.devices_rounded,
          path: '/family/devices',
          color: Color(0xFF176BFF),
          art: FeatureArt.devices,
        ),
      if (parent?.can('device.add') == true)
        const FeatureHubItem(
          title: 'Pair a child device',
          description: 'Connect a child device using a pairing code.',
          icon: Icons.qr_code_2_rounded,
          path: '/pairing',
          color: Color(0xFF00C587),
          art: FeatureArt.pairing,
        ),
      if (parent?.can('child.view') == true &&
          parent?.can('location.view') == true)
        const FeatureHubItem(
          title: 'Family map & distance',
          description: 'See reported locations and location freshness.',
          icon: Icons.location_on_outlined,
          path: '/family-map',
          color: Color(0xFF7945FF),
          art: FeatureArt.map,
        ),
      if (parent?.can('child.view') == true &&
          [
            'app.view',
            'control.view',
            'control.update',
            'screen_time.view',
            'location.view',
            'sos.view',
          ].any((permission) => parent!.can(permission)))
        const FeatureHubItem(
          title: 'Apps, location, SOS & approvals',
          description: 'Manage app usage, location permissions and approvals.',
          icon: Icons.shield_outlined,
          path: '/family/children',
          color: Color(0xFFFFAD08),
          art: FeatureArt.controls,
        ),
      if (parent?.can('sos.view') == true)
        const FeatureHubItem(
          title: 'SOS alerts & history',
          description: 'View emergency alerts and activity history.',
          icon: Icons.notifications_active_rounded,
          path: '/sos',
          color: Color(0xFFFF344E),
          art: FeatureArt.sos,
        ),
    ];
    final records = ParentFeature.all
        .where(
          (feature) =>
              feature.can(permissions, 'view') ||
              feature.can(permissions, 'create') ||
              feature.key == 'report' && feature.can(permissions, 'export'),
        )
        .toList();
    void open(FeatureHubItem item) => context.push(item.path);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF9),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FeaturesHero(),
                  if (items.isNotEmpty)
                    FeatureHubGrid(items: items, onOpen: open),
                  if (records.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    const Text(
                      'More features',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: featureInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FeatureHubGrid(
                      items: [
                        for (final feature in records)
                          FeatureHubItem(
                            title: feature.title,
                            description:
                                'Open ${feature.title.toLowerCase()} records.',
                            icon: feature.icon,
                            path: '/records/${feature.key}',
                            color: const Color(0xFFFF681A),
                          ),
                      ],
                      onOpen: open,
                    ),
                  ],
                  if (permissions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No Parent features are assigned to this account. Ask your administrator to update your role.',
                        style: TextStyle(
                          color: featureMuted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
