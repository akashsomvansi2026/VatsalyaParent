import 'package:flutter/material.dart';

class FamilyGlanceCard extends StatelessWidget {
  const FamilyGlanceCard({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Material(
      key: const Key('choose-child'),
      color: const Color(0xFFFFF4E9),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(16) > 21;
            return SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned(
                    right: -16,
                    bottom: -32,
                    child: Container(
                      width: constraints.maxWidth * .62,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFDFBC),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  if (!largeText)
                    Positioned(
                      right: -10,
                      bottom: -4,
                      width: (constraints.maxWidth * .54).clamp(0.0, 240.0),
                      child: Image.asset(
                        'assets/illustrations/family_portrait.png',
                        excludeFromSemantics: true,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: largeText
                          ? constraints.maxWidth
                          : constraints.maxWidth > 600
                          ? constraints.maxWidth - 280
                          : constraints.maxWidth * .44,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR FAMILY',
                            style: TextStyle(
                              color: Color(0xFFFF5715),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              letterSpacing: .8,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your family, at a glance',
                            style: TextStyle(
                              color: Color(0xFF101329),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -.5,
                            ),
                          ),
                          SizedBox(height: 9),
                          Text(
                            'Stay connected, stay safe wherever they are.',
                            style: TextStyle(
                              color: Color(0xFF535A6C),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!largeText)
                    const Positioned(
                      right: 16,
                      top: 14,
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 31,
                        color: Color(0xFFFF661B),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
