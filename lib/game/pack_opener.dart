import 'dart:math';

import 'package:uuid/uuid.dart';

import '../data/riftbound_catalog.dart';
import '../models/enums.dart';
import '../models/models.dart';

/// IRL Riftbound pack structure:
/// 14 cards = 7C + 3U + 2 rare-or-better foil + 1 foil-any + 1 token/rune
class RiftboundPackOpener {
  RiftboundPackOpener(this.catalog, {Random? rng}) : _rng = rng ?? Random();

  final RiftboundCatalog catalog;
  final Random _rng;
  final _uuid = const Uuid();

  List<OwnedCard> openPack(String setCode) {
    if (catalog.isPokemon) {
      // Modern Pokémon-style 10-card pack (Rare Candy feel).
      // Some catalog sets omit Uncommon — fill those slots from Common.
      final cards = <OwnedCard>[];
      cards.addAll(_drawMany(setCode, Rarity.common, 5, foil: false));
      final uncommons = _drawMany(setCode, Rarity.uncommon, 3, foil: false);
      cards.addAll(uncommons);
      if (uncommons.length < 3) {
        cards.addAll(
          _drawMany(setCode, Rarity.common, 3 - uncommons.length, foil: false),
        );
      }
      cards.add(_drawReverseHolo(setCode));
      cards.addAll(_drawRarePlus(setCode, 1, forceFoil: false));
      return cards;
    }
    if (catalog.isMtg) {
      // Play Booster–style: ~14 cards with rare+ slot and foil chance.
      final cards = <OwnedCard>[];
      cards.addAll(_drawMany(setCode, Rarity.common, 6, foil: false));
      cards.addAll(_drawMany(setCode, Rarity.uncommon, 3, foil: false));
      cards.addAll(_drawRarePlus(setCode, 1, forceFoil: false));
      cards.add(_drawFoilAny(setCode));
      // Wildcard / land-ish filler from commons.
      cards.addAll(_drawMany(setCode, Rarity.common, 3, foil: false));
      return cards;
    }
    if (catalog.isOnePiece) {
      // One Piece booster: 6 main cards; optional DON!! when catalog has them.
      final cards = <OwnedCard>[];
      cards.addAll(_drawMany(setCode, Rarity.common, 3, foil: false));
      final uncommons = _drawMany(setCode, Rarity.uncommon, 2, foil: false);
      cards.addAll(uncommons);
      if (uncommons.length < 2) {
        cards.addAll(
          _drawMany(setCode, Rarity.common, 2 - uncommons.length, foil: false),
        );
      }
      cards.addAll(_drawRarePlus(setCode, 1, forceFoil: false));
      while (cards.length < 6) {
        cards.addAll(_drawMany(setCode, Rarity.common, 1, foil: false));
        if (cards.isEmpty) break;
      }
      final don = _drawDon(setCode);
      if (don != null) cards.add(don);
      return cards.take(7).toList();
    }
    if (catalog.isYugioh) {
      // Modern TCG booster ~9 cards. Some reprint sets (RA0x) are rare+ heavy
      // with few/no commons — fall back to whatever the set actually stocks.
      final cards = <OwnedCard>[];
      cards.addAll(_drawManyOrAny(setCode, Rarity.common, 5, foil: false));
      cards.addAll(_drawManyOrAny(setCode, Rarity.uncommon, 3, foil: false));
      cards.addAll(_drawRarePlus(setCode, 1, forceFoil: false));
      while (cards.length < 9) {
        final filler = _pickAny(setCode);
        if (filler == null) break;
        cards.add(_instantiate(filler, foil: false));
      }
      return cards.take(9).toList();
    }
    if (catalog.isGundam) {
      // Gundam Card Game booster ≈ 7 cards (6 + resource/token-ish filler).
      final cards = <OwnedCard>[];
      cards.addAll(_drawManyOrAny(setCode, Rarity.common, 3, foil: false));
      cards.addAll(_drawManyOrAny(setCode, Rarity.uncommon, 2, foil: false));
      cards.addAll(_drawRarePlus(setCode, 1, forceFoil: false));
      while (cards.length < 7) {
        final filler = _pickAny(setCode);
        if (filler == null) break;
        cards.add(_instantiate(filler, foil: false));
      }
      return cards.take(7).toList();
    }
    final cards = <OwnedCard>[];
    cards.addAll(_drawMany(setCode, Rarity.common, 7, foil: false));
    cards.addAll(_drawMany(setCode, Rarity.uncommon, 3, foil: false));
    cards.addAll(_drawRarePlus(setCode, 2, forceFoil: true));
    cards.add(_drawFoilAny(setCode));
    cards.add(_drawToken(setCode));
    return cards;
  }

  /// Open a sealed box as N packs of [setCode].
  /// Prefer [packCount] from the sealed product's `packsPerBox`; otherwise
  /// use franchise defaults (36 Pokémon / 30 MTG / 24 other).
  List<OwnedCard> openBox(String setCode, {int? packCount}) {
    final packs = packCount ??
        (catalog.isPokemon
            ? 36
            : catalog.isMtg
                ? 30
                : 24);
    final all = <OwnedCard>[];
    for (var i = 0; i < packs; i++) {
      all.addAll(openPack(setCode));
    }
    // No forced chase injection — box odds = sum of pack odds.
    return all;
  }

  OwnedCard _drawReverseHolo(String setCode) {
    final roll = _rng.nextDouble();
    final rarity = roll < 0.6
        ? Rarity.common
        : roll < 0.9
            ? Rarity.uncommon
            : Rarity.rare;
    final def = _pick(setCode, rarity) ??
        _pick(setCode, Rarity.common) ??
        catalog.bySet[setCode]!.first;
    return _instantiate(def, foil: true);
  }

  List<OwnedCard> _drawMany(
    String setCode,
    Rarity rarity,
    int count, {
    required bool foil,
  }) {
    final out = <OwnedCard>[];
    for (var i = 0; i < count; i++) {
      final def = _pick(setCode, rarity);
      if (def == null) continue;
      out.add(_instantiate(def, foil: foil));
    }
    return out;
  }

  /// Like [_drawMany], but fills shortfalls from any card in the set.
  List<OwnedCard> _drawManyOrAny(
    String setCode,
    Rarity rarity,
    int count, {
    required bool foil,
  }) {
    final out = _drawMany(setCode, rarity, count, foil: foil);
    while (out.length < count) {
      final def = _pickAny(setCode);
      if (def == null) break;
      out.add(_instantiate(def, foil: foil));
    }
    return out;
  }

  CardDef? _pickAny(String setCode) {
    final all = catalog.bySet[setCode];
    if (all == null || all.isEmpty) return null;
    return all[_rng.nextInt(all.length)];
  }

  List<OwnedCard> _drawRarePlus(String setCode, int count, {required bool forceFoil}) {
    final out = <OwnedCard>[];
    for (var i = 0; i < count; i++) {
      final rarity = _rollRarePlus(setCode);
      final def = _pick(setCode, rarity) ??
          _pick(setCode, Rarity.rare) ??
          _pick(setCode, Rarity.epic) ??
          _pick(setCode, Rarity.showcase) ??
          _pickAny(setCode);
      if (def == null) continue;
      out.add(_instantiate(def, foil: forceFoil));
    }
    return out;
  }

  OwnedCard _drawFoilAny(String setCode) {
    final roll = _rng.nextDouble();
    final rarity = roll < 0.55
        ? Rarity.common
        : roll < 0.82
            ? Rarity.uncommon
            : roll < 0.95
                ? Rarity.rare
                : Rarity.epic;
    final def = _pick(setCode, rarity) ??
        _pick(setCode, Rarity.common) ??
        catalog.bySet[setCode]!.first;
    return _instantiate(def, foil: true);
  }

  OwnedCard _drawToken(String setCode) {
    final tokens = catalog.pool(setCode, Rarity.token, tokens: true);
    final commons = catalog.pool(setCode, Rarity.common);
    final def = tokens.isNotEmpty
        ? tokens[_rng.nextInt(tokens.length)]
        : (commons.isNotEmpty
            ? commons[_rng.nextInt(commons.length)]
            : catalog.bySet[setCode]!.first);
    return _instantiate(def, foil: false);
  }

  /// Optional DON!! slot when the set catalog includes DON / token cards.
  OwnedCard? _drawDon(String setCode) {
    final tokens = catalog.pool(setCode, Rarity.token, tokens: true);
    final dons = tokens
        .where((c) {
          final n = c.name.toLowerCase();
          final t = (c.cardType ?? '').toLowerCase();
          return n.contains('don') || t.contains('don');
        })
        .toList();
    var pool = dons.isNotEmpty ? dons : tokens;
    if (pool.isEmpty) {
      // Fallback: older catalogs may tag DON!! as Common.
      final all = catalog.bySet[setCode] ?? const <CardDef>[];
      pool = all
          .where((c) {
            final n = c.name.toLowerCase();
            final t = (c.cardType ?? '').toLowerCase();
            return n.contains('don!!') || t.contains('don');
          })
          .toList();
    }
    if (pool.isEmpty) return null;
    return _instantiate(pool[_rng.nextInt(pool.length)], foil: false);
  }

  Rarity _rollRarePlus(String setCode) {
    final roll = _rng.nextDouble();
    if (catalog.isPokemon) {
      // Modern SV booster rare slot ≈ mostly Rare; IR/SIR (Epic) ~1/6–1/8 packs.
      if (roll < 0.84) return Rarity.rare;
      if (roll < 0.97) return Rarity.epic;
      return Rarity.promo;
    }
    if (catalog.isOnePiece) {
      // OPTCG: R common in rare slot; SR less often; SEC / Leader rare.
      if (roll < 0.74) return Rarity.rare;
      if (roll < 0.92) return Rarity.epic;
      if (roll < 0.98) return Rarity.showcase;
      return Rarity.promo;
    }
    if (catalog.isYugioh) {
      // Modern TCG rare slot: mostly Rare/Super, Ultra less, Starlight/Secret rare.
      if (roll < 0.72) return Rarity.rare;
      if (roll < 0.90) return Rarity.epic;
      if (roll < 0.985) return Rarity.showcase;
      return Rarity.promo;
    }
    if (catalog.isGundam) {
      // GCG: R common in rare slot; LR less; LR+/SCR rarer.
      if (roll < 0.70) return Rarity.rare;
      if (roll < 0.90) return Rarity.epic;
      if (roll < 0.98) return Rarity.showcase;
      return Rarity.promo;
    }
    if (catalog.isMtg) {
      // Play Booster rare/mythic slot — mostly rares, ~1/7–1/8 mythic-ish.
      if (roll < 0.86) return Rarity.rare;
      if (roll < 0.97) return Rarity.epic;
      if (roll < 0.995) return Rarity.showcase;
      return Rarity.signature;
    }
    // Riftbound: community-ish rare+ foil slots (no box chase injection).
    if (setCode == 'UNL' && roll < 0.001) return Rarity.ultimate;
    if (roll < 0.78) return Rarity.rare;
    if (roll < 0.93) return Rarity.epic;
    if (roll < 0.98) return Rarity.showcase;
    if (roll < 0.996) return Rarity.overnumbered;
    return Rarity.signature;
  }

  CardDef? _pick(String setCode, Rarity rarity) {
    var pool = catalog.pool(setCode, rarity);
    if (pool.isEmpty && rarity == Rarity.showcase) {
      pool = catalog.pool(setCode, Rarity.epic);
    }
    if (pool.isEmpty) return null;
    return pool[_rng.nextInt(pool.length)];
  }

  OwnedCard _instantiate(CardDef def, {required bool foil}) {
    final condition = _rollSealedCondition();
    final centeringLR = _gauss(50, 8).clamp(5, 95);
    final centeringTB = _gauss(50, 8).clamp(5, 95);
    final defects = <FactoryDefect>[];
    if (_rng.nextDouble() < 0.04) defects.add(FactoryDefect.whitening);
    if (_rng.nextDouble() < 0.02) defects.add(FactoryDefect.printLine);
    if (_rng.nextDouble() < 0.015) defects.add(FactoryDefect.bentCorner);
    if ((centeringLR - 50).abs() > 18 || (centeringTB - 50).abs() > 18) {
      if (_rng.nextDouble() < 0.5) defects.add(FactoryDefect.offCenter);
    }
    if (_rng.nextDouble() < 0.004) defects.add(FactoryDefect.miscut);

    return OwnedCard(
      instanceId: _uuid.v4(),
      cardId: def.id,
      foil: foil,
      condition: condition,
      centeringLR: centeringLR.toDouble(),
      centeringTB: centeringTB.toDouble(),
      surface: _gauss(9.2, 0.6).clamp(4, 10).toDouble(),
      edges: _gauss(9.1, 0.7).clamp(4, 10).toDouble(),
      corners: _gauss(9.0, 0.8).clamp(3, 10).toDouble(),
      defects: defects,
    );
  }

  Condition _rollSealedCondition() {
    final r = _rng.nextDouble();
    // Sealed-fresh feel: mostly Mint/NM.
    if (r < 0.70) return Condition.mint;
    if (r < 0.95) return Condition.nearMint;
    if (r < 0.99) return Condition.lightlyPlayed;
    return Condition.moderatelyPlayed;
  }

  double _gauss(double mean, double std) {
    final u1 = _rng.nextDouble().clamp(1e-9, 1.0);
    final u2 = _rng.nextDouble();
    final z = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    return mean + z * std;
  }
}
