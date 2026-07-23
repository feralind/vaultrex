import '../models/enums.dart';
import '../models/models.dart';
import 'featured_packs.dart';

/// One Piece Featured Packs — same Instapack tier shape as MTG / Pokémon.
const int kOnePieceFeaturedPackCardCount = 6;

List<FeaturedPackDef> get kOnePieceFeaturedPacks => [
      FeaturedPackDef(
        id: 'opfp_starter_sea',
        tier: FeaturedPackTier.common,
        name: 'Starter Sea',
        blurb:
            'Budget Romance Dawn / Paramount War rip. Mostly commons & uncommons '
            'with a slim shot at a spicy rare. 6 cards; last slot is the highlight.',
        priceUsd: 4.99,
        cardCount: kOnePieceFeaturedPackCardCount,
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
            tierLabel: 'SR+',
            priceRangeLabel: '\$40+',
            percent: 3,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'op_454513', oddsPercent: 1.2),
          FeaturedTopHit(cardId: 'op_453506', oddsPercent: 1.4),
          FeaturedTopHit(cardId: 'op_453508', oddsPercent: 1.6),
          FeaturedTopHit(cardId: 'op_453510', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'op_454522', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'op_454548', oddsPercent: 2.2),
        ],
        poolSelector: _starterPool,
      ),
      FeaturedPackDef(
        id: 'opfp_grand_line',
        tier: FeaturedPackTier.uncommon,
        name: 'Grand Line',
        blurb:
            'Mid-sea rip weighted toward Awakening & Emperors playables. '
            'Leaders and SRs in the mix. 6 cards; highlight last.',
        priceUsd: 9.99,
        cardCount: kOnePieceFeaturedPackCardCount,
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
            tierLabel: 'SR',
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
          FeaturedTopHit(cardId: 'op_527019', oddsPercent: 1.5),
          FeaturedTopHit(cardId: 'op_527020', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'op_596918', oddsPercent: 2.4),
          FeaturedTopHit(cardId: 'op_596917', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'op_587960', oddsPercent: 3.2),
          FeaturedTopHit(cardId: 'op_453506', oddsPercent: 3.6),
        ],
        poolSelector: _grandLinePool,
      ),
      FeaturedPackDef(
        id: 'opfp_new_world',
        tier: FeaturedPackTier.rare,
        name: 'New World',
        blurb:
            'OP09 / OP13-weighted Instant rip. Loaded with SRs and Leaders — '
            'Emperors headline. Highlight last.',
        priceUsd: 24.99,
        cardCount: kOnePieceFeaturedPackCardCount,
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
            tierLabel: 'SR',
            priceRangeLabel: '\$40 – \$150',
            percent: 24,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SEC+',
            priceRangeLabel: '\$150+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'op_596925', oddsPercent: 2.5),
          FeaturedTopHit(cardId: 'op_597035', oddsPercent: 3.0),
          FeaturedTopHit(cardId: 'op_657442', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'op_527019', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'op_596984', oddsPercent: 1.2),
          FeaturedTopHit(cardId: 'op_587966', oddsPercent: 0.8),
        ],
        poolSelector: _newWorldPool,
      ),
      FeaturedPackDef(
        id: 'opfp_yonko_raid',
        tier: FeaturedPackTier.epic,
        name: 'Yonko Raid',
        blurb:
            'Navy pack stacked with Emperors & Carrying On His Will chases. '
            'Manga / SP treatments in the highlight. 6 cards; highlight last.',
        priceUsd: 49.99,
        cardCount: kOnePieceFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$5 – \$25',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SR',
            priceRangeLabel: '\$25 – \$100',
            percent: 48,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SEC / SP',
            priceRangeLabel: '\$100 – \$500',
            percent: 24,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Manga',
            priceRangeLabel: '\$500+',
            percent: 6,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'op_454666', oddsPercent: 0.4),
          FeaturedTopHit(cardId: 'op_485862', oddsPercent: 0.6),
          FeaturedTopHit(cardId: 'op_587963', oddsPercent: 0.7),
          FeaturedTopHit(cardId: 'op_596925', oddsPercent: 0.9),
          FeaturedTopHit(cardId: 'op_657402', oddsPercent: 2.5),
          FeaturedTopHit(cardId: 'op_587966', oddsPercent: 3.0),
        ],
        poolSelector: _yonkoPool,
      ),
      FeaturedPackDef(
        id: 'opfp_secret_rare_vault',
        tier: FeaturedPackTier.legendary,
        name: 'Secret Rare Vault',
        blurb:
            'OP13/PRB01 legendary rip with bulk through SEC/Manga. Big hits '
            'are uncommon; pity unlocks the chase. Dump for ≥50% candy.',
        priceUsd: 99.99,
        cardCount: kOnePieceFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk / rare',
            priceRangeLabel: 'under \$25',
            percent: 55,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SR',
            priceRangeLabel: '\$25 – \$100',
            percent: 26,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SEC / SP',
            priceRangeLabel: '\$100 – \$400',
            percent: 14,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Manga / grail',
            priceRangeLabel: '\$400+',
            percent: 5,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'op_454666', oddsPercent: 1.1),
          FeaturedTopHit(cardId: 'op_587963', oddsPercent: 1.4),
          FeaturedTopHit(cardId: 'op_657411', oddsPercent: 1.6),
          FeaturedTopHit(cardId: 'op_485862', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'op_657402', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'op_587708', oddsPercent: 4.0),
        ],
        poolSelector: _secretVaultPool,
      ),
      FeaturedPackDef(
        id: 'opfp_emperors_treasure',
        tier: FeaturedPackTier.mythic,
        name: "Emperor's Treasure",
        blurb:
            'Full OP13/PRB01 pack shape — commons through Manga serials. '
            'Grails stay rare; pity unlocks the true chase.',
        priceUsd: 179.99,
        cardCount: kOnePieceFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk / rare',
            priceRangeLabel: 'under \$40',
            percent: 60,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SR / SEC',
            priceRangeLabel: '\$40 – \$150',
            percent: 24,
          ),
          FeaturedPullRateRow(
            tierLabel: 'SP / Manga',
            priceRangeLabel: '\$150 – \$500',
            percent: 12,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$500+',
            percent: 4,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'op_454666', oddsPercent: 2.2),
          FeaturedTopHit(cardId: 'op_587963', oddsPercent: 2.5),
          FeaturedTopHit(cardId: 'op_657411', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'op_485862', oddsPercent: 3.2),
          FeaturedTopHit(cardId: 'op_596925', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'op_657402', oddsPercent: 4.5),
        ],
        poolSelector: _emperorsPool,
      ),
    ];

bool _playable(CardDef c) =>
    c.rarity != Rarity.token &&
    c.rarity != Rarity.none &&
    c.marketPrice > 0 &&
    c.marketPrice < 20000 &&
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

bool _inSets(CardDef c, Set<String> codes) => codes.contains(c.setCode);

List<({CardDef card, double weight})> _starterPool(List<CardDef> all) {
  // Romance Dawn + Paramount War.
  return _weight(
    all.where((c) => _inSets(c, const {'OP01', 'OP02'})),
    weightOf: (c) {
      if (c.rarity == Rarity.common) return 8;
      if (c.rarity == Rarity.uncommon && c.marketPrice < 4) return 5;
      if (c.rarity == Rarity.rare && c.marketPrice < 25) return 1.2;
      if (c.rarity == Rarity.epic && c.marketPrice < 50) return 0.25;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _grandLinePool(List<CardDef> all) {
  return _weight(
    all.where((c) => _inSets(c, const {'OP05', 'OP09'})),
    weightOf: (c) {
      if (c.rarity == Rarity.common) return 2;
      if (c.rarity == Rarity.uncommon) return 6;
      if (c.rarity == Rarity.rare) return 5;
      if (c.rarity == Rarity.epic && c.marketPrice < 120) return 1.0;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _newWorldPool(List<CardDef> all) {
  return _weight(
    all.where((c) => _inSets(c, const {'OP09', 'OP13'})),
    weightOf: (c) {
      if (c.rarity == Rarity.uncommon && c.marketPrice >= 1) return 2;
      if (c.rarity == Rarity.rare) return 7;
      if (c.rarity == Rarity.epic) return 5;
      if (c.marketPrice >= 100 && c.marketPrice < 500) return 0.8;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _yonkoPool(List<CardDef> all) {
  return _weight(
    all.where((c) => _inSets(c, const {'OP09', 'OP13'})),
    weightOf: (c) {
      if (c.rarity == Rarity.common) return 6;
      if (c.rarity == Rarity.uncommon) return 5;
      if (c.rarity == Rarity.rare && c.marketPrice >= 5) return 2.5;
      if (c.rarity == Rarity.epic) {
        return c.marketPrice < 300 ? 1.2 : 0.4;
      }
      if (c.rarity == Rarity.showcase || c.marketPrice >= 200) return 0.35;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _secretVaultPool(List<CardDef> all) {
  return _weight(
    all.where((c) => _inSets(c, const {'OP13', 'PRB01'})),
    weightOf: (c) {
      if (c.rarity == Rarity.common) return 8;
      if (c.rarity == Rarity.uncommon) return 6;
      if (c.rarity == Rarity.rare) return 3.5;
      if (c.rarity == Rarity.epic && c.marketPrice < 25) return 1.4;
      if (c.rarity == Rarity.epic && c.marketPrice >= 25) return 0.7;
      if (c.rarity == Rarity.showcase ||
          c.name.toLowerCase().contains('manga') ||
          c.name.toLowerCase().contains('(sp)')) {
        return c.marketPrice >= 400 ? 0.25 : 0.45;
      }
      if (c.rarity == Rarity.epic) return 0.9;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _emperorsPool(List<CardDef> all) {
  return _weight(
    all.where((c) => _inSets(c, const {'OP13', 'PRB01'})),
    weightOf: (c) {
      if (c.rarity == Rarity.common) return 9;
      if (c.rarity == Rarity.uncommon) return 7;
      if (c.rarity == Rarity.rare) return 4;
      if (c.name.toLowerCase().contains('manga') ||
          c.rarity == Rarity.showcase) {
        return c.marketPrice >= 1000 ? 0.2 : 0.4;
      }
      if (c.rarity == Rarity.epic && c.marketPrice < 80) return 1.5;
      if (c.rarity == Rarity.epic && c.marketPrice >= 80) return 0.55;
      if (c.marketPrice >= 150) return 0.35;
      return 0;
    },
  );
}
