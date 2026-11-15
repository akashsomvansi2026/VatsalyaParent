import 'package:flutter/material.dart';

/// The shared family shield, with variants for neutral and brand surfaces.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32, this.onBrandSurface = false});

  final double size;
  final bool onBrandSurface;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = onBrandSurface
        ? 'logo-monochrome-white'
        : dark
            ? 'logo-symbol-dark'
            : 'logo-symbol';
    return Image.asset(
      'assets/branding/$asset.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
