/// Scrydex CDN art + Riftbound expansion helpers
/// (https://scrydex.com / images.scrydex.com).
///
/// Image CDN needs no API key. Live metadata/pricing still need
/// `X-Api-Key` + `X-Team-ID`.
library;

import 'package:flutter/widgets.dart';

import '../models/models.dart';

/// Public expansion facts from Scrydex (logos work without auth).
class ScrydexExpansion {
  const ScrydexExpansion({
    required this.id,
    required this.name,
    required this.type,
    required this.total,
    required this.printedTotal,
    required this.releaseDate,
  });

  final String id;
  final String name;
  /// e.g. Main, Starter
  final String type;
  final int total;
  final int printedTotal;
  /// YYYY/MM/DD
  final String releaseDate;

  String get logoUrl =>
      'https://images.scrydex.com/riftbound/$id-logo/logo';

  /// Scrydex header line: `SFD • Main • 288 cards • Released 2026/02/13`
  String get subtitle =>
      '$id · $type · $printedTotal cards · $releaseDate';
}

abstract final class ScrydexArt {
  /// Bindora setCode → Scrydex expansion id (Pokémon).
  static const pokemonExpansionBySet = <String, String>{
    'MEW': 'sv3pt5',
    'OBF': 'sv3',
    'PAL': 'sv2',
    'TWM': 'sv6',
    'SSP': 'sv8',
    'PRE': 'sv8pt5',
  };

  /// From Scrydex expansion pages / docs (no API key).
  static const riftboundExpansions = <String, ScrydexExpansion>{
    'OGS': ScrydexExpansion(
      id: 'OGS',
      name: 'Proving Grounds',
      type: 'Starter',
      total: 24,
      printedTotal: 24,
      releaseDate: '2025/10/31',
    ),
    'OGN': ScrydexExpansion(
      id: 'OGN',
      name: 'Origins',
      type: 'Main',
      total: 352,
      printedTotal: 298,
      releaseDate: '2025/10/31',
    ),
    'SFD': ScrydexExpansion(
      id: 'SFD',
      name: 'Spiritforged',
      type: 'Main',
      total: 288,
      printedTotal: 221,
      releaseDate: '2026/02/13',
    ),
    'UNL': ScrydexExpansion(
      id: 'UNL',
      name: 'Unleashed',
      type: 'Main',
      total: 286,
      printedTotal: 219,
      releaseDate: '2026/05/08',
    ),
  };

  static Set<String> get riftboundSets => riftboundExpansions.keys.toSet();

  static ScrydexExpansion? riftboundExpansion(String setCode) =>
      riftboundExpansions[setCode.toUpperCase()];

  static String? pokemonExpansionId(String setCode) =>
      pokemonExpansionBySet[setCode.toUpperCase()];

  /// Collector number → Scrydex id suffix (`1`, `T03`, `299`).
  static String? normalizeNumber(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var n = raw.split('/').first.trim();
    // Dual-faced catalog rows: "T01 // T05"
    if (n.contains('//')) {
      n = n.split('//').first.trim();
    }
    n = n.replaceAll('*', '').trim();
    if (n.isEmpty) return null;

    // Tokens keep T + 2-digit pad (CDN: SFD-T03, not SFD-T3).
    final tok = RegExp(r'^[Tt]0*([0-9]+)$').firstMatch(n);
    if (tok != null) {
      return 'T${tok.group(1)!.padLeft(2, '0')}';
    }

    final m = RegExp(r'^0*([0-9]+[a-zA-Z]?)$').firstMatch(n);
    if (m != null) return m.group(1);
    return n.isEmpty ? null : n;
  }

  /// Scrydex-style printed line, e.g. `#001/221` or `#T03/221`.
  static String? printedNumberLabel(CardDef def) {
    final raw = def.number;
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains('/')) return '#$raw'.replaceAll('*', '');
    final exp = riftboundExpansion(def.setCode);
    final n = normalizeNumber(raw);
    if (n == null) return '#$raw';
    if (exp != null) {
      final pad = n.startsWith('T')
          ? n
          : n.padLeft(3, '0');
      return '#$pad/${exp.printedTotal}';
    }
    return '#$n';
  }

  static String? cardIdFor(CardDef def) {
    final num = normalizeNumber(def.number);
    if (num == null) return null;

    if (def.isPokemonCard) {
      final exp = pokemonExpansionId(def.setCode);
      if (exp == null) return null;
      return '$exp-$num';
    }

    if (!def.isMtgCard) {
      final set = def.setCode.toUpperCase();
      if (riftboundExpansions.containsKey(set)) return '$set-$num';
    }

    return null;
  }

  static String? gamePath(CardDef def) {
    if (def.isPokemonCard) return 'pokemon';
    if (!def.isMtgCard &&
        riftboundExpansions.containsKey(def.setCode.toUpperCase())) {
      return 'riftbound';
    }
    return null;
  }

  /// `small` | `medium` | `large`
  static String? imageUrl(CardDef def, {String size = 'large'}) {
    final id = cardIdFor(def);
    final game = gamePath(def);
    if (id == null || game == null) return null;
    return 'https://images.scrydex.com/$game/$id/$size';
  }

  static String? expansionLogoUrl(CardDef def) {
    if (def.isPokemonCard || def.isMtgCard) return null;
    return riftboundExpansion(def.setCode)?.logoUrl;
  }

  /// Prefer Scrydex expansion name when we have it.
  static String displaySetName(CardDef def) {
    final exp = riftboundExpansion(def.setCode);
    return exp?.name ?? def.setName;
  }
}

/// Small expansion logo for chips / detail headers.
class ScrydexExpansionLogo extends StatelessWidget {
  const ScrydexExpansionLogo({
    super.key,
    required this.setCode,
    this.height = 18,
  });

  final String setCode;
  final double height;

  @override
  Widget build(BuildContext context) {
    final exp = ScrydexArt.riftboundExpansion(setCode);
    if (exp == null) return const SizedBox.shrink();
    return Image.network(
      exp.logoUrl,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
