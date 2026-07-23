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
            'High-ticket Millennium rip with real bulk density. Big \$\$\$ '
            'hits are uncommon — pity is the unlock.',
        priceUsd: 249.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk / mid',
            priceRangeLabel: 'under \$60',
            percent: 58,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mythic',
            priceRangeLabel: '\$60 – \$300',
            percent: 28,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Millennium',
            priceRangeLabel: '\$300 – \$500',
            percent: 10,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Divine',
            priceRangeLabel: '\$500+',
            percent: 4,
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
            'Above Mythic. Paid pack with filler density — grails stay rare '
            'outside soft/hard pity.',
        priceUsd: 349.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk / mid',
            priceRangeLabel: 'under \$80',
            percent: 60,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Millennium',
            priceRangeLabel: '\$80 – \$300',
            percent: 26,
          ),
          FeaturedPullRateRow(
            tierLabel: 'High',
            priceRangeLabel: '\$300 – \$500',
            percent: 10,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Divine',
            priceRangeLabel: '\$500+',
            percent: 4,
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
            '\$500 apex with full catalog shape. Grails can print on a run — '
            'not every rip.',
        priceUsd: 499.99,
        cardCount: kYugiohFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk / mid',
            priceRangeLabel: 'under \$100',
            percent: 62,
          ),
          FeaturedPullRateRow(
            tierLabel: 'High',
            priceRangeLabel: '\$100 – \$350',
            percent: 24,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Millennium',
            priceRangeLabel: '\$350 – \$500',
            percent: 10,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Divine',
            priceRangeLabel: '\$500+',
            percent: 4,
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
      if (c.marketPrice > 0 && c.marketPrice < 10) return 8;
      if (c.marketPrice >= 10 && c.marketPrice < 25) return 5;
      if (c.marketPrice >= 25 && c.marketPrice < 70) return 2.2;
      if (c.marketPrice >= 70 && c.marketPrice < 150) return 0.9;
      if (c.marketPrice >= 150 && c.marketPrice < 300) return 0.35;
      if (c.marketPrice >= 300 || _isStarlight(c)) return 0.12;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _godCardsPool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      if (c.marketPrice > 0 && c.marketPrice < 15) return 9;
      if (c.marketPrice >= 15 && c.marketPrice < 40) return 5;
      if (c.marketPrice >= 40 && c.marketPrice < 70) return 2.5;
      if (c.marketPrice >= 70 && c.marketPrice < 150) return 1.0;
      if (c.marketPrice >= 150 && c.marketPrice < 300) return 0.45;
      if (c.marketPrice >= 300 && c.marketPrice < 500) return 0.2;
      if (c.marketPrice >= 500 || _isStarlight(c)) return 0.1;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _millenniumGrailsPool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      if (c.marketPrice > 0 && c.marketPrice < 20) return 10;
      if (c.marketPrice >= 20 && c.marketPrice < 60) return 5;
      if (c.marketPrice >= 60 && c.marketPrice < 120) return 2.2;
      if (c.marketPrice >= 120 && c.marketPrice < 300) return 0.7;
      if (c.marketPrice >= 300 && c.marketPrice < 500) return 0.28;
      if (c.marketPrice >= 500) return 0.12;
      if (_isStarlight(c) && c.marketPrice >= 150) return 0.18;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _millenniumPuzzlePool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      if (c.marketPrice > 0 && c.marketPrice < 25) return 11;
      if (c.marketPrice >= 25 && c.marketPrice < 80) return 5;
      if (c.marketPrice >= 80 && c.marketPrice < 150) return 2;
      if (c.marketPrice >= 150 && c.marketPrice < 220) return 0.55;
      if (c.marketPrice >= 220 && c.marketPrice < 300) return 0.3;
      if (c.marketPrice >= 300 && c.marketPrice < 500) return 0.18;
      if (c.marketPrice >= 500) return 0.1;
      if (_isStarlight(c) && c.marketPrice >= 150) return 0.15;
      return 0;
    },
  );
}

List<({CardDef card, double weight})> _divineAscensionPool(List<CardDef> all) {
  return _weight(
    all,
    weightOf: (c) {
      if (c.marketPrice > 0 && c.marketPrice < 30) return 12;
      if (c.marketPrice >= 30 && c.marketPrice < 100) return 5;
      if (c.marketPrice >= 100 && c.marketPrice < 220) return 1.6;
      if (c.marketPrice >= 220 && c.marketPrice < 350) return 0.45;
      if (c.marketPrice >= 350 && c.marketPrice < 500) return 0.22;
      if (c.marketPrice >= 500 && c.marketPrice < 800) return 0.12;
      if (c.marketPrice >= 800) return 0.08;
      if (_isStarlight(c) && c.marketPrice >= 180) return 0.12;
      return 0;
    },
  );
}
