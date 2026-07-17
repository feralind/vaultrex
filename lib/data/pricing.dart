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

  static double fairValue(
    CardDef def,
    OwnedCard owned, {
    List<MarketEvent> events = const [],
  }) {
    final base = owned.foil
        ? (def.foilMarketPrice ?? def.marketPrice * 2.2)
        : def.marketPrice;
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

  static double platformFeeRate(PlayerStats player) {
    if (player.ownedUpgrades.contains('fee_cut')) return 0.08;
    return 0.12;
  }
}
