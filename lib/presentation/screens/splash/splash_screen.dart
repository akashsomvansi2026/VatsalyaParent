import 'package:vrajrani_tech_solution/branding/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/auth_colors.dart';
import '../../../core/theme/auth_theme.dart';
import '../../../core/theme/auth_typography.dart';

/// Premium iOS-inspired Splash Screen matching the warm off-white,
/// soft peach aesthetic of the authentication flow.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AuthTheme.lightSystemUiOverlay,
      child: Scaffold(
        backgroundColor: AuthColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Soft Peach Circular Badge with Shield
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AuthColors.primaryAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AuthColors.iconBadgeBorder,
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18242424),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: BrandMark(size: 40),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Luxury Serif Brand Heading
                        Text(
                          'Vatsalya',
                          style: AuthTypography.headingLarge().copyWith(
                            fontSize: 34,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Muted Subtitle
                        Text(
                          'Family Protection & Safety',
                          style: AuthTypography.subtitle(),
                        ),
                        const SizedBox(height: 36),

                        // Sleek minimal progress indicator
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AuthColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom iOS Home Indicator
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 135,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: AuthColors.homeIndicator.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
