import 'package:flutter/material.dart';

/// A glyph identifying how a brand logo should be painted ([BrandLogo]).
///
/// Each value maps to a hand-drawn [CustomPainter] in [BrandLogo]. Keeping this
/// as a stable enum (never an index) means the catalog stays portable.
enum BrandGlyph {
  netflix,
  spotify,
  youtube,
  amazonPrime,
  disneyPlus,
  appleMusic,
  chatGpt,
  googleOne,
  microsoft365,
  playstation,
  xbox,
  adobe,
  gym,
  internet,
  mobile,
  generic,
}

/// A predefined subscription service shown in the picker (§1).
///
/// Brand marks are painted as vectors in the service's signature colour so the
/// app stays fully offline (no network, no bundled binary assets, no emoji).
class SubscriptionBrand {
  final String name;
  final String category;
  final int colorValue;
  final BrandGlyph glyph;

  const SubscriptionBrand({
    required this.name,
    required this.category,
    required this.colorValue,
    required this.glyph,
  });

  Color get color => Color(colorValue);

  /// The predefined services offered in the picker, in display order (§1).
  static const List<SubscriptionBrand> catalog = [
    SubscriptionBrand(name: 'Netflix', category: 'Streaming', colorValue: 0xFFE50914, glyph: BrandGlyph.netflix),
    SubscriptionBrand(name: 'Spotify', category: 'Music', colorValue: 0xFF1DB954, glyph: BrandGlyph.spotify),
    SubscriptionBrand(name: 'YouTube Premium', category: 'Streaming', colorValue: 0xFFFF0000, glyph: BrandGlyph.youtube),
    SubscriptionBrand(name: 'Amazon Prime', category: 'Shopping', colorValue: 0xFF00A8E1, glyph: BrandGlyph.amazonPrime),
    SubscriptionBrand(name: 'Disney+', category: 'Streaming', colorValue: 0xFF0F1689, glyph: BrandGlyph.disneyPlus),
    SubscriptionBrand(name: 'Apple Music', category: 'Music', colorValue: 0xFFFA243C, glyph: BrandGlyph.appleMusic),
    SubscriptionBrand(name: 'ChatGPT Plus', category: 'AI', colorValue: 0xFF10A37F, glyph: BrandGlyph.chatGpt),
    SubscriptionBrand(name: 'Google One', category: 'Cloud', colorValue: 0xFF4285F4, glyph: BrandGlyph.googleOne),
    SubscriptionBrand(name: 'Microsoft 365', category: 'Productivity', colorValue: 0xFFD83B01, glyph: BrandGlyph.microsoft365),
    SubscriptionBrand(name: 'PlayStation Plus', category: 'Gaming', colorValue: 0xFF0070D1, glyph: BrandGlyph.playstation),
    SubscriptionBrand(name: 'Xbox Game Pass', category: 'Gaming', colorValue: 0xFF107C10, glyph: BrandGlyph.xbox),
    SubscriptionBrand(name: 'Adobe Creative Cloud', category: 'Design', colorValue: 0xFFFF0000, glyph: BrandGlyph.adobe),
    SubscriptionBrand(name: 'Gym membership', category: 'Fitness', colorValue: 0xFF00796B, glyph: BrandGlyph.gym),
    SubscriptionBrand(name: 'Internet / Wi-Fi', category: 'Utilities', colorValue: 0xFF5E35B1, glyph: BrandGlyph.internet),
    SubscriptionBrand(name: 'Mobile recharge', category: 'Utilities', colorValue: 0xFF00897B, glyph: BrandGlyph.mobile),
  ];

  /// Finds a predefined brand by (case-insensitive) name, or null if none.
  static SubscriptionBrand? byName(String name) {
    final lower = name.trim().toLowerCase();
    for (final b in catalog) {
      if (b.name.toLowerCase() == lower) return b;
    }
    return null;
  }
}
