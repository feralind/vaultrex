import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/models.dart';
import 'pokemon_featured_packs.dart';
import 'mtg_featured_packs.dart';

/// Featured Pack tiers (separate from Riftbound sealed).
enum FeaturedPackTier {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

extension FeaturedPackTierX on FeaturedPackTier {
  String get label => switch (this) {
        FeaturedPackTier.common => 'Common',
        FeaturedPackTier.uncommon => 'Uncommon',
        FeaturedPackTier.rare => 'Rare',
        FeaturedPackTier.epic => 'Epic',
        FeaturedPackTier.legendary => 'Legendary',
        FeaturedPackTier.mythic => 'Mythic',
      };

  /// Legacy flat path — prefer [FeaturedPackDef.assetPath] (franchise folders).
  String get assetPath =>
      'assets/featured_packs/riftbound/pack_$name.png';


  List<Color> get bloomColors => switch (this) {
        FeaturedPackTier.common => const [
            Color(0xFF86EFAC),
            Color(0xFF16A34A),
          ],
        FeaturedPackTier.uncommon => const [
            Color(0xFF67E8F9),
            Color(0xFF0E7490),
          ],
        FeaturedPackTier.rare => const [
            Color(0xFFFDE68A),
            Color(0xFFF97316),
            Color(0xFFF472B6),
          ],
        FeaturedPackTier.epic => const [
            Color(0xFFE9D5FF),
            Color(0xFF7C3AED),
            Color(0xFFDB2777),
          ],
        FeaturedPackTier.legendary => const [
            Color(0xFFFECACA),
            Color(0xFF7F1D1D),
            Color(0xFFD4AF37),
          ],
        FeaturedPackTier.mythic => const [
            Color(0xFFF9A8D4),
            Color(0xFF67E8F9),
            Color(0xFFFDE68A),
            Color(0xFFC084FC),
          ],
      };
}

/// Documented pull-rate row shown on the buy detail screen.
class FeaturedPullRateRow {
  const FeaturedPullRateRow({
    required this.tierLabel,
    required this.priceRangeLabel,
    required this.percent,
  });

  final String tierLabel;
  final String priceRangeLabel;
  final double percent;
}

/// A chase card shown in Top Hits with disclosed odds.
class FeaturedTopHit {
  const FeaturedTopHit({
    required this.cardId,
    required this.oddsPercent,
  });

  final String cardId;
  final double oddsPercent;
}

class FeaturedPackDef {
  const FeaturedPackDef({
    required this.id,
    required this.tier,
    required this.name,
    required this.blurb,
    required this.priceUsd,
    required this.cardCount,
    required this.pullRates,
    required this.topHitIds,
    required this.poolSelector,
  });

  final String id;
  final FeaturedPackTier tier;
  final String name;
  final String blurb;
  final double priceUsd;
  final int cardCount;
  final List<FeaturedPullRateRow> pullRates;
  final List<FeaturedTopHit> topHitIds;

  /// Builds the weighted draw pool for this pack from the live catalog.
  final List<({CardDef card, double weight})> Function(List<CardDef> all)
      poolSelector;

  int get candyPrice => (priceUsd * 100).round();

  String get assetPath {
    // Franchise folders. Riftbound uses the RIP Pack + twirl art set.
    final folder = id.startsWith('pkfp_')
        ? 'pokemon'
        : id.startsWith('mtgfp_')
            ? 'mtg'
            : 'riftbound';
    return 'assets/featured_packs/$folder/pack_${tier.name}.png';
  }
}

/// Curated Featured Packs — Vaultrex instant-rip pricing tiers.
/// mid-tier (~$10–$50) and premium chase (~$80–$180) digital rip products.
const int kFeaturedPackCardCount = 6;

List<FeaturedPackDef> get kFeaturedPacks => [
      FeaturedPackDef(
        id: 'fp_common',
        tier: FeaturedPackTier.common,
        name: 'Common Hits',
        blurb:
            'Budget Riftbound rip — mostly commons & uncommons with a chance at a spicy rare. '
            '6 cards; the last slot is always the highlight. Exchange all for ≥50% candy value.',
        priceUsd: 5.99,
        cardCount: kFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Common',
            priceRangeLabel: '\$0 – \$2',
            percent: 52,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Uncommon',
            priceRangeLabel: '\$2 – \$5',
            percent: 32,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$5 – \$20',
            percent: 12,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Epic+',
            priceRangeLabel: '\$20+',
            percent: 4,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'rb_653146', oddsPercent: 4.2),
          FeaturedTopHit(cardId: 'rb_652821', oddsPercent: 3.8),
          FeaturedTopHit(cardId: 'rb_653018', oddsPercent: 2.5),
          FeaturedTopHit(cardId: 'rb_652834', oddsPercent: 2.1),
          FeaturedTopHit(cardId: 'rb_652898', oddsPercent: 1.2),
          FeaturedTopHit(cardId: 'rb_652941', oddsPercent: 0.8),
        ],
        poolSelector: _commonPool,
      ),
      FeaturedPackDef(
        id: 'fp_uncommon',
        tier: FeaturedPackTier.uncommon,
        name: 'Uncommon Hits',
        blurb:
            'Teal-tier Instapack stacked with playable uncommons and mid rares. '
            '6 cards; last card is the guaranteed highlight pull.',
        priceUsd: 12.99,
        cardCount: kFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Common',
            priceRangeLabel: '\$0 – \$3',
            percent: 28,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Uncommon',
            priceRangeLabel: '\$2 – \$6',
            percent: 38,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$5 – \$25',
            percent: 26,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Epic+',
            priceRangeLabel: '\$25+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'rb_685589', oddsPercent: 5.0),
          FeaturedTopHit(cardId: 'rb_653018', oddsPercent: 4.4),
          FeaturedTopHit(cardId: 'rb_665592', oddsPercent: 3.6),
          FeaturedTopHit(cardId: 'rb_652898', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'rb_652941', oddsPercent: 2.2),
          FeaturedTopHit(cardId: 'rb_652812', oddsPercent: 0.9),
        ],
        poolSelector: _uncommonPool,
      ),
      FeaturedPackDef(
        id: 'fp_rare',
        tier: FeaturedPackTier.rare,
        name: 'Rare Hits',
        blurb:
            'Gold-foil chase pack aimed at rares and low epics. '
            'Modern Hits–style lineup with disclosed odds. Last slot = highlight.',
        priceUsd: 24.99,
        cardCount: kFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Uncommon',
            priceRangeLabel: '\$1 – \$5',
            percent: 18,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$5 – \$25',
            percent: 48,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Epic',
            priceRangeLabel: '\$25 – \$80',
            percent: 26,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Showcase',
            priceRangeLabel: '\$80+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'rb_652898', oddsPercent: 6.5),
          FeaturedTopHit(cardId: 'rb_652941', oddsPercent: 5.2),
          FeaturedTopHit(cardId: 'rb_652801', oddsPercent: 4.1),
          FeaturedTopHit(cardId: 'rb_652812', oddsPercent: 2.4),
          FeaturedTopHit(cardId: 'rb_653038', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'rb_652946', oddsPercent: 1.2),
        ],
        poolSelector: _rarePool,
      ),
      FeaturedPackDef(
        id: 'fp_epic',
        tier: FeaturedPackTier.epic,
        name: 'Epic Hits',
        blurb:
            'Violet pack loaded with Epics and mid Showcases. '
            'Chase Kai\'Sa Survivor, Baited Hook, and more. 6 cards, highlight last.',
        priceUsd: 49.99,
        cardCount: kFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$5 – \$25',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Epic',
            priceRangeLabel: '\$25 – \$80',
            percent: 48,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Showcase',
            priceRangeLabel: '\$80 – \$400',
            percent: 24,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Signature',
            priceRangeLabel: '\$400+',
            percent: 6,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'rb_652812', oddsPercent: 7.0),
          FeaturedTopHit(cardId: 'rb_653038', oddsPercent: 5.5),
          FeaturedTopHit(cardId: 'rb_652946', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'rb_652905', oddsPercent: 3.2),
          FeaturedTopHit(cardId: 'rb_653093', oddsPercent: 1.1),
          FeaturedTopHit(cardId: 'rb_653101', oddsPercent: 0.7),
        ],
        poolSelector: _epicPool,
      ),
      FeaturedPackDef(
        id: 'fp_legendary',
        tier: FeaturedPackTier.legendary,
        name: 'Legendary Hits',
        blurb:
            'Deep-red legendary rip aimed at expensive Showcases & Overnumbered alts. '
            'High EV highlight slot. Exchange ≥50% candy if you dump the rip.',
        priceUsd: 89.99,
        cardCount: kFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Epic',
            priceRangeLabel: '\$25 – \$80',
            percent: 20,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Showcase',
            priceRangeLabel: '\$80 – \$500',
            percent: 52,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Overnumbered',
            priceRangeLabel: '\$200 – \$600',
            percent: 18,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Signature',
            priceRangeLabel: '\$500+',
            percent: 10,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'rb_653093', oddsPercent: 4.8),
          FeaturedTopHit(cardId: 'rb_653101', oddsPercent: 4.2),
          FeaturedTopHit(cardId: 'rb_664881', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'rb_653100', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'rb_653116', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'rb_653098', oddsPercent: 1.1),
        ],
        poolSelector: _legendaryPool,
      ),
      FeaturedPackDef(
        id: 'fp_mythic',
        tier: FeaturedPackTier.mythic,
        name: 'Mythic Chase',
        blurb:
            'Prismatic chase pack — Signature Showcases and Ultimate grails. '
            'Highest EV highlight of any Featured Pack. 6 cards; last is always the chase.',
        priceUsd: 179.99,
        cardCount: kFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Showcase',
            priceRangeLabel: '\$100 – \$500',
            percent: 28,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Overnumbered',
            priceRangeLabel: '\$200 – \$600',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Signature',
            priceRangeLabel: '\$500 – \$2000',
            percent: 38,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$2000+',
            percent: 12,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'rb_653094', oddsPercent: 3.2),
          FeaturedTopHit(cardId: 'rb_664913', oddsPercent: 3.0),
          FeaturedTopHit(cardId: 'rb_653102', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'rb_685925', oddsPercent: 2.2),
          FeaturedTopHit(cardId: 'rb_664930', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'rb_653114', oddsPercent: 1.5),
        ],
        poolSelector: _mythicPool,
      ),
    ];

/// Featured packs for the active franchise (`riftbound` | `pokemon` | `mtg`).
List<FeaturedPackDef> featuredPacksFor(String gameId) => switch (gameId) {
      'pokemon' => kPokemonFeaturedPacks,
      'mtg' => kMtgFeaturedPacks,
      _ => kFeaturedPacks,
    };

FeaturedPackDef? featuredPackById(String id) {
  for (final p in kFeaturedPacks) {
    if (p.id == id) return p;
  }
  for (final p in kPokemonFeaturedPacks) {
    if (p.id == id) return p;
  }
  for (final p in kMtgFeaturedPacks) {
    if (p.id == id) return p;
  }
  return null;
}

bool _isPlayable(CardDef c) =>
    c.rarity != Rarity.token &&
    c.rarity != Rarity.none &&
    c.marketPrice > 0 &&
    !c.name.toLowerCase().contains('oversized');

List<({CardDef card, double weight})> _weightByPrice(
  Iterable<CardDef> cards, {
  required double Function(CardDef) weightOf,
}) {
  final out = <({CardDef card, double weight})>[];
  for (final c in cards) {
    if (!_isPlayable(c)) continue;
    final w = weightOf(c);
    if (w > 0) out.add((card: c, weight: w));
  }
  return out;
}

List<({CardDef card, double weight})> _commonPool(List<CardDef> all) {
  return _weightByPrice(all, weightOf: (c) {
    if (c.rarity == Rarity.common) return 8;
    if (c.rarity == Rarity.uncommon && c.marketPrice < 4) return 5;
    if (c.rarity == Rarity.rare && c.marketPrice < 20) return 1.2;
    if (c.rarity == Rarity.epic && c.marketPrice < 40) return 0.25;
    return 0;
  });
}

List<({CardDef card, double weight})> _uncommonPool(List<CardDef> all) {
  return _weightByPrice(all, weightOf: (c) {
    if (c.rarity == Rarity.common) return 3;
    if (c.rarity == Rarity.uncommon) return 7;
    if (c.rarity == Rarity.rare) return 4;
    if (c.rarity == Rarity.epic && c.marketPrice < 80) return 0.8;
    return 0;
  });
}

List<({CardDef card, double weight})> _rarePool(List<CardDef> all) {
  return _weightByPrice(all, weightOf: (c) {
    if (c.rarity == Rarity.uncommon && c.marketPrice >= 1) return 2;
    if (c.rarity == Rarity.rare) return 8;
    if (c.rarity == Rarity.epic) return 4;
    if (c.rarity == Rarity.showcase && c.marketPrice < 200) return 0.6;
    return 0;
  });
}

List<({CardDef card, double weight})> _epicPool(List<CardDef> all) {
  return _weightByPrice(all, weightOf: (c) {
    if (c.rarity == Rarity.rare && c.marketPrice >= 5) return 2;
    if (c.rarity == Rarity.epic) return 8;
    if (c.rarity == Rarity.showcase && c.marketPrice < 500) {
      return c.marketPrice < 300 ? 2.5 : 1.0;
    }
    if (c.name.contains('Signature') && c.marketPrice < 800) return 0.35;
    return 0;
  });
}

List<({CardDef card, double weight})> _legendaryPool(List<CardDef> all) {
  return _weightByPrice(all, weightOf: (c) {
    if (c.rarity == Rarity.epic && c.marketPrice >= 25) return 3;
    if (c.rarity == Rarity.showcase) {
      if (c.name.contains('Signature')) {
        return c.marketPrice >= 500 ? 2.5 : 1.2;
      }
      if (c.name.contains('Overnumbered')) return 3.5;
      if (c.name.contains('Ultimate')) return 1.5;
      return c.marketPrice >= 80 ? 4 : 1;
    }
    return 0;
  });
}

List<({CardDef card, double weight})> _mythicPool(List<CardDef> all) {
  return _weightByPrice(all, weightOf: (c) {
    if (c.rarity != Rarity.showcase && c.rarity != Rarity.epic) return 0;
    if (c.name.contains('Signature')) {
      return c.marketPrice >= 1000 ? 6 : 3.5;
    }
    if (c.name.contains('Ultimate')) return 5;
    if (c.name.contains('Overnumbered')) return 2.5;
    if (c.rarity == Rarity.showcase && c.marketPrice >= 100) return 2;
    if (c.rarity == Rarity.epic && c.marketPrice >= 40) return 0.8;
    return 0;
  });
}
