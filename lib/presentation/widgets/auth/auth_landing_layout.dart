import 'package:vrajrani_tech_solution/branding/brand_mark.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Responsive authentication composition; authentication state stays in screens.
class AuthLandingLayout extends StatelessWidget {
  const AuthLandingLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF914D), Color(0xFFF56B19)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(28, 36, 28, 54),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            BrandMark(size: 30, onBrandSurface: true),
                            SizedBox(width: 10),
                            Text(
                              'VATSALYA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        Text(
                          'Closer to your family.\nEvery day.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Stay connected and care for your child, wherever life takes you.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14D85B16),
                        blurRadius: 36,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
