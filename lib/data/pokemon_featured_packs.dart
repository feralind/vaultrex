import '../models/enums.dart';
import '../models/models.dart';
import 'featured_packs.dart';

/// Pokémon Featured Packs — RareCandy Instapack–inspired tiers mapped onto
/// Vaultrex Pokémon Featured Pack UI/mechanics.
///
/// Research notes (2026-07): packs.rarecandy.com requires auth; public odds
/// tables were unavailable. Pricing tiers taken from RareCandy Instapacks grid
/// (spark ≈ 100× USD). Pull bands are approximate digital-rip EV curves tuned
/// to catalog market prices (IR/SIR appear as [Rarity.epic] in pokemon_catalog).
///
/// RareCandy products referenced for naming/price shape:
/// - Kanto Friends (~$4.99 / 500)
/// - Roaring Waters (~$7.99 / 800)
/// - Rolling Thunder (~$19.99 / 2,000)
/// - Fire & Gold (~$29.99 / 3,000)
/// - Modern Grails (~$99.99 / 10,000)
/// - Mythical Grails (~$249.99 / 25,000)
/// - Themed set packs (151 / TWM / Paldea) aligned to mid-tier RC pricing
const int kPokemonFeaturedPackCardCount = 6;

List<FeaturedPackDef> get kPokemonFeaturedPacks => [
      FeaturedPackDef(
        id: 'pkfp_kanto_friends',
        tier: FeaturedPackTier.common,
        name: 'Kanto Friends',
        blurb:
            'Budget RareCandy-style rip from Scarlet & Violet—151. '
            'Mostly Commons & Rares with a slim shot at an IR/SIR. '
            '6 cards; last slot is the highlight.',
        priceUsd: 4.99,
        cardCount: kPokemonFeaturedPackCardCount,
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
            tierLabel: 'IR',
            priceRangeLabel: '\$8 – \$40',
            percent: 12,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SIR+',
            priceRangeLabel: '\$40+',
            percent: 3,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'pkm_517045', oddsPercent: 0.9),
          FeaturedTopHit(cardId: 'pkm_517046', oddsPercent: 1.4),
          FeaturedTopHit(cardId: 'pkm_517044', oddsPercent: 1.6),
          FeaturedTopHit(cardId: 'pkm_502556', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'pkm_517048', oddsPercent: 1.7),
          FeaturedTopHit(cardId: 'pkm_502549', oddsPercent: 1.9),
        ],
        poolSelector: _kantoFriendsPool,
      ),
      FeaturedPackDef(
        id: 'pkfp_roaring_waters',
        tier: FeaturedPackTier.uncommon,
        name: 'Roaring Waters',
        blurb:
            'Teal-tier water & Paldea splash pack. Mid singles with a chance '
            'at Magikarp IR / Raichu SIR–tier hits. 6 cards; highlight last.',
        priceUsd: 7.99,
        cardCount: kPokemonFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk',
            priceRangeLabel: '\$0 – \$3',
            percent: 42,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mid',
            priceRangeLabel: '\$3 – \$15',
            percent: 38,
          ),
          FeaturedPullRateRow(
            tierLabel: 'IR',
            priceRangeLabel: '\$15 – \$60',
            percent: 15,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Chase',
            priceRangeLabel: '\$60+',
            percent: 5,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'pkm_497606', oddsPercent: 1.1),
          FeaturedTopHit(cardId: 'pkm_497614', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'pkm_497629', oddsPercent: 2.2),
          FeaturedTopHit(cardId: 'pkm_497625', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'pkm_497689', oddsPercent: 3.0),
          FeaturedTopHit(cardId: 'pkm_497599', oddsPercent: 3.2),
        ],
        poolSelector: _roaringWatersPool,
      ),
      FeaturedPackDef(
        id: 'pkfp_rolling_thunder',
        tier: FeaturedPackTier.rare,
        name: 'Rolling Thunder',
        blurb:
            'Surging Sparks–weighted Instant rip. Loaded with electric chases '
            'and mid SIRs — Pikachu ex & Latias headline. Highlight last.',
        priceUsd: 19.99,
        cardCount: kPokemonFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Filler',
            priceRangeLabel: '\$1 – \$8',
            percent: 28,
          ),
          FeaturedPullRateRow(
            tierLabel: 'IR',
            priceRangeLabel: '\$8 – \$40',
            percent: 42,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SIR',
            priceRangeLabel: '\$40 – \$150',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$150+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'pkm_590027', oddsPercent: 2.4),
          FeaturedTopHit(cardId: 'pkm_589985', oddsPercent: 3.2),
          FeaturedTopHit(cardId: 'pkm_590006', oddsPercent: 3.8),
          FeaturedTopHit(cardId: 'pkm_593169', oddsPercent: 4.5),
          FeaturedTopHit(cardId: 'pkm_589967', oddsPercent: 5.0),
          FeaturedTopHit(cardId: 'pkm_589930', oddsPercent: 5.5),
        ],
        poolSelector: _rollingThunderPool,
      ),
      FeaturedPackDef(
        id: 'pkfp_twilight_masquerade',
        tier: FeaturedPackTier.epic,
        name: 'Twilight Masquerade',
        blurb:
            'Fire & Gold–priced TWM chase pack. Greninja ex SIR and Perrin '
            'headline disclosed odds. 6 cards; last is always the highlight.',
        priceUsd: 29.99,
        cardCount: kPokemonFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Filler',
            priceRangeLabel: '\$2 – \$10',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'IR',
            priceRangeLabel: '\$10 – \$50',
            percent: 40,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SIR',
            priceRangeLabel: '\$50 – \$200',
            percent: 28,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$200+',
            percent: 10,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'pkm_550258', oddsPercent: 2.2),
          FeaturedTopHit(cardId: 'pkm_550264', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'pkm_550232', oddsPercent: 4.5),
          FeaturedTopHit(cardId: 'pkm_550261', oddsPercent: 5.2),
          FeaturedTopHit(cardId: 'pkm_550231', oddsPercent: 5.8),
          FeaturedTopHit(cardId: 'pkm_550260', oddsPercent: 6.0),
        ],
        poolSelector: _twilightPool,
      ),
      FeaturedPackDef(
        id: 'pkfp_paldea_hits',
        tier: FeaturedPackTier.rare,
        name: 'Paldea Hits',
        blurb:
            'Paldea Evolved instant rip — Magikarp IR and Iono SIR-tier heat. '
            'RC mid-tier EV curve. 6 cards; highlight last.',
        priceUsd: 24.99,
        cardCount: kPokemonFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Filler',
            priceRangeLabel: '\$1 – \$8',
            percent: 25,
          ),
          FeaturedPullRateRow(
            tierLabel: 'IR',
            priceRangeLabel: '\$8 – \$40',
            percent: 44,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SIR',
            priceRangeLabel: '\$40 – \$150',
            percent: 23,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$150+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'pkm_497606', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'pkm_497614', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'pkm_497629', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'pkm_497625', oddsPercent: 4.8),
          FeaturedTopHit(cardId: 'pkm_497689', oddsPercent: 5.2),
          FeaturedTopHit(cardId: 'pkm_497599', oddsPercent: 5.5),
        ],
        poolSelector: _paldeaPool,
      ),
      FeaturedPackDef(
        id: 'pkfp_151_grails',
        tier: FeaturedPackTier.epic,
        name: '151 Chase',
        blurb:
            'Scarlet & Violet—151 chase pack. Charizard ex SIR headlines with '
            'starter IRs. Exchange ≥50% candy if you dump the rip.',
        priceUsd: 49.99,
        cardCount: kPokemonFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'IR',
            priceRangeLabel: '\$5 – \$40',
            percent: 30,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SIR',
            priceRangeLabel: '\$40 – \$150',
            percent: 42,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Big SIR',
            priceRangeLabel: '\$150 – \$400',
            percent: 20,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$400+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'pkm_517045', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'pkm_517046', oddsPercent: 5.0),
          FeaturedTopHit(cardId: 'pkm_517044', oddsPercent: 5.5),
          FeaturedTopHit(cardId: 'pkm_502556', oddsPercent: 6.0),
          FeaturedTopHit(cardId: 'pkm_517048', oddsPercent: 5.8),
          FeaturedTopHit(cardId: 'pkm_513721', oddsPercent: 6.2),
        ],
        poolSelector: _mewChasePool,
      ),
      FeaturedPackDef(
        id: 'pkfp_modern_grails',
        tier: FeaturedPackTier.legendary,
        name: 'Modern Grails',
        blurb:
            'RareCandy Modern Grails–tier rip across SV chases. High EV '
            'highlight aimed at \$80–\$500 SIRs. 6 cards; last is the chase.',
        priceUsd: 99.99,
        cardCount: kPokemonFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'IR+',
            priceRangeLabel: '\$25 – \$80',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SIR',
            priceRangeLabel: '\$80 – \$300',
            percent: 48,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Big SIR',
            priceRangeLabel: '\$300 – \$800',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$800+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'pkm_517045', oddsPercent: 3.8),
          FeaturedTopHit(cardId: 'pkm_550258', oddsPercent: 3.6),
          FeaturedTopHit(cardId: 'pkm_590027', oddsPercent: 3.4),
          FeaturedTopHit(cardId: 'pkm_497606', oddsPercent: 3.0),
          FeaturedTopHit(cardId: 'pkm_589985', oddsPercent: 4.2),
          FeaturedTopHit(cardId: 'pkm_550264', oddsPercent: 4.5),
        ],
        poolSelector: _modernGrailsPool,
      ),
      FeaturedPackDef(
        id: 'pkfp_mythical_grails',
        tier: FeaturedPackTier.mythic,
        name: 'Mythical Grails',
        blurb:
            'Prismatic Evolutions–weighted mythic rip. Umbreon / Sylveon SIRs '
            'and Eeveelution grails. Highest EV Featured Pack. Highlight last.',
        priceUsd: 179.99,
        cardCount: kPokemonFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'SIR',
            priceRangeLabel: '\$80 – \$300',
            percent: 28,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Big SIR',
            priceRangeLabel: '\$300 – \$800',
            percent: 36,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$800 – \$2000',
            percent: 26,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$2000+',
            percent: 10,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'pkm_610516', oddsPercent: 2.2),
          FeaturedTopHit(cardId: 'pkm_610511', oddsPercent: 3.0),
          FeaturedTopHit(cardId: 'pkm_610499', oddsPercent: 3.8),
          FeaturedTopHit(cardId: 'pkm_610510', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'pkm_610504', oddsPercent: 4.2),
          FeaturedTopHit(cardId: 'pkm_610505', oddsPercent: 4.4),
        ],
        poolSelector: _mythicalGrailsPool,
      ),
    ];

bool _playable(CardDef c) =>
    c.rarity != Rarity.token &&
    c.rarity != Rarity.none &&
    c.marketPrice > 0 &&
    c.number != null &&
    c.number!.isNotEmpty;

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

bool _inSets(CardDef c, Set<String> codes) => codes.contains(c.setCode);

/// Budget 151 pool — commons dominate; thin IR/SIR tail.
List<({CardDef card, double weight})> _kantoFriendsPool(List<CardDef> all) {
  return _weight(all.where((c) => c.setCode == 'MEW'), weightOf: (c) {
    if (c.rarity == Rarity.common && c.marketPrice < 3) return 10;
    if (c.rarity == Rarity.rare && c.marketPrice < 8) return 4;
    if (c.rarity == Rarity.epic && c.marketPrice < 40) return 1.2;
    if (c.rarity == Rarity.epic && c.marketPrice < 120) return 0.35;
    if (c.rarity == Rarity.epic) return 0.08;
    return 0;
  });
}

/// Paldea + water-leaning mid pool.
List<({CardDef card, double weight})> _roaringWatersPool(List<CardDef> all) {
  return _weight(
    all.where((c) => _inSets(c, const {'PAL', 'TWM', 'MEW'})),
    weightOf: (c) {
      final water = (c.cardType ?? '').toLowerCase().contains('water');
      final boost = water ? 1.35 : 1.0;
      if (c.rarity == Rarity.common && c.marketPrice < 4) return 5 * boost;
      if (c.rarity == Rarity.rare) return 6 * boost;
      if (c.rarity == Rarity.epic && c.marketPrice < 60) return 3 * boost;
      if (c.rarity == Rarity.epic && c.marketPrice < 200) return 0.9 * boost;
      if (c.rarity == Rarity.epic) return 0.2 * boost;
      return 0;
    },
  );
}

/// Surging Sparks–weighted mid chase.
List<({CardDef card, double weight})> _rollingThunderPool(List<CardDef> all) {
  return _weight(
    all.where((c) => _inSets(c, const {'SSP', 'OBF', 'PRE'})),
    weightOf: (c) {
      final electric = (c.cardType ?? '').toLowerCase().contains('lightning') ||
          (c.cardType ?? '').toLowerCase().contains('electric');
      final boost = electric || c.setCode == 'SSP' ? 1.4 : 1.0;
      if (c.rarity == Rarity.rare && c.marketPrice >= 1) return 3 * boost;
      if (c.rarity == Rarity.epic && c.marketPrice < 40) return 7 * boost;
      if (c.rarity == Rarity.epic && c.marketPrice < 150) return 3.5 * boost;
      if (c.rarity == Rarity.epic) return 1.2 * boost;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _twilightPool(List<CardDef> all) {
  return _weight(all.where((c) => c.setCode == 'TWM'), weightOf: (c) {
    if (c.rarity == Rarity.rare && c.marketPrice >= 2) return 2.5;
    if (c.rarity == Rarity.epic && c.marketPrice < 50) return 7;
    if (c.rarity == Rarity.epic && c.marketPrice < 200) return 4;
    if (c.rarity == Rarity.epic) return 1.5;
    return 0;
  });
}

List<({CardDef card, double weight})> _paldeaPool(List<CardDef> all) {
  return _weight(all.where((c) => c.setCode == 'PAL'), weightOf: (c) {
    if (c.rarity == Rarity.rare && c.marketPrice >= 1) return 3;
    if (c.rarity == Rarity.epic && c.marketPrice < 40) return 7;
    if (c.rarity == Rarity.epic && c.marketPrice < 150) return 3.5;
    if (c.rarity == Rarity.epic) return 1.0;
    return 0;
  });
}

List<({CardDef card, double weight})> _mewChasePool(List<CardDef> all) {
  return _weight(all.where((c) => c.setCode == 'MEW'), weightOf: (c) {
    if (c.rarity == Rarity.rare && c.marketPrice >= 3) return 2;
    if (c.rarity == Rarity.epic && c.marketPrice < 80) return 6;
    if (c.rarity == Rarity.epic && c.marketPrice < 250) return 4;
    if (c.rarity == Rarity.epic) return 2.5;
    return 0;
  });
}

/// Cross-set modern SIRs — RareCandy Modern Grails shape.
List<({CardDef card, double weight})> _modernGrailsPool(List<CardDef> all) {
  return _weight(all, weightOf: (c) {
    if (c.rarity != Rarity.epic && c.rarity != Rarity.rare) return 0;
    if (c.rarity == Rarity.rare && c.marketPrice >= 25) return 1.5;
    if (c.marketPrice < 25) return 0;
    if (c.marketPrice < 80) return 4;
    if (c.marketPrice < 300) return 6;
    if (c.marketPrice < 800) return 3.5;
    return 1.8;
  });
}

/// Prismatic Evolutions–heavy mythic pool.
List<({CardDef card, double weight})> _mythicalGrailsPool(List<CardDef> all) {
  return _weight(
    all.where((c) => _inSets(c, const {'PRE', 'MEW', 'TWM', 'SSP'})),
    weightOf: (c) {
      final preBoost = c.setCode == 'PRE' ? 1.6 : 1.0;
      if (c.rarity != Rarity.epic && !(c.rarity == Rarity.rare && c.marketPrice >= 40)) {
        return 0;
      }
      if (c.marketPrice < 80) return 0.8 * preBoost;
      if (c.marketPrice < 300) return 4 * preBoost;
      if (c.marketPrice < 800) return 6 * preBoost;
      if (c.marketPrice < 2000) return 5 * preBoost;
      return 3.5 * preBoost;
    },
  );
}
