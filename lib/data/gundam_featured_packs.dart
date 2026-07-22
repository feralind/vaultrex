import '../models/enums.dart';
import '../models/models.dart';
import 'featured_packs.dart';

/// Gundam Card Game Featured Packs — first-wave Instapack tiers.
const int kGundamFeaturedPackCardCount = 7;

List<FeaturedPackDef> get kGundamFeaturedPacks => [
      FeaturedPackDef(
        id: 'gdfp_colony_drop',
        tier: FeaturedPackTier.common,
        name: 'Colony Drop',
        blurb:
            'Budget Newtype Rising & Dual Impact rip. 7 cards; last slot is the highlight.',
        priceUsd: 5.99,
        cardCount: kGundamFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk',
            priceRangeLabel: '\$0 – \$2',
            percent: 55,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Playable',
            priceRangeLabel: '\$2 – \$15',
            percent: 30,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Rare',
            priceRangeLabel: '\$15 – \$60',
            percent: 12,
          ),
          FeaturedPullRateRow(
            tierLabel: 'LR+',
            priceRangeLabel: '\$60+',
            percent: 3,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'gd_645344', oddsPercent: 1.2),
          FeaturedTopHit(cardId: 'gd_646003', oddsPercent: 1.4),
          FeaturedTopHit(cardId: 'gd_675703', oddsPercent: 1.6),
          FeaturedTopHit(cardId: 'gd_675689', oddsPercent: 1.8),
          FeaturedTopHit(cardId: 'gd_659279', oddsPercent: 2.0),
          FeaturedTopHit(cardId: 'gd_691971', oddsPercent: 2.2),
        ],
        poolSelector: _budgetPool,
      ),
      FeaturedPackDef(
        id: 'gdfp_newtype_rush',
        tier: FeaturedPackTier.uncommon,
        name: 'Newtype Rush',
        blurb: 'Weighted mid-tier across GD01–GD03. 7 cards; highlight last.',
        priceUsd: 11.99,
        cardCount: kGundamFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Bulk',
            priceRangeLabel: '\$0 – \$3',
            percent: 40,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Mid',
            priceRangeLabel: '\$3 – \$25',
            percent: 38,
          ),
          FeaturedPullRateRow(
            tierLabel: 'LR',
            priceRangeLabel: '\$25 – \$100',
            percent: 16,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Chase',
            priceRangeLabel: '\$100+',
            percent: 6,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'gd_645375', oddsPercent: 0.6),
          FeaturedTopHit(cardId: 'gd_645376', oddsPercent: 0.8),
          FeaturedTopHit(cardId: 'gd_659292', oddsPercent: 1.0),
          FeaturedTopHit(cardId: 'gd_691970', oddsPercent: 1.2),
          FeaturedTopHit(cardId: 'gd_702815', oddsPercent: 1.4),
          FeaturedTopHit(cardId: 'gd_691976', oddsPercent: 1.8),
        ],
        poolSelector: _midPool,
      ),
      FeaturedPackDef(
        id: 'gdfp_mobile_suit',
        tier: FeaturedPackTier.rare,
        name: 'Mobile Suit Vault',
        blurb: 'Steel Requiem & Phantom Aria chase weighting. 7 cards.',
        priceUsd: 24.99,
        cardCount: kGundamFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Mid',
            priceRangeLabel: '\$1 – \$10',
            percent: 35,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Hot',
            priceRangeLabel: '\$10 – \$50',
            percent: 35,
          ),
          FeaturedPullRateRow(
            tierLabel: 'LR',
            priceRangeLabel: '\$50 – \$200',
            percent: 22,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$200+',
            percent: 8,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'gd_645375', oddsPercent: 0.5),
          FeaturedTopHit(cardId: 'gd_702815', oddsPercent: 0.6),
          FeaturedTopHit(cardId: 'gd_691970', oddsPercent: 0.8),
          FeaturedTopHit(cardId: 'gd_645376', oddsPercent: 1.0),
          FeaturedTopHit(cardId: 'gd_659292', oddsPercent: 1.2),
          FeaturedTopHit(cardId: 'gd_691971', oddsPercent: 1.5),
        ],
        poolSelector: _hotPool,
      ),
      FeaturedPackDef(
        id: 'gdfp_freedom_vault',
        tier: FeaturedPackTier.epic,
        name: 'Freedom Vault',
        blurb:
            'High EV highlight slot across Freedom Ascension & Eternal Nexus. '
            'Exchange ≥50% candy if you dump the rip.',
        priceUsd: 49.99,
        cardCount: kGundamFeaturedPackCardCount,
        pullRates: const [
          FeaturedPullRateRow(
            tierLabel: 'Playable',
            priceRangeLabel: '\$2 – \$20',
            percent: 30,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Spike',
            priceRangeLabel: '\$20 – \$80',
            percent: 35,
          ),
          FeaturedPullRateRow(
            tierLabel: 'LR+',
            priceRangeLabel: '\$80 – \$400',
            percent: 25,
          ),
          FeaturedPullRateRow(
            tierLabel: 'Grail',
            priceRangeLabel: '\$400+',
            percent: 10,
          ),
        ],
        topHitIds: const [
          FeaturedTopHit(cardId: 'gd_645375', oddsPercent: 0.4),
          FeaturedTopHit(cardId: 'gd_702815', oddsPercent: 0.5),
          FeaturedTopHit(cardId: 'gd_691970', oddsPercent: 0.7),
          FeaturedTopHit(cardId: 'gd_645376', oddsPercent: 0.9),
          FeaturedTopHit(cardId: 'gd_659292', oddsPercent: 1.1),
          FeaturedTopHit(cardId: 'gd_659279', oddsPercent: 1.4),
        ],
        poolSelector: _chasePool,
      ),
    ];

List<({CardDef card, double weight})> _budgetPool(List<CardDef> all) => [
      for (final c in all)
        if (c.marketPrice > 0 && c.marketPrice < 40)
          (card: c, weight: c.marketPrice < 5 ? 6.0 : 2.0),
    ];

List<({CardDef card, double weight})> _midPool(List<CardDef> all) => [
      for (final c in all)
        if (c.marketPrice >= 1 && c.marketPrice < 150)
          (
            card: c,
            weight: c.marketPrice < 20
                ? 5.0
                : c.marketPrice < 60
                    ? 2.5
                    : 1.0,
          ),
    ];

List<({CardDef card, double weight})> _hotPool(List<CardDef> all) => [
      for (final c in all)
        if (c.marketPrice >= 5)
          (
            card: c,
            weight: c.marketPrice < 40
                ? 4.0
                : c.marketPrice < 120
                    ? 2.0
                    : 0.8,
          ),
    ];

List<({CardDef card, double weight})> _chasePool(List<CardDef> all) => [
      for (final c in all)
        if (c.marketPrice >= 15)
          (
            card: c,
            weight: c.marketPrice < 80
                ? 3.0
                : c.marketPrice < 250
                    ? 2.0
                    : 1.2,
          ),
    ];
