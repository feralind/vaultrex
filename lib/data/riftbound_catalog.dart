import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/enums.dart';
import '../models/models.dart';

class RiftboundCatalog {
  RiftboundCatalog._(this.cards, this.sealed, this.byId, this.bySet);

  final List<CardDef> cards;
  final List<SealedProduct> sealed;
  final Map<String, CardDef> byId;
  final Map<String, List<CardDef>> bySet;

  static RiftboundCatalog? _instance;

  static Future<RiftboundCatalog> load() async {
    if (_instance != null) return _instance!;
    final cardRaw =
        jsonDecode(await rootBundle.loadString('assets/data/riftbound_catalog.json'))
            as Map<String, dynamic>;
    final sealedRaw =
        jsonDecode(await rootBundle.loadString('assets/data/sealed_products.json'))
            as Map<String, dynamic>;

    final cards = <CardDef>[];
    for (final e in (cardRaw['cards'] as List)) {
      final m = e as Map<String, dynamic>;
      final name = m['name'] as String? ?? '';
      final rarity = parseRarity(m['rarity'] as String?);
      final number = m['number'] as String?;
      // Singles only — never admit sealed kits/packs/boxes into CardDef catalog.
      if (_looksLikeSealedProduct(name) || number == null || number.isEmpty) {
        continue;
      }
      if (rarity == Rarity.none) continue;
      cards.add(CardDef.fromJson(m));
    }

    final sealed = (sealedRaw['products'] as List)
        .map((e) => SealedProduct.fromJson(e as Map<String, dynamic>))
        .where((p) => p.kind == SealedKind.pack || p.kind == SealedKind.box)
        .toList();

    final byId = {for (final c in cards) c.id: c};
    final bySet = <String, List<CardDef>>{};
    for (final c in cards) {
      bySet.putIfAbsent(c.setCode, () => []).add(c);
    }
    _instance = RiftboundCatalog._(cards, sealed, byId, bySet);
    return _instance!;
  }

  List<CardDef> pool(String setCode, Rarity rarity, {bool tokens = false}) {
    final list = bySet[setCode] ?? const [];
    return list.where((c) {
      final isToken = c.cardType?.toLowerCase() == 'token' ||
          c.rarity == Rarity.token ||
          (c.number == null && c.cardType == 'Token');
      if (tokens) return isToken || c.rarity == Rarity.token;
      if (isToken) return false;
      return c.rarity == rarity;
    }).toList();
  }
}

/// Sealed product names that sometimes leak into TCGCSV "products" as faux cards.
bool _looksLikeSealedProduct(String name) {
  final n = name.toLowerCase();
  return n.contains('booster') ||
      n.contains('display') ||
      n.contains('promo pack') ||
      n.contains('bundle') ||
      n.contains('pre-rift') ||
      n.contains('event kit') ||
      n.contains('bulk runes') ||
      n.contains('art bundle') ||
      RegExp(r'\bkit\b').hasMatch(n) ||
      RegExp(r'\bbox\b').hasMatch(n);
}

/// True when [c] is a real graded-single candidate (collector # + chase rarity/price).
bool isSlabEligibleCard(CardDef c) {
  if (c.number == null || c.number!.isEmpty) return false;
  if (_looksLikeSealedProduct(c.name)) return false;
  if (c.rarity == Rarity.token || c.rarity == Rarity.none) return false;
  if (c.cardType?.toLowerCase() == 'token') return false;
  final chaseRarity = c.rarity == Rarity.epic ||
      c.rarity == Rarity.showcase ||
      c.rarity == Rarity.overnumbered ||
      c.rarity == Rarity.signature ||
      c.rarity == Rarity.ultimate ||
      c.rarity == Rarity.promo ||
      (c.rarity == Rarity.rare && c.marketPrice >= 8);
  final expensive = c.marketPrice >= 25 ||
      (c.foilMarketPrice != null && c.foilMarketPrice! >= 40);
  return chaseRarity || expensive;
}

/// HD art URLs for Instapacks PSA mini-slab rotation (set chase cards).
///
/// Prefers [isSlabEligibleCard] / rare+, foil-eligible, high [CardDef.marketPrice].
List<String> chaseArtUrlsForSet(
  RiftboundCatalog catalog,
  String setCode, {
  int count = 6,
}) {
  final pool = catalog.bySet[setCode] ?? const <CardDef>[];
  if (pool.isEmpty || count <= 0) return const [];

  var picks = pool
      .where(isSlabEligibleCard)
      .where((c) => c.displayArtUrl.isNotEmpty)
      .toList();
  if (picks.length < 4) {
    picks = pool
        .where(
          (c) =>
              c.displayArtUrl.isNotEmpty &&
              c.rarity != Rarity.token &&
              c.rarity != Rarity.none &&
              (c.rarity.isRarePlus || c.marketPrice >= 5),
        )
        .toList();
  }

  int rarityRank(Rarity r) => switch (r) {
        Rarity.ultimate => 8,
        Rarity.signature => 7,
        Rarity.overnumbered => 6,
        Rarity.showcase => 5,
        Rarity.epic => 4,
        Rarity.promo => 3,
        Rarity.rare => 2,
        Rarity.uncommon => 1,
        _ => 0,
      };

  picks.sort((a, b) {
    final foilA = a.foilMarketPrice != null ? 1 : 0;
    final foilB = b.foilMarketPrice != null ? 1 : 0;
    if (foilA != foilB) return foilB.compareTo(foilA);
    final rr = rarityRank(b.rarity).compareTo(rarityRank(a.rarity));
    if (rr != 0) return rr;
    final price = b.marketPrice.compareTo(a.marketPrice);
    if (price != 0) return price;
    return a.id.compareTo(b.id);
  });

  final seen = <String>{};
  final urls = <String>[];
  for (final c in picks) {
    final url = c.displayArtUrl;
    if (!seen.add(url)) continue;
    urls.add(url);
    if (urls.length >= count) break;
  }
  return urls;
}

Rarity parseRarity(String? raw) {
  if (raw == null || raw.isEmpty || raw == 'None') return Rarity.none;
  switch (raw.toLowerCase()) {
    case 'common':
      return Rarity.common;
    case 'uncommon':
      return Rarity.uncommon;
    case 'rare':
      return Rarity.rare;
    case 'epic':
      return Rarity.epic;
    case 'showcase':
      return Rarity.showcase;
    case 'overnumbered':
      return Rarity.overnumbered;
    case 'signature':
      return Rarity.signature;
    case 'ultimate':
      return Rarity.ultimate;
    case 'promo':
      return Rarity.promo;
    case 'token':
      return Rarity.token;
    default:
      if (raw.toLowerCase().contains('showcase')) return Rarity.showcase;
      if (raw.toLowerCase().contains('signature')) return Rarity.signature;
      return Rarity.none;
  }
}
