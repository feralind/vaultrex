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

  /// Whale packs bias fillers CHEAPER so the rip isn't 6 chase cards.
  List<({CardDef card, double weight})> _priceScaledFillerPool(
    List<({CardDef card, double weight})> pool,
    double packPriceUsd,
  ) {
    if (packPriceUsd < 40) return pool;
    return [
      for (final e in pool)
        (
          card: e.card,
          weight: e.weight * _fillerBias(e.card.marketPrice, packPriceUsd),
        ),
    ];
  }

  static double _fillerBias(double fair, double packPriceUsd) {
    final ratio = fair / packPriceUsd;
    if (ratio < 0.08) return 2.4;
    if (ratio < 0.18) return 1.5;
    if (ratio < 0.35) return 0.75;
    if (ratio < 0.60) return 0.35;
    return 0.12;
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

  /// Hit-rate / EV curve — mild price tilt; pool weights do most of the work.
  static double highlightEvExponent(double packPriceUsd) {
    if (packPriceUsd <= 10) return 0.55;
    if (packPriceUsd <= 50) return 0.62;
    if (packPriceUsd <= 130) return 0.70;
    if (packPriceUsd <= 260) return 0.78;
    if (packPriceUsd <= 400) return 0.85;
    return 0.92;
  }

  /// Cap used for normal EV rolls so \$3k serials don't dominate every highlight.
  /// True grails still land via soft/hard pity.
  static double highlightEvFairCap(double packPriceUsd) {
    return math.max(40.0, packPriceUsd * 1.15);
  }

  /// Chance a premium pack floors the highlight into a strong-but-not-free band.
  static double premiumFloorChance(double packPriceUsd) {
    if (packPriceUsd < 100) return 0;
    // $130 → ~8%, $250 → ~11%, $500 → ~16%
    return (0.04 + (packPriceUsd / 500) * 0.12).clamp(0.04, 0.16);
  }

  /// Near-miss odds — tension without wiping heat every other rip.
  static double nearMissChance(double packPriceUsd) {
    if (packPriceUsd >= 100) return 0.14;
    if (packPriceUsd >= 20) return 0.10;
    return 0.08;
  }

  /// Weighted highlight pick. Pity/floor/near-miss use the expensive cream;
  /// normal rolls use the **full pool** (was top-16-only — felt like cheating).
  CardDef _pickHighlight(
    List<({CardDef card, double weight})> pool,
    List<CardDef> already, {
    double pityBoost = 1.0,
    int dryCount = 0,
    double packPriceUsd = 10,
  }) {
    final ranked = [...pool]
      ..sort((a, b) => b.card.marketPrice.compareTo(a.card.marketPrice));
    final topCap = packPriceUsd >= 350
        ? 12
        : packPriceUsd >= 150
            ? 16
            : 24;
    final topN = ranked.take(math.min(topCap, ranked.length)).toList();
    final clearBar = featuredChaseFairThreshold(packPriceUsd);

    // Hard pity: guaranteed top-band jackpot (top 3 by market).
    if (dryCount >= kFeaturedHardPityDry && topN.isNotEmpty) {
      final band = topN.take(math.min(3, topN.length)).toList();
      return band[_rng.nextInt(band.length)].card;
    }

    // Soft pity jackpot: occasional true clear before hard pity.
    if (dryCount >= 7 &&
        dryCount < kFeaturedHardPityDry &&
        topN.isNotEmpty &&
        _rng.nextDouble() < softPityJackpotChance(packPriceUsd)) {
      final jackpot = topN
          .where((e) => e.card.marketPrice >= clearBar)
          .toList();
      final band = jackpot.isNotEmpty
          ? jackpot.take(math.min(4, jackpot.length)).toList()
          : topN.take(math.min(3, topN.length)).toList();
      return band[_rng.nextInt(band.length)].card;
    }

    // Premium floor: mid-strong highlight from the full pool (not only cream).
    final floorChance = premiumFloorChance(packPriceUsd);
    if (floorChance > 0 && _rng.nextDouble() < floorChance) {
      final minFair = packPriceUsd * 0.45;
      final maxFair = clearBar;
      final floorBand = pool
          .where((e) =>
              e.card.marketPrice >= minFair &&
              e.card.marketPrice < maxFair)
          .toList();
      if (floorBand.isNotEmpty) {
        return _weightedPick(floorBand);
      }
    }

    // Near-miss: just under chase clear — dopamine without wiping heat.
    final nearChance = nearMissChance(packPriceUsd);
    if (dryCount >= 3 && _rng.nextDouble() < nearChance) {
      final under = pool
          .where((e) =>
              e.card.marketPrice >= clearBar * 0.35 &&
              e.card.marketPrice < clearBar)
          .toList();
      if (under.length >= 2) {
        return _weightedPick(under);
      }
    }

    // Normal path: full pool + capped EV so fillers actually win most rips.
    final exp = highlightEvExponent(packPriceUsd);
    final fairCap = highlightEvFairCap(packPriceUsd);
    final boosted = <({CardDef card, double weight})>[];
    for (final e in pool) {
      final novelty = already.any((c) => c.id == e.card.id) ? 0.55 : 1.0;
      final fairForEv = e.card.marketPrice.clamp(0.5, fairCap);
      final ev = math.pow(fairForEv, exp).toDouble();
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
