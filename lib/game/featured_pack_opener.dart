import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../data/featured_packs.dart';
import '../data/riftbound_catalog.dart';
import '../models/enums.dart';
import '../models/models.dart';

/// Weighted Featured Pack opener — fixed small count; last card is the highlight
/// (highest EV draw from that pack’s pool).
///
/// Dopamine loop:
/// - Fillers: frequent small foil / rare+ wins
/// - Highlight: EV-weighted + soft pity, near-miss band, hard pity jackpot
class FeaturedPackOpener {
  FeaturedPackOpener(this.catalog, {math.Random? rng})
      : _rng = rng ?? math.Random();

  final RiftboundCatalog catalog;
  final math.Random _rng;
  final _uuid = const Uuid();

  List<OwnedCard> open(
    FeaturedPackDef pack, {
    double pityBoost = 1.0,
    int dryCount = 0,
  }) {
    final pool = pack.poolSelector(catalog.cards);
    if (pool.isEmpty) {
      // Do not fall back to franchise-wide scrapes — keep set/theme locks honest.
      return const [];
    }

    final pulls = <OwnedCard>[];
    final fillers = <CardDef>[];
    final fillerPool = _priceScaledFillerPool(pool, pack.priceUsd);
    for (var i = 0; i < pack.cardCount - 1; i++) {
      final def = _weightedPick(fillerPool);
      fillers.add(def);
      pulls.add(_instantiate(def, entryPack: pack.priceUsd <= 10));
    }

    final highlight = _pickHighlight(
      pool,
      fillers,
      pityBoost: pityBoost,
      dryCount: dryCount,
      packPriceUsd: pack.priceUsd,
    );
    pulls.add(_instantiate(highlight, forceFoil: true));
    return pulls;
  }

  /// Whale packs bias fillers upward so the whole rip feels paid-for.
  List<({CardDef card, double weight})> _priceScaledFillerPool(
    List<({CardDef card, double weight})> pool,
    double packPriceUsd,
  ) {
    if (packPriceUsd < 80) return pool;
    // $80 → mild, $500 → strong preference for cards near pack value.
    final lean = (packPriceUsd / 500).clamp(0.15, 1.0);
    return [
      for (final e in pool)
        (
          card: e.card,
          weight: e.weight *
              (0.55 +
                  lean *
                      (e.card.marketPrice / packPriceUsd).clamp(0.15, 2.2)),
        ),
    ];
  }

  CardDef _weightedPick(List<({CardDef card, double weight})> pool) {
    var total = 0.0;
    for (final e in pool) {
      total += e.weight;
    }
    if (total <= 0) return pool.first.card;
    var roll = _rng.nextDouble() * total;
    for (final e in pool) {
      roll -= e.weight;
      if (roll <= 0) return e.card;
    }
    return pool.last.card;
  }

  /// Hit-rate / EV curve scales with pack price (entry flat → whale steep).
  static double highlightEvExponent(double packPriceUsd) {
    if (packPriceUsd <= 10) return 1.18;
    if (packPriceUsd <= 50) return 1.22; // softer mid — leave room for heat
    if (packPriceUsd <= 130) return 1.38;
    if (packPriceUsd <= 260) return 1.48;
    if (packPriceUsd <= 400) return 1.58;
    return 1.70;
  }

  /// Chance a premium pack floors the highlight into a "can print" band.
  static double premiumFloorChance(double packPriceUsd) {
    if (packPriceUsd < 100) return 0;
    // $130 → ~25%, $250 → ~34%, $500 → ~50%
    return (0.16 + (packPriceUsd / 500) * 0.34).clamp(0.16, 0.50);
  }

  /// Near-miss odds — climb starts earlier so whales feel tension.
  static double nearMissChance(double packPriceUsd) {
    if (packPriceUsd >= 100) return 0.40;
    if (packPriceUsd >= 20) return 0.32;
    return 0.24;
  }

  /// Highest-EV weighted pick with soft pity, near-miss, hard pity,
  /// and price-scaled hit rate.
  CardDef _pickHighlight(
    List<({CardDef card, double weight})> pool,
    List<CardDef> already, {
    double pityBoost = 1.0,
    int dryCount = 0,
    double packPriceUsd = 10,
  }) {
    final ranked = [...pool]
      ..sort((a, b) => b.card.marketPrice.compareTo(a.card.marketPrice));
    // Tighter cream on whale packs = nicer hit rate without guaranteeing.
    final topCap = packPriceUsd >= 350
        ? 12
        : packPriceUsd >= 150
            ? 16
            : 24;
    final topN = ranked.take(math.min(topCap, ranked.length)).toList();

    // Hard pity: guaranteed top-band jackpot (top 3 by market).
    if (dryCount >= kFeaturedHardPityDry && topN.isNotEmpty) {
      final band = topN.take(math.min(3, topN.length)).toList();
      return band[_rng.nextInt(band.length)].card;
    }

    // Soft pity jackpot: occasional true clear before hard pity (fair crack, not brick).
    if (dryCount >= 7 &&
        dryCount < kFeaturedHardPityDry &&
        topN.isNotEmpty &&
        _rng.nextDouble() < softPityJackpotChance(packPriceUsd)) {
      final clearBar = featuredChaseFairThreshold(packPriceUsd);
      final jackpot = topN
          .where((e) => e.card.marketPrice >= clearBar)
          .toList();
      final band = jackpot.isNotEmpty
          ? jackpot.take(math.min(4, jackpot.length)).toList()
          : topN.take(math.min(3, topN.length)).toList();
      return band[_rng.nextInt(band.length)].card;
    }

    // Premium floor: paid packs land a strong-but-under-clear highlight.
    final floorChance = premiumFloorChance(packPriceUsd);
    if (floorChance > 0 && _rng.nextDouble() < floorChance) {
      final clearBar = featuredChaseFairThreshold(packPriceUsd);
      final minFair = packPriceUsd * 0.75;
      final floorBand = topN
          .where((e) =>
              e.card.marketPrice >= minFair &&
              e.card.marketPrice < clearBar)
          .toList();
      final band = floorBand.isNotEmpty
          ? floorBand
          : topN
              .where((e) => e.card.marketPrice < clearBar)
              .take(math.min(5, topN.length))
              .toList();
      final use = band.isNotEmpty
          ? band
          : topN.take(math.min(5, topN.length)).toList();
      return use[_rng.nextInt(use.length)].card;
    }

    // Near-miss: just under chase clear — dopamine without wiping heat.
    final nearChance = nearMissChance(packPriceUsd);
    final clearBar = featuredChaseFairThreshold(packPriceUsd);
    if (dryCount >= 3 &&
        topN.length >= 4 &&
        _rng.nextDouble() < nearChance) {
      final under = topN
          .where((e) => e.card.marketPrice < clearBar)
          .toList();
      if (under.length >= 2) {
        final band = under.take(math.min(6, under.length)).toList();
        return band[_rng.nextInt(band.length)].card;
      }
      // Fallback: ranks just under the absolute top, still under clear if possible.
      final near = topN.sublist(
        math.min(2, topN.length - 1),
        math.min(8, topN.length),
      );
      final nearUnder =
          near.where((e) => e.card.marketPrice < clearBar).toList();
      final band = nearUnder.isNotEmpty ? nearUnder : near;
      if (band.isNotEmpty) {
        return band[_rng.nextInt(band.length)].card;
      }
    }

    final exp = highlightEvExponent(packPriceUsd);

    final boosted = <({CardDef card, double weight})>[];
    for (final e in topN) {
      final novelty = already.any((c) => c.id == e.card.id) ? 0.55 : 1.0;
      final ev =
          math.pow(e.card.marketPrice.clamp(0.5, 5000), exp).toDouble();
      boosted.add((
        card: e.card,
        weight: e.weight * ev * novelty * pityBoost,
      ));
    }
    return _weightedPick(boosted);
  }
  OwnedCard _instantiate(
    CardDef def, {
    bool forceFoil = false,
    bool entryPack = false,
  }) {
    // Entry packs print a few more foils so rips feel juicy without jackpots.
    final rareFoil = entryPack ? 0.68 : 0.58;
    final baseFoil = entryPack ? 0.18 : 0.14;
    final foil = forceFoil ||
        (def.rarity.isRarePlus && _rng.nextDouble() < rareFoil) ||
        _rng.nextDouble() < baseFoil;
    final centeringLR = _gauss(50, 8).clamp(5, 95);
    final centeringTB = _gauss(50, 8).clamp(5, 95);
    final defects = <FactoryDefect>[];
    if (_rng.nextDouble() < 0.03) defects.add(FactoryDefect.whitening);
    if (_rng.nextDouble() < 0.015) defects.add(FactoryDefect.printLine);

    return OwnedCard(
      instanceId: _uuid.v4(),
      cardId: def.id,
      foil: foil,
      condition: _rng.nextDouble() < 0.92 ? Condition.nearMint : Condition.mint,
      centeringLR: centeringLR.toDouble(),
      centeringTB: centeringTB.toDouble(),
      surface: _gauss(9.2, 0.55).clamp(5, 10).toDouble(),
      edges: _gauss(9.1, 0.6).clamp(5, 10).toDouble(),
      corners: _gauss(9.0, 0.7).clamp(4, 10).toDouble(),
      defects: defects,
    );
  }

  double _gauss(double mean, double std) {
    final u1 = _rng.nextDouble().clamp(1e-9, 1.0);
    final u2 = _rng.nextDouble();
    final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    return mean + z * std;
  }
}
