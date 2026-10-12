import 'package:flutter/material.dart';

import '../models/subscription_brand.dart';

/// A clean, offline brand mark for a subscription service.
///
/// Renders the service's signature colour as a softly tinted rounded tile
/// with bold initials (never emoji, never a network image), so the picker
/// stays fully offline with consistent icon sizes and graceful fallback.
class BrandLogo extends StatelessWidget {
  final SubscriptionBrand brand;
  final double size;

  const BrandLogo({super.key, required this.brand, this.size = 44});

  /// Short 1-2 letter code identifying the brand (e.g. "N", "Yt", "365").
  String get _initials {
    switch (brand.glyph) {
      case BrandGlyph.netflix:
        return 'N';
      case BrandGlyph.spotify:
        return 'Sp';
      case BrandGlyph.youtube:
        return 'Yt';
      case BrandGlyph.amazonPrime:
        return 'a';
      case BrandGlyph.disneyPlus:
        return 'D+';
      case BrandGlyph.appleMusic:
        return 'A';
      case BrandGlyph.chatGpt:
        return 'Ai';
      case BrandGlyph.googleOne:
        return 'G';
      case BrandGlyph.microsoft365:
        return '365';
      case BrandGlyph.playstation:
        return 'Ps';
      case BrandGlyph.xbox:
        return 'X';
      case BrandGlyph.adobe:
        return 'Ae';
      case BrandGlyph.gym:
        return 'Gy';
      case BrandGlyph.internet:
        return 'Wi';
      case BrandGlyph.mobile:
        return 'Mo';
      case BrandGlyph.generic:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = brand.color;
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      label: '${brand.name} logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: base.withValues(alpha: dark ? 0.22 : 0.13),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(
            color: base.withValues(alpha: dark ? 0.55 : 0.35),
          ),
        ),
        child: Text(
          _initials,
          maxLines: 1,
          style: TextStyle(
            color: dark ? _lighten(base) : _darken(base),
            fontWeight: FontWeight.w800,
            fontSize: size * 0.36,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Color _lighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + 0.22).clamp(0.0, 1.0)).toColor();
  }

  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }
}
