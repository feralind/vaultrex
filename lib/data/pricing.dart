import 'dart:math';

import '../models/enums.dart';
import '../models/models.dart';

class Pricing {
  static double trendMult(List<MarketEvent> events, String setCode) {
    var m = 1.0;
    for (final e in events) {
      if (e.setCode == setCode || e.setCode == '*') m *= e.multiplier;
    }
    return m;
  }

  /// Speculative floor by rarity when no TCGCSV spot exists.
  static double speculativeBase(CardDef def) {
    final r = def.rarity;
    final floor = switch (r) {
      Rarity.common => 0.35,
      Rarity.uncommon => 0.85,
      Rarity.rare => 4.5,
      Rarity.epic => 18,
      Rarity.showcase => 55,
      Rarity.overnumbered => 80,
      Rarity.signature => 120,
      Rarity.ultimate => 200,
      Rarity.promo => 12,
      Rarity.token => 0.15,
      Rarity.none => 0.5,
    };
    // Pre-market premium — cards not on real secondary market yet.
    final premium = switch (r) {
      Rarity.showcase ||
      Rarity.signature ||
      Rarity.ultimate ||
      Rarity.overnumbered =>
        2.5,
      Rarity.epic => 2.1,
      Rarity.rare => 1.85,
      _ => 1.6,
    };
    return floor * premium;
  }

  static double fairValue(
    CardDef def,
    OwnedCard owned, {
    List<MarketEvent> events = const [],
  }) {
    double base;
    if (def.isUnlisted) {
      base = speculativeBase(def);
      if (owned.foil) base *= 2.0;
    } else {
      base = owned.foil
          ? (def.foilMarketPrice ?? def.marketPrice * 2.2)
          : def.marketPrice;
    }
    var v = base * owned.condition.valueMult;
    final center = owned.centeringScore / 100.0;
    v *= 0.85 + center * 0.2;
    if (owned.defects.contains(FactoryDefect.miscut)) v *= 1.8;
    if (owned.defects.contains(FactoryDefect.printLine)) v *= 0.85;
    if (owned.defects.contains(FactoryDefect.whitening)) v *= 0.9;
    if (owned.defects.contains(FactoryDefect.bentCorner)) v *= 0.8;
    if (owned.graded && owned.grade != null) {
      final g = owned.grade!;
      final gradeMult = g >= 10
          ? 3.2
          : g >= 9.5
              ? 2.2
              : g >= 9
                  ? 1.55
                  : g >= 8
                      ? 1.2
                      : 0.95;
      final companyMult = switch (owned.gradingCompany) {
        GradingCompany.psa => 1.2,
        null => 1.0,
      };
      v *= gradeMult * companyMult;
    }
    v *= trendMult(events, def.setCode);
    return max(0.01, v);
  }

  /// Fair ask for a market listing (no owned-card defects).
  static double fairForListing(
    CardDef def,
    MarketListing listing, {
    List<MarketEvent> events = const [],
  }) {
    double base;
    if (def.isUnlisted) {
      base = speculativeBase(def);
      if (listing.foil) base *= 2.0;
    } else {
      base = listing.foil
          ? (def.foilMarketPrice ?? def.marketPrice * 2.2)
          : def.marketPrice;
    }
    var v = base * listing.condition.valueMult;
    if (listing.graded && listing.grade != null) {
      final g = listing.grade!;
      final gradeMult = g >= 10
          ? 3.2
          : g >= 9.5
              ? 2.2
              : g >= 9
                  ? 1.55
                  : g >= 8
                      ? 1.2
                      : 0.95;
      v *= gradeMult * 1.2;
    }
    v *= trendMult(events, def.setCode);
    return max(0.01, v);
  }

  static double platformFeeRate(PlayerStats player) {
    if (player.ownedUpgrades.contains('fee_cut')) return 0.10;
    return 0.14;
  }
}
