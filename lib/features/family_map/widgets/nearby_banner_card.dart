import 'package:flutter/material.dart';

class NearbyBannerCard extends StatelessWidget {
  const NearbyBannerCard({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20FF6515),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFF6215),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5208), Color(0xFFFF9D3D)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    const CircleAvatar(
                      radius: 23,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.explore_rounded,
                        color: Color(0xFFFF5715),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEARBY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Find family & devices near you',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'See live location, stay connected, stay safe.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (constraints.maxWidth >= 480 &&
                        MediaQuery.textScalerOf(context).scale(14) < 21)
                      SizedBox(
                        width: 80,
                        height: 65,
                        child: Image.asset(
                          'assets/illustrations/family_portrait.png',
                          excludeFromSemantics: true,
                        ),
                      ),
                    const CircleAvatar(
                      radius: 17,
                      backgroundColor: Color(0xFFFFD9B2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFFF5715),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
