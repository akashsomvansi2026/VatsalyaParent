import 'package:flutter/material.dart';
import '../../../data/models/parent_user.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.account,
    required this.onAddChild,
    required this.onOpenChildren,
    required this.onOpenPairing,
    required this.onOpenSos,
  });
  final ParentUser? account;
  final VoidCallback onAddChild, onOpenChildren, onOpenPairing, onOpenSos;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = ((constraints.maxWidth + 8) / (110 * textScale + 8))
            .floor()
            .clamp(1, 3);
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionCard(
              width: width,
              icon: Icons.search_rounded,
              accent: const Color(0xFFFF5715),
              title: 'Find child',
              subtitle: 'Locate in real-time',
              decoration: Icons.location_on_rounded,
              onTap: onAddChild,
            ),
            _ActionCard(
              width: width,
              icon: Icons.people_alt_rounded,
              accent: const Color(0xFF7153FF),
              title: 'My children',
              subtitle: 'Manage family',
              family: true,
              onTap: onOpenChildren,
            ),
            if (account?.can('device.add') == true)
              _ActionCard(
                width: width,
                icon: Icons.qr_code_2_rounded,
                accent: const Color(0xFF00B978),
                title: 'Pair device',
                subtitle: 'Connect new device',
                decoration: Icons.phonelink_setup_rounded,
                onTap: onOpenPairing,
              ),
          ],
        );
      },
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.width,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.decoration,
    this.family = false,
  });
  final double width;
  final IconData icon;
  final IconData? decoration;
  final Color accent;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool family;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, accent.withValues(alpha: .075)],
            ),
            border: Border.all(color: Colors.white),
          ),
          child: Stack(
            children: [
              if (family)
                Positioned(
                  right: -12,
                  bottom: -15,
                  child: Image.asset(
                    'assets/illustrations/family_portrait.png',
                    width: 65,
                    excludeFromSemantics: true,
                  ),
                ),
              if (decoration != null)
                Positioned(
                  right: 5,
                  top: 29,
                  child: Icon(
                    decoration,
                    color: accent.withValues(alpha: .85),
                    size: 37,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: accent, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF101329),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(10) * 2.6,
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF535A6C),
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: accent.withValues(alpha: .10),
                      child: Icon(Icons.arrow_forward, color: accent, size: 19),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
