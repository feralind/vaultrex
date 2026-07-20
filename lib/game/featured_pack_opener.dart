import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../data/featured_packs.dart';
import '../data/riftbound_catalog.dart';
import '../models/enums.dart';
import '../models/models.dart';

/// Weighted Featured Pack opener — fixed small count; last card is the highlight
/// (highest EV draw from that pack’s pool).
class FeaturedPackOpener {
  FeaturedPackOpener(this.catalog, {math.Random? rng})
      : _rng = rng ?? math.Random();

  final RiftboundCatalog catalog;
  final math.Random _rng;
  final _uuid = const Uuid();

  List<OwnedCard> open(FeaturedPackDef pack, {double pityBoost = 1.0}) {
    final pool = pack.poolSelector(catalog.cards);
    if (pool.isEmpty) {
      final fallback = catalog.cards
          .where((c) => c.marketPrice > 0 && c.rarity != Rarity.token)
          .toList();
      if (fallback.isEmpty) return const [];
      return List.generate(
        pack.cardCount,
        (_) => _instantiate(fallback[_rng.nextInt(fallback.length)]),
      );
    }

    final pulls = <OwnedCard>[];
    final fillers = <CardDef>[];
    for (var i = 0; i < pack.cardCount - 1; i++) {
      final def = _weightedPick(pool);
      fillers.add(def);
      pulls.add(_instantiate(def));
    }

    final highlight = _pickHighlight(pool, fillers, pityBoost: pityBoost);
    pulls.add(_instantiate(highlight, forceFoil: true));
    return pulls;
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

  /// Highest-EV weighted pick: reweight by marketPrice^1.35 so expensive chases
  /// dominate the last slot without making every rip identical.
  CardDef _pickHighlight(
    List<({CardDef card, double weight})> pool,
    List<CardDef> already, {
    double pityBoost = 1.0,
  }) {
    final ranked = [...pool]
      ..sort((a, b) => b.card.marketPrice.compareTo(a.card.marketPrice));
    final topN = ranked.take(math.min(24, ranked.length)).toList();
    final boosted = <({CardDef card, double weight})>[];
    for (final e in topN) {
      final novelty = already.any((c) => c.id == e.card.id) ? 0.55 : 1.0;
      final ev =
          math.pow(e.card.marketPrice.clamp(0.5, 5000), 1.35).toDouble();
      boosted.add((
        card: e.card,
        weight: e.weight * ev * novelty * pityBoost,
      ));
    }
    return _weightedPick(boosted);
  }

  OwnedCard _instantiate(CardDef def, {bool forceFoil = false}) {
    final foil = forceFoil ||
        (def.rarity.isRarePlus && _rng.nextDouble() < 0.55) ||
        _rng.nextDouble() < 0.12;
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
