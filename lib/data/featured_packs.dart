import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/models.dart';
import 'pokemon_featured_packs.dart';
import 'mtg_featured_packs.dart';
import 'onepiece_featured_packs.dart';
import 'yugioh_featured_packs.dart';
import 'gundam_featured_packs.dart';

/// Featured Pack tiers (separate from Riftbound sealed).
///
/// [millennium] and [divine] are Yu-Gi-Oh–only pack tiers (art under
/// `assets/featured_packs/yugioh/`). Other franchises stop at [mythic].
enum FeaturedPackTier {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
  millennium,
  divine,
}

extension FeaturedPackTierX on FeaturedPackTier {
  String get label => switch (this) {
        FeaturedPackTier.common => 'Common',
        FeaturedPackTier.uncommon => 'Uncommon',
        FeaturedPackTier.rare => 'Rare',
        FeaturedPackTier.epic => 'Epic',
        FeaturedPackTier.legendary => 'Legendary',
        FeaturedPackTier.mythic => 'Mythic',
        FeaturedPackTier.millennium => 'Millennium',
        FeaturedPackTier.divine => 'Divine',
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
        FeaturedPackTier.millennium => const [
            Color(0xFFFDE68A),
            Color(0xFF6D28D9),
            Color(0xFFEAB308),
          ],
        FeaturedPackTier.divine => const [
            Color(0xFFFFFBEB),
            Color(0xFFD4AF37),
            Color(0xFF0A0A0F),
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
            : id.startsWith('opfp_')
                ? 'onepiece'
                : id.startsWith('ygofp_')
                    ? 'yugioh'
                    : id.startsWith('gdfp_')
                        ? 'gundam'
                        : 'riftbound';
    return 'assets/featured_packs/$folder/pack_${tier.name}.png';
  }
}

/// Curated Featured Packs — Bindora instant-rip pricing tiers.
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
            'Deep-red legendary rip with bulk through Showcase. Signature '
            'grails stay rare outside pity. Exchange ≥50% candy if you dump.',
        priceUsd: 89.99,
        cardCount: kFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk / rare',
            priceRangeLabel: 'under \$25',
            percent: 52,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Epic',
            priceRangeLabel: '\$25 – \$80',
            percent: 28,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Showcase',
            priceRangeLabel: '\$80 – \$500',
            percent: 15,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Signature+',
            priceRangeLabel: '\$500+',
            percent: 5,
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
            'Full UNL pack shape — bulk through Signature Showcases. Highest '
            'ticket Riftbound Featured Pack; grails are rare without pity.',
        priceUsd: 179.99,
        cardCount: kFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk / rare',
            priceRangeLabel: 'under \$40',
            percent: 58,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Epic / showcase',
            priceRangeLabel: '\$40 – \$200',
            percent: 26,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Signature',
            priceRangeLabel: '\$200 – \$1000',
            percent: 12,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$1000+',
            percent: 4,
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

/// Featured packs for the active franchise.
/// [rotationSeed] rotates order when the timed drop restocks.
List<FeaturedPackDef> featuredPacksFor(String gameId, {int rotationSeed = 0}) {
  final packs = switch (gameId) {
    'pokemon' => kPokemonFeaturedPacks,
    'mtg' => kMtgFeaturedPacks,
    'onepiece' => kOnePieceFeaturedPacks,
    'yugioh' => kYugiohFeaturedPacks,
    'gundam' => kGundamFeaturedPacks,
    _ => kFeaturedPacks,
  };
  if (packs.isEmpty || rotationSeed <= 0) return packs;
  final i = rotationSeed % packs.length;
  if (i == 0) return packs;
  return [...packs.sublist(i), ...packs.sublist(0, i)];
}

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
  for (final p in kOnePieceFeaturedPacks) {
    if (p.id == id) return p;
  }
  for (final p in kYugiohFeaturedPacks) {
    if (p.id == id) return p;
  }
  for (final p in kGundamFeaturedPacks) {
    if (p.id == id) return p;
  }
  return null;
}

/// Cheapest featured pack whose pool includes [setCode] cards.
FeaturedPackDef? featuredPackForSet({
  required String gameId,
  required String setCode,
  required List<CardDef> catalogCards,
  int rotationSeed = 0,
}) {
  FeaturedPackDef? best;
  for (final p in featuredPacksFor(gameId, rotationSeed: rotationSeed)) {
    final pool = p.poolSelector(catalogCards);
    if (!pool.any((e) => e.card.setCode == setCode)) continue;
    if (best == null || p.candyPrice < best.candyPrice) best = p;
  }
  return best;
}

/// Featured pack with the highest pity dry streak (for heat CTA).
FeaturedPackDef? hottestFeaturedPack({
  required String gameId,
  required Map<String, int> featuredPity,
  int rotationSeed = 0,
}) {
  final packs = featuredPacksFor(gameId, rotationSeed: rotationSeed);
  FeaturedPackDef? best;
  var bestDry = -1;
  for (final p in packs) {
    final dry = featuredPity[p.id] ?? 0;
    if (dry > bestDry) {
      bestDry = dry;
      best = p;
    }
  }
  return bestDry > 0 ? best : (packs.isEmpty ? null : packs.first);
}

bool _isPlayable(CardDef c) =>
    c.rarity != Rarity.token &&
    c.rarity != Rarity.none &&
    c.marketPrice > 0 &&
    !c.name.toLowerCase().contains('oversized');

bool _inSets(CardDef c, Set<String> codes) => codes.contains(c.setCode);

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
  return _weightByPrice(
    all.where((c) => c.setCode == 'OGN'),
    weightOf: (c) {
      if (c.rarity == Rarity.common) return 8;
      if (c.rarity == Rarity.uncommon && c.marketPrice < 4) return 5;
      if (c.rarity == Rarity.rare && c.marketPrice < 20) return 1.2;
      if (c.rarity == Rarity.epic && c.marketPrice < 40) return 0.25;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _uncommonPool(List<CardDef> all) {
  return _weightByPrice(
    all.where((c) => _inSets(c, const {'OGN', 'SFD'})),
    weightOf: (c) {
      if (c.rarity == Rarity.common) return 3;
      if (c.rarity == Rarity.uncommon) return 7;
      if (c.rarity == Rarity.rare) return 4;
      if (c.rarity == Rarity.epic && c.marketPrice < 80) return 0.8;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _rarePool(List<CardDef> all) {
  return _weightByPrice(
    all.where((c) => _inSets(c, const {'SFD', 'OGN'})),
    weightOf: (c) {
      if (c.rarity == Rarity.uncommon && c.marketPrice >= 1) return 2;
      if (c.rarity == Rarity.rare) return 8;
      if (c.rarity == Rarity.epic) return 4;
      if (c.rarity == Rarity.showcase && c.marketPrice < 200) return 0.6;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _epicPool(List<CardDef> all) {
  return _weightByPrice(
    all.where((c) => _inSets(c, const {'SFD', 'UNL'})),
    weightOf: (c) {
      if (c.rarity == Rarity.rare && c.marketPrice >= 5) return 2;
      if (c.rarity == Rarity.epic) return 8;
      if (c.rarity == Rarity.showcase && c.marketPrice < 500) {
        return c.marketPrice < 300 ? 2.5 : 1.0;
      }
      if (c.name.contains('Signature') && c.marketPrice < 800) return 0.35;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _legendaryPool(List<CardDef> all) {
  return _weightByPrice(
    all.where((c) => _inSets(c, const {'UNL', 'SFD'})),
    weightOf: (c) {
      if (c.rarity == Rarity.common) return 7;
      if (c.rarity == Rarity.uncommon) return 5;
      if (c.rarity == Rarity.rare) return 3.5;
      if (c.rarity == Rarity.epic && c.marketPrice < 25) return 1.6;
      if (c.rarity == Rarity.epic && c.marketPrice >= 25) return 0.9;
      if (c.rarity == Rarity.showcase) {
        if (c.name.contains('Signature')) {
          return c.marketPrice >= 500 ? 0.35 : 0.55;
        }
        if (c.name.contains('Overnumbered')) return 0.5;
        if (c.name.contains('Ultimate')) return 0.4;
        return c.marketPrice >= 80 ? 0.7 : 1.0;
      }
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _mythicPool(List<CardDef> all) {
  return _weightByPrice(all.where((c) => c.setCode == 'UNL'), weightOf: (c) {
    if (c.rarity == Rarity.common) return 9;
    if (c.rarity == Rarity.uncommon) return 7;
    if (c.rarity == Rarity.rare) return 4;
    if (c.rarity == Rarity.epic && c.marketPrice < 40) return 1.5;
    if (c.rarity == Rarity.epic && c.marketPrice >= 40) return 0.7;
    if (c.rarity != Rarity.showcase) return 0;
    if (c.name.contains('Signature')) {
      return c.marketPrice >= 1000 ? 0.25 : 0.45;
    }
    if (c.name.contains('Ultimate')) return 0.4;
    if (c.name.contains('Overnumbered')) return 0.5;
    if (c.marketPrice >= 100) return 0.55;
    return 0.9;
  });
}
