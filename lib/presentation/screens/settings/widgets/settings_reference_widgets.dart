import 'package:flutter/material.dart';

const settingsInk = Color(0xFF111729);
const settingsMuted = Color(0xFF7B8391);

class SettingsHero extends StatelessWidget {
  const SettingsHero({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final artworkWidth = (constraints.maxWidth * .39).clamp(110.0, 180.0);
      const heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
              color: settingsInk,
              height: 1.15,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Make it yours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF434B5A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your account, preferences and app information.',
            style: TextStyle(fontSize: 14, height: 1.45, color: settingsMuted),
          ),
        ],
      );
      final art = ExcludeSemantics(
        child: Image.asset(
          'assets/illustrations/settings_shield.png',
          width: stacked ? 130 : artworkWidth,
        ),
      );
      if (stacked) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: art),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 140),
          child: Stack(
            children: [
              Positioned(right: 0, bottom: 0, child: art),
              Padding(
                padding: EdgeInsets.only(
                  right: artworkWidth + 4,
                  top: 10,
                  bottom: 12,
                ),
                child: heading,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.onTap,
    this.trailing,
    this.busy = false,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool busy;
  @override
  Widget build(BuildContext context) => _SettingsSurface(
    color: color,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 47,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .085),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                      color: titleColor ?? settingsInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: settingsMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (busy)
              Semantics(
                label: 'Action in progress',
                liveRegion: true,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              trailing ??
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: color.withValues(alpha: .065),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: color,
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}

class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.onTap,
  });
  final String name, email;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final initials = words.isEmpty
        ? 'P'
        : words.map((word) => word.characters.first.toUpperCase()).join();
    return _SettingsSurface(
      color: const Color(0xFFFF681A),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 29,
                  backgroundColor: const Color(0xFFFFDEC6),
                  child: Text(
                    initials,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD94A10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                        color: settingsInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF697184),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFFFF0E6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFF681A),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({required this.color, required this.child});
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.white, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SettingsWave(color)),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}

class _SettingsWave extends CustomPainter {
  const _SettingsWave(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .55, size.height)
      ..cubicTo(
        size.width * .8,
        size.height * .8,
        size.width * .7,
        size.height * .15,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: .035));
  }

  @override
  bool shouldRepaint(_SettingsWave oldDelegate) => oldDelegate.color != color;
}
