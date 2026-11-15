import 'package:vrajrani_tech_solution/branding/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/parent_user.dart';

const dashboardInk = Color(0xFF171829);
const dashboardMuted = Color(0xFF777B7A);
const dashboardOrange = Color(0xFFFF5708);

class DashboardSurface extends StatelessWidget {
  const DashboardSurface({
    super.key,
    required this.child,
    this.tint = Colors.white,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final Color tint;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFF0EEEB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class DashboardOrangeButton extends StatelessWidget {
  const DashboardOrangeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        colors: [Color(0xFFFF9B31), Color(0xFFFF5100), Color(0xFFE23B0C)],
      ),
    ),
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class DashboardReferenceHeader extends StatelessWidget {
  const DashboardReferenceHeader({
    super.key,
    required this.onRefresh,
    required this.refreshing,
  });
  final VoidCallback? onRefresh;
  final bool refreshing;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFFF6517), Color(0xFFD93B08), Color(0xFFFF7915)],
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: .35)),
              ),
              child: const BrandMark(size: 32, onBrandSurface: true),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -.4,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Your family at a glance',
                    style: TextStyle(color: Color(0xFFFFD8BC), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .08),
              ),
              icon: refreshing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.parent,
    required this.status,
    required this.statusColor,
  });
  final ParentUser? parent;
  final String status;
  final Color statusColor;
  @override
  Widget build(BuildContext context) => DashboardSurface(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final illustrated =
            constraints.maxWidth >= 320 &&
            MediaQuery.textScalerOf(context).scale(14) < 20;
        final actions = <Widget>[
          if (parent?.can('child.create') == true)
            DashboardOrangeButton(
              label: 'Add child',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => context.push('/family/children?create=true'),
            ),
          if (parent?.can('device.add') == true)
            _GreetingAction(
              label: 'Pair device',
              icon: Icons.qr_code_2,
              onTap: () => context.push('/pairing'),
            ),
          if (parent?.can('child.view') == true)
            _GreetingAction(
              label: 'My children',
              icon: Icons.people_outline_rounded,
              onTap: () => context.push('/family/children'),
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: illustrated ? 86 : 0),
              child: Stack(
                children: [
                  if (illustrated)
                    Positioned(
                      right: -8,
                      bottom: 0,
                      width: 96,
                      child: Opacity(
                        opacity: .9,
                        child: Image.asset(
                          'assets/illustrations/family_portrait.png',
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(right: illustrated ? 96 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 27,
                          backgroundColor: Color(0xFFFFDDC4),
                          child: Icon(
                            Icons.person_rounded,
                            color: dashboardOrange,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${parent?.name ?? 'Parent'}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: dashboardInk,
                                  letterSpacing: -.5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Your family, connected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dashboardMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Icon(
                                      Icons.circle,
                                      size: 7,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      status,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: dashboardMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (constraints.maxWidth >= 300 &&
                  MediaQuery.textScalerOf(context).scale(12) < 17)
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 7),
                      Expanded(child: actions[i]),
                    ],
                  ],
                )
              else
                Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        );
      },
    ),
  );
}

class _GreetingAction extends StatelessWidget {
  const _GreetingAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      foregroundColor: dashboardOrange,
      backgroundColor: const Color(0xFFFFF6EF),
      side: const BorderSide(color: Color(0xFFFFE8D9)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
    onPressed: onTap,
    icon: Icon(icon, size: 17),
    label: Text(label, textAlign: TextAlign.center),
  );
}

class DashboardSectionHeading extends StatelessWidget {
  const DashboardSectionHeading({
    super.key,
    required this.title,
    required this.action,
    this.onTap,
  });
  final String title, action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: dashboardInk,
            letterSpacing: -.7,
          ),
        ),
      ),
      if (onTap != null)
        Flexible(
          child: TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: dashboardOrange,
              padding: const EdgeInsets.only(left: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
    ],
  );
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });
  final String label, value, subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => DashboardSurface(
    tint: Color.alphaBlend(accent.withValues(alpha: .035), Colors.white),
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 37,
              height: 39,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 23),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: accent == const Color(0xFF00A66B)
                                ? const Color(0xFF15734F)
                                : dashboardInk,
                          ),
                        ),
                      ),
                      if (onTap != null)
                        Icon(Icons.chevron_right, color: accent, size: 17),
                    ],
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: dashboardInk,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.3,
                      color: dashboardMuted,
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

class DashboardEmptyChildren extends StatelessWidget {
  const DashboardEmptyChildren({super.key, this.onAdd});
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => DashboardSurface(
    tint: const Color(0xFFFFF7F1),
    padding: EdgeInsets.zero,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final illustrated =
            constraints.maxWidth >= 330 &&
            MediaQuery.textScalerOf(context).scale(14) < 20;
        return SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              if (illustrated)
                Positioned(
                  right: 1,
                  bottom: 0,
                  width: (constraints.maxWidth * .39).clamp(0.0, 190.0),
                  child: Image.asset(
                    'assets/illustrations/dashboard_child.png',
                    excludeFromSemantics: true,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: illustrated
                      ? constraints.maxWidth > 600
                            ? constraints.maxWidth - 230
                            : constraints.maxWidth * .59
                      : constraints.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No children paired yet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: dashboardInk,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add a child and pair their device to see their safety status.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: dashboardMuted,
                        ),
                      ),
                      if (onAdd != null) ...[
                        const SizedBox(height: 16),
                        DashboardOrangeButton(
                          label: 'Add child',
                          icon: Icons.person_add_alt_1_rounded,
                          onPressed: onAdd,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
