import '../models/enums.dart';
import '../models/models.dart';
import 'featured_packs.dart';

/// Magic: The Gathering Featured Packs — same Instapack tier shape as Pokémon.
const int kMtgFeaturedPackCardCount = 6;

List<FeaturedPackDef> get kMtgFeaturedPacks => [
      FeaturedPackDef(
        id: 'mtgfp_starter_spells',
        tier: FeaturedPackTier.common,
        name: 'Starter Spells',
        blurb:
            'Budget Foundations / Bloomburrow rip. Mostly commons & uncommons '
            'with a slim shot at a spicy rare. 6 cards; last slot is the highlight.',
        priceUsd: 4.99,
        cardCount: kMtgFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk',
            priceRangeLabel: '\$0 – \$2',
            percent: 55,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Playable',
            priceRangeLabel: '\$2 – \$8',
            percent: 30,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$8 – \$40',
            percent: 12,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic+',
            priceRangeLabel: '\$40+',
            percent: 3,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'mtg_591769', oddsPercent: 1.2),
          FeaturedTopHit(cardId: 'mtg_590825', oddsPercent: 1.4),
          FeaturedTopHit(cardId: 'mtg_589425', oddsPercent: 1.6),
          FeaturedTopHit(cardId: 'mtg_558378', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'mtg_558683', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'mtg_558323', oddsPercent: 2.2),
        ],
        poolSelector: _starterPool,
      ),
      FeaturedPackDef(
        id: 'mtgfp_frontier_raids',
        tier: FeaturedPackTier.uncommon,
        name: 'Frontier Raids',
        blurb:
            'Outlaws & Aetherdrift mid-tier rip. Playable rares with a chance '
            'at borderless chases. 6 cards; highlight last.',
        priceUsd: 9.99,
        cardCount: kMtgFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk',
            priceRangeLabel: '\$0 – \$3',
            percent: 40,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mid',
            priceRangeLabel: '\$3 – \$15',
            percent: 38,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$15 – \$60',
            percent: 16,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Chase',
            priceRangeLabel: '\$60+',
            percent: 6,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'mtg_589446', oddsPercent: 1.5),
          FeaturedTopHit(cardId: 'mtg_590833', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'mtg_541391', oddsPercent: 2.4),
          FeaturedTopHit(cardId: 'mtg_559633', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'mtg_558586', oddsPercent: 3.2),
          FeaturedTopHit(cardId: 'mtg_591198', oddsPercent: 3.6),
        ],
        poolSelector: _frontierPool,
      ),
      FeaturedPackDef(
        id: 'mtgfp_mythic_horizons',
        tier: FeaturedPackTier.rare,
        name: 'Mythic Horizons',
        blurb:
            'MH3-weighted Instant rip. Loaded with mythics and borderless '
            'treatments — Eldrazi headline. Highlight last.',
        priceUsd: 24.99,
        cardCount: kMtgFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Filler',
            priceRangeLabel: '\$1 – \$8',
            percent: 26,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$8 – \$40',
            percent: 42,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$40 – \$150',
            percent: 24,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$150+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'mtg_558681', oddsPercent: 2.5),
          FeaturedTopHit(cardId: 'mtg_558319', oddsPercent: 3.0),
          FeaturedTopHit(cardId: 'mtg_558348', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'mtg_559157', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'mtg_555060', oddsPercent: 1.2),
          FeaturedTopHit(cardId: 'mtg_555059', oddsPercent: 0.8),
        ],
        poolSelector: _horizonsPool,
      ),
      FeaturedPackDef(
        id: 'mtgfp_eldrazi_breach',
        tier: FeaturedPackTier.epic,
        name: 'Eldrazi Breach',
        blurb:
            'Violet pack stacked with MH3 titans and raised foils. '
            'Chase Emrakul / Ulamog serials. 6 cards; highlight last.',
        priceUsd: 49.99,
        cardCount: kMtgFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$5 – \$25',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$25 – \$100',
            percent: 48,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Showcase',
            priceRangeLabel: '\$100 – \$500',
            percent: 24,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Serial',
            priceRangeLabel: '\$500+',
            percent: 6,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'mtg_541282', oddsPercent: 0.4),
          FeaturedTopHit(cardId: 'mtg_555059', oddsPercent: 0.6),
          FeaturedTopHit(cardId: 'mtg_614395', oddsPercent: 0.7),
          FeaturedTopHit(cardId: 'mtg_555060', oddsPercent: 0.9),
          FeaturedTopHit(cardId: 'mtg_559157', oddsPercent: 2.5),
          FeaturedTopHit(cardId: 'mtg_558348', oddsPercent: 3.0),
        ],
        poolSelector: _eldraziPool,
      ),
      FeaturedPackDef(
        id: 'mtgfp_serialized_storm',
        tier: FeaturedPackTier.legendary,
        name: 'Serialized Storm',
        blurb:
            'Deep-red legendary rip aimed at serials & raised foils. '
            'High EV highlight slot. Exchange ≥50% candy if you dump the rip.',
        priceUsd: 99.99,
        cardCount: kMtgFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$25 – \$100',
            percent: 28,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Showcase',
            priceRangeLabel: '\$100 – \$400',
            percent: 42,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Serial',
            priceRangeLabel: '\$400 – \$1500',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$1500+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'mtg_541282', oddsPercent: 1.1),
          FeaturedTopHit(cardId: 'mtg_555059', oddsPercent: 1.4),
          FeaturedTopHit(cardId: 'mtg_614395', oddsPercent: 1.6),
          FeaturedTopHit(cardId: 'mtg_555060', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'mtg_559157', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'mtg_558348', oddsPercent: 4.0),
        ],
        poolSelector: _serializedPool,
      ),
      FeaturedPackDef(
        id: 'mtgfp_planar_grails',
        tier: FeaturedPackTier.mythic,
        name: 'Planar Grails',
        blurb:
            'Prismatic chase pack — serial Eldrazi and mana-foil legends. '
            'Highest EV highlight of any MTG Featured Pack.',
        priceUsd: 179.99,
        cardCount: kMtgFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Showcase',
            priceRangeLabel: '\$100 – \$500',
            percent: 30,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Serial',
            priceRangeLabel: '\$500 – \$2000',
            percent: 40,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$2000+',
            percent: 20,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$40 – \$100',
            percent: 10,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'mtg_541282', oddsPercent: 2.2),
          FeaturedTopHit(cardId: 'mtg_555059', oddsPercent: 2.5),
          FeaturedTopHit(cardId: 'mtg_614395', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'mtg_555060', oddsPercent: 3.2),
          FeaturedTopHit(cardId: 'mtg_559157', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'mtg_558348', oddsPercent: 4.5),
        ],
        poolSelector: _planarPool,
      ),
    ];

bool _playable(CardDef c) =>
    c.rarity != Rarity.token &&
    c.rarity != Rarity.none &&
    c.marketPrice > 0 &&
    !c.name.toLowerCase().contains('token');

List<({CardDef card, double weight})> _weight(
  Iterable<CardDef> cards, {
  required double Function(CardDef) weightOf,
}) {
  final out = <({CardDef card, double weight})>[];
  for (final c in cards) {
    if (!_playable(c)) continue;
    final w = weightOf(c);
    if (w > 0) out.add((card: c, weight: w));
  }
  return out;
}

List<({CardDef card, double weight})> _starterPool(List<CardDef> all) {
  return _weight(all, weightOf: (c) {
    if (c.rarity == Rarity.common) return 8;
    if (c.rarity == Rarity.uncommon && c.marketPrice < 4) return 5;
    if (c.rarity == Rarity.rare && c.marketPrice < 25) return 1.2;
    if (c.rarity == Rarity.epic && c.marketPrice < 50) return 0.25;
    return 0;
  });
}

List<({CardDef card, double weight})> _frontierPool(List<CardDef> all) {
  return _weight(all, weightOf: (c) {
    if (c.rarity == Rarity.common) return 2;
    if (c.rarity == Rarity.uncommon) return 6;
    if (c.rarity == Rarity.rare) return 5;
    if (c.rarity == Rarity.epic && c.marketPrice < 120) return 1.0;
    return 0;
  });
}

List<({CardDef card, double weight})> _horizonsPool(List<CardDef> all) {
  return _weight(all, weightOf: (c) {
    if (c.rarity == Rarity.uncommon && c.marketPrice >= 1) return 2;
    if (c.rarity == Rarity.rare) return 7;
    if (c.rarity == Rarity.epic) return 5;
    if (c.marketPrice >= 100 && c.marketPrice < 500) return 0.8;
    return 0;
  });
}

List<({CardDef card, double weight})> _eldraziPool(List<CardDef> all) {
  return _weight(all, weightOf: (c) {
    if (c.rarity == Rarity.rare && c.marketPrice >= 5) return 2;
    if (c.rarity == Rarity.epic) {
      return c.marketPrice < 300 ? 6 : 2.5;
    }
    if (c.name.contains('Serial') || c.marketPrice >= 200) return 1.2;
    return 0;
  });
}

List<({CardDef card, double weight})> _serializedPool(List<CardDef> all) {
  return _weight(all, weightOf: (c) {
    if (c.rarity == Rarity.epic && c.marketPrice >= 25) return 3;
    if (c.name.contains('Serial') || c.name.contains('Raised Foil')) {
      return c.marketPrice >= 400 ? 5 : 2.5;
    }
    if (c.rarity == Rarity.epic) return 2;
    return 0;
  });
}

List<({CardDef card, double weight})> _planarPool(List<CardDef> all) {
  return _weight(all, weightOf: (c) {
    if (c.name.contains('Serial')) {
      return c.marketPrice >= 1000 ? 7 : 4;
    }
    if (c.rarity == Rarity.epic && c.marketPrice >= 80) return 3;
    if (c.marketPrice >= 150) return 2;
    return 0;
  });
}
