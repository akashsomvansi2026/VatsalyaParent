import 'package:flutter/material.dart';

const featureInk = Color(0xFF111729);
const featureMuted = Color(0xFF707C92);

enum FeatureArt { profiles, devices, pairing, map, controls, sos }

/// Presentation metadata; access decisions remain in the Riverpod screen.
class FeatureHubItem {
  const FeatureHubItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.path,
    required this.color,
    this.art,
  });
  final String title, description, path;
  final IconData icon;
  final Color color;
  final FeatureArt? art;
}

class FeaturesHero extends StatelessWidget {
  const FeaturesHero({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final artworkWidth = (constraints.maxWidth * .46).clamp(140.0, 260.0);
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6217),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Parent features',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFFF6217),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Care starts here',
            style: TextStyle(
              fontSize: 29,
              height: 1.1,
              letterSpacing: -.9,
              fontWeight: FontWeight.w800,
              color: featureInk,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Manage your family, build healthy habits and stay connected.',
            style: TextStyle(fontSize: 14, height: 1.45, color: featureMuted),
          ),
        ],
      );
      if (stacked) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: _FamilyArt(width: 160),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 162),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                bottom: -15,
                child: _FamilyArt(width: artworkWidth),
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: artworkWidth * .92,
                  bottom: 24,
                  top: 12,
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

class _FamilyArt extends StatelessWidget {
  const _FamilyArt({required this.width});
  final double width;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: width,
            height: width,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF0E7),
            ),
          ),
          Image.asset('assets/illustrations/family_portrait.png', width: width),
          Positioned(
            top: 2,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 20,
                color: Color(0xFFFF8B6F),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class FeatureHubGrid extends StatelessWidget {
  const FeatureHubGrid({super.key, required this.items, required this.onOpen});
  final List<FeatureHubItem> items;
  final ValueChanged<FeatureHubItem> onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = ((constraints.maxWidth + 10) / (140 * scale + 10))
          .floor()
          .clamp(1, 3);
      return Column(
        children: [
          for (var row = 0; row < items.length; row += columns) ...[
            if (row > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: 10),
                    Expanded(
                      child: row + col < items.length
                          ? FeatureHubCard(
                              item: items[row + col],
                              onTap: () => onOpen(items[row + col]),
                            )
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

class FeatureHubCard extends StatelessWidget {
  const FeatureHubCard({super.key, required this.item, required this.onTap});
  final FeatureHubItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 20,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      color: Color.alphaBlend(item.color.withValues(alpha: .045), Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -45,
              child: Container(
                width: 155,
                height: 115,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .045),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.color, size: 27),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: item.color.withValues(alpha: .065),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: featureInk,
                      letterSpacing: -.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: featureMuted,
                    ),
                  ),
                  if (item.art != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 64,
                      child: _CardArt(art: item.art!, color: item.color),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CardArt extends StatelessWidget {
  const _CardArt({required this.art, required this.color});
  final FeatureArt art;
  final Color color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: switch (art) {
      FeatureArt.profiles => LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            for (var i = 0; i < (constraints.maxWidth < 125 ? 2 : 3); i++)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: [
                    const Color(0xFFFFD99F),
                    const Color(0xFFFFCBE9),
                    const Color(0xFFFFE5CE),
                  ][i],
                  backgroundImage: const AssetImage(
                    'assets/illustrations/dashboard_child.png',
                  ),
                ),
              ),
            Icon(Icons.add_circle_rounded, color: color, size: 28),
          ],
        ),
      ),
      FeatureArt.controls => Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final icon in [
            Icons.grid_view_rounded,
            Icons.location_on,
            Icons.sos_rounded,
            Icons.settings_rounded,
          ])
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: icon == Icons.sos_rounded
                    ? Colors.redAccent
                    : featureInk,
              ),
            ),
        ],
      ),
      _ => Align(
        alignment: Alignment.bottomRight,
        child: SizedBox(width: 64, height: 64, child: _SheetArt(art: art)),
      ),
    },
  );
}

/// Draws one decorative quadrant from the illustration sheet without duplicating assets.
class _SheetArt extends StatelessWidget {
  const _SheetArt({required this.art});
  final FeatureArt art;
  @override
  Widget build(BuildContext context) {
    final alignment = switch (art) {
      FeatureArt.devices => Alignment.topLeft,
      FeatureArt.pairing => Alignment.topRight,
      FeatureArt.map => Alignment.bottomLeft,
      _ => Alignment.bottomRight,
    };
    return ClipRect(
      child: OverflowBox(
        alignment: alignment,
        maxWidth: 128,
        maxHeight: 128,
        child: Image.asset(
          'assets/illustrations/features_artwork.png',
          width: 128,
          height: 128,
          fit: BoxFit.fill,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
