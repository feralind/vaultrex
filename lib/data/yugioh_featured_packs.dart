import '../models/enums.dart';
import '../models/models.dart';
import 'featured_packs.dart';

/// Yu-Gi-Oh! Featured Packs — premium ladder (Rare floor → Divine $500).
/// Hit rates / pool weights scale with pack price: whale packs feel juicy,
/// not free money.
const int kYugiohFeaturedPackCardCount = kFeaturedPackCardCount;

List<FeaturedPackDef> get kYugiohFeaturedPacks => [
      FeaturedPackDef(
        id: 'ygofp_shadow_realm',
        tier: FeaturedPackTier.rare,
        name: 'Shadow Realm',
        blurb:
            "Bindora's Yu-Gi-Oh entry point — and it starts at Rare. "
            'No commons, no uncommons, guaranteed rare-or-better in every '
            'slot. 6 cards; the last slot is always the highlight.',
        priceUsd: 34.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$10 – \$30',
            percent: 48,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Epic',
            priceRangeLabel: '\$30 – \$70',
            percent: 33,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Legendary',
            priceRangeLabel: '\$70 – \$150',
            percent: 14,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic+',
            priceRangeLabel: '\$150+',
            percent: 5,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'ygo_687315', oddsPercent: 5.0),
          FeaturedTopHit(cardId: 'ygo_626885', oddsPercent: 4.2),
          FeaturedTopHit(cardId: 'ygo_692334', oddsPercent: 3.4),
          FeaturedTopHit(cardId: 'ygo_687317', oddsPercent: 2.6),
          FeaturedTopHit(cardId: 'ygo_692266', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'ygo_626877', oddsPercent: 1.0),
        ],
        poolSelector: _shadowRealmPool,
      ),
      FeaturedPackDef(
        id: 'ygofp_pharaohs_court',
        tier: FeaturedPackTier.epic,
        name: "Pharaoh's Court",
        blurb: 'Deep chase pool, weighted hard toward legendary hits.',
        priceUsd: 69.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Epic',
            priceRangeLabel: '\$30 – \$70',
            percent: 42,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Legendary',
            priceRangeLabel: '\$70 – \$150',
            percent: 36,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$150 – \$300',
            percent: 16,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Millennium+',
            priceRangeLabel: '\$300+',
            percent: 6,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'ygo_687325', oddsPercent: 5.2),
          FeaturedTopHit(cardId: 'ygo_687331', oddsPercent: 4.4),
          FeaturedTopHit(cardId: 'ygo_674758', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'ygo_687329', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'ygo_674757', oddsPercent: 1.9),
          FeaturedTopHit(cardId: 'ygo_692267', oddsPercent: 1.1),
        ],
        poolSelector: _pharaohsCourtPool,
      ),
      FeaturedPackDef(
        id: 'ygofp_god_cards',
        tier: FeaturedPackTier.legendary,
        name: 'God Cards',
        blurb:
            'Legendary-or-better guaranteed. This is where collections get made.',
        priceUsd: 129.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Legendary',
            priceRangeLabel: '\$70 – \$150',
            percent: 42,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$150 – \$300',
            percent: 36,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Millennium',
            priceRangeLabel: '\$300 – \$500',
            percent: 15,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Divine',
            priceRangeLabel: '\$500+',
            percent: 7,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'ygo_687313', oddsPercent: 5.0),
          FeaturedTopHit(cardId: 'ygo_687327', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'ygo_687325', oddsPercent: 3.2),
          FeaturedTopHit(cardId: 'ygo_687331', oddsPercent: 2.4),
          FeaturedTopHit(cardId: 'ygo_674758', oddsPercent: 1.6),
          FeaturedTopHit(cardId: 'ygo_687329', oddsPercent: 1.0),
        ],
        poolSelector: _godCardsPool,
      ),
      FeaturedPackDef(
        id: 'ygofp_millennium_grails',
        tier: FeaturedPackTier.mythic,
        name: 'Millennium Grails',
        blurb:
            'The most expensive standard-tier rip in Bindora. Mythic-or-'
            'better in every slot — hit rate scales with the price.',
        priceUsd: 249.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$150 – \$300',
            percent: 40,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Millennium',
            priceRangeLabel: '\$300 – \$500',
            percent: 38,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Divine',
            priceRangeLabel: '\$500+',
            percent: 22,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'ygo_687313', oddsPercent: 5.5),
          FeaturedTopHit(cardId: 'ygo_687327', oddsPercent: 4.5),
          FeaturedTopHit(cardId: 'ygo_687325', oddsPercent: 3.4),
          FeaturedTopHit(cardId: 'ygo_687331', oddsPercent: 2.5),
          FeaturedTopHit(cardId: 'ygo_674758', oddsPercent: 1.7),
          FeaturedTopHit(cardId: 'ygo_674757', oddsPercent: 1.0),
        ],
        poolSelector: _millenniumGrailsPool,
      ),
      FeaturedPackDef(
        id: 'ygofp_millennium_puzzle',
        tier: FeaturedPackTier.millennium,
        name: 'Millennium Puzzle',
        blurb:
            'Above Mythic. Paid-up odds — grail highlights land often enough '
            'to chase.',
        priceUsd: 349.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Millennium',
            priceRangeLabel: '\$300 – \$500',
            percent: 48,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Divine',
            priceRangeLabel: '\$500+',
            percent: 52,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'ygo_687313', oddsPercent: 6.5),
          FeaturedTopHit(cardId: 'ygo_687327', oddsPercent: 5.2),
          FeaturedTopHit(cardId: 'ygo_687325', oddsPercent: 4.0),
          FeaturedTopHit(cardId: 'ygo_687331', oddsPercent: 2.8),
          FeaturedTopHit(cardId: 'ygo_674758', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'ygo_692267', oddsPercent: 1.0),
        ],
        poolSelector: _millenniumPuzzlePool,
      ),
      FeaturedPackDef(
        id: 'ygofp_divine_ascension',
        tier: FeaturedPackTier.divine,
        name: 'Divine Ascension',
        blurb:
            '\$500 apex. Catalog grails only — hit rate is tuned so a run '
            'can print, without printing every rip.',
        priceUsd: 499.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Divine',
            priceRangeLabel: '\$500+',
            percent: 100,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'ygo_687313', oddsPercent: 8.0),
          FeaturedTopHit(cardId: 'ygo_687327', oddsPercent: 6.5),
          FeaturedTopHit(cardId: 'ygo_687325', oddsPercent: 5.0),
          FeaturedTopHit(cardId: 'ygo_687331', oddsPercent: 3.5),
          FeaturedTopHit(cardId: 'ygo_674758', oddsPercent: 2.2),
          FeaturedTopHit(cardId: 'ygo_687329', oddsPercent: 1.4),
        ],
        poolSelector: _divineAscensionPool,
      ),
    ];

bool _playable(CardDef c) =>
    c.rarity != Rarity.token &&
    c.rarity != Rarity.none &&
    c.marketPrice > 0 &&
    c.marketPrice < 20000 &&
    !c.name.toLowerCase().contains('token');

bool _isStarlight(CardDef c) =>
    c.name.toLowerCase().contains('starlight') || c.rarity == Rarity.showcase;

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

/// Rare floor — no commons/uncommons; rare+ and mid EV.
List<({CardDef card, double weight})> _shadowRealmPool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      if (c.rarity == Rarity.common || c.rarity == Rarity.uncommon) return 0;
      if (c.marketPrice >= 10 && c.marketPrice < 30) return 8;
      if (c.marketPrice >= 30 && c.marketPrice < 70) return 4;
      if (c.marketPrice >= 70 && c.marketPrice < 150) return 1.5;
      if (c.marketPrice >= 150) return 0.4;
      if (c.rarity.isRarePlus && c.marketPrice >= 5) return 2;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _pharaohsCourtPool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      if (c.marketPrice < 25) return 0;
      if (c.marketPrice >= 30 && c.marketPrice < 70) return 5.5;
      if (c.marketPrice >= 70 && c.marketPrice < 150) return 5.5;
      if (c.marketPrice >= 150 && c.marketPrice < 300) return 2.4;
      if (c.marketPrice >= 300 || _isStarlight(c)) return 0.85;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _godCardsPool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      if (c.marketPrice < 60) return 0;
      if (c.marketPrice >= 70 && c.marketPrice < 150) return 5;
      if (c.marketPrice >= 150 && c.marketPrice < 300) return 4.8;
      if (c.marketPrice >= 300 && c.marketPrice < 500) return 2.2;
      if (c.marketPrice >= 500 || _isStarlight(c)) return 1.2;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _millenniumGrailsPool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      if (c.marketPrice < 120) return 0;
      if (c.marketPrice >= 150 && c.marketPrice < 300) return 4.5;
      if (c.marketPrice >= 300 && c.marketPrice < 500) return 5.5;
      if (c.marketPrice >= 500) return 4.0;
      if (_isStarlight(c) && c.marketPrice >= 150) return 3.5;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _millenniumPuzzlePool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      // Paid-up odds: divine band dominates without being every rip.
      if (c.marketPrice >= 500) return 12;
      if (c.marketPrice >= 300) return 7;
      if (c.marketPrice >= 220) return 4;
      if (_isStarlight(c) && c.marketPrice >= 150) return 5;
      if (c.marketPrice >= 150) return 1.2;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _divineAscensionPool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      // \$500 pack — apex pool, heavy on true grails so EV can print.
      if (c.marketPrice >= 800) return 16;
      if (c.marketPrice >= 500) return 12;
      if (c.marketPrice >= 350) return 5;
      if (c.marketPrice >= 220) return 2.5;
      if (_isStarlight(c) && c.marketPrice >= 180) return 4;
      return 0;
    },
  );
}
