/// Scrydex CDN art + expansion helpers
/// (https://scrydex.com / images.scrydex.com).
///
/// Image CDN needs no API key. Live metadata/pricing still need
/// `X-Api-Key` + `X-Team-ID`.
library;

import 'package:flutter/widgets.dart';

import '../models/models.dart';

/// Public expansion facts (logos/symbols work without auth).
class ScrydexExpansion {
  const ScrydexExpansion({
    required this.id,
    required this.gamePath,
    required this.name,
    required this.type,
    required this.total,
    required this.printedTotal,
    required this.releaseDate,
    this.hasSymbol = false,
  });

  /// Scrydex expansion id (e.g. `sv3pt5`, `SFD`, `FDN`).
  final String id;
  /// CDN path segment: `pokemon` | `riftbound` | `magicthegathering`.
  final String gamePath;
  final String name;
  /// e.g. Main, Starter, Scarlet & Violet
  final String type;
  final int total;
  final int printedTotal;
  /// YYYY/MM/DD
  final String releaseDate;
  /// Pokémon + MTG expose set symbols; Riftbound CDN returns 404.
  final bool hasSymbol;

  String get logoUrl =>
      'https://images.scrydex.com/$gamePath/$id-logo/logo';

  String? get symbolUrl => hasSymbol
      ? 'https://images.scrydex.com/$gamePath/$id-symbol/symbol'
      : null;

  /// Header line: `SFD · Main · 221 cards · 2026/02/13`
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

  /// Pokémon expansions keyed by Bindora setCode (CDN logos/symbols free).
  static const pokemonExpansions = <String, ScrydexExpansion>{
    'MEW': ScrydexExpansion(
      id: 'sv3pt5',
      gamePath: 'pokemon',
      name: 'Scarlet & Violet 151',
      type: 'Scarlet & Violet',
      total: 207,
      printedTotal: 165,
      releaseDate: '2023/09/22',
      hasSymbol: true,
    ),
    'OBF': ScrydexExpansion(
      id: 'sv3',
      gamePath: 'pokemon',
      name: 'Obsidian Flames',
      type: 'Scarlet & Violet',
      total: 230,
      printedTotal: 197,
      releaseDate: '2023/08/11',
      hasSymbol: true,
    ),
    'PAL': ScrydexExpansion(
      id: 'sv2',
      gamePath: 'pokemon',
      name: 'Paldea Evolved',
      type: 'Scarlet & Violet',
      total: 279,
      printedTotal: 193,
      releaseDate: '2023/06/09',
      hasSymbol: true,
    ),
    'TWM': ScrydexExpansion(
      id: 'sv6',
      gamePath: 'pokemon',
      name: 'Twilight Masquerade',
      type: 'Scarlet & Violet',
      total: 226,
      printedTotal: 167,
      releaseDate: '2024/05/24',
      hasSymbol: true,
    ),
    'SSP': ScrydexExpansion(
      id: 'sv8',
      gamePath: 'pokemon',
      name: 'Surging Sparks',
      type: 'Scarlet & Violet',
      total: 252,
      printedTotal: 191,
      releaseDate: '2024/11/08',
      hasSymbol: true,
    ),
    'PRE': ScrydexExpansion(
      id: 'sv8pt5',
      gamePath: 'pokemon',
      name: 'Prismatic Evolutions',
      type: 'Scarlet & Violet',
      total: 180,
      printedTotal: 131,
      releaseDate: '2025/01/17',
      hasSymbol: true,
    ),
  };

  /// From Scrydex expansion pages / docs (no API key).
  static const riftboundExpansions = <String, ScrydexExpansion>{
    'OGS': ScrydexExpansion(
      id: 'OGS',
      gamePath: 'riftbound',
      name: 'Proving Grounds',
      type: 'Starter',
      total: 24,
      printedTotal: 24,
      releaseDate: '2025/10/31',
    ),
    'OGN': ScrydexExpansion(
      id: 'OGN',
      gamePath: 'riftbound',
      name: 'Origins',
      type: 'Main',
      total: 352,
      printedTotal: 298,
      releaseDate: '2025/10/31',
    ),
    'SFD': ScrydexExpansion(
      id: 'SFD',
      gamePath: 'riftbound',
      name: 'Spiritforged',
      type: 'Main',
      total: 288,
      printedTotal: 221,
      releaseDate: '2026/02/13',
    ),
    'UNL': ScrydexExpansion(
      id: 'UNL',
      gamePath: 'riftbound',
      name: 'Unleashed',
      type: 'Main',
      total: 286,
      printedTotal: 219,
      releaseDate: '2026/05/08',
    ),
  };

  /// MTG expansions keyed by Bindora setCode (CDN art/logos/symbols free).
  static const mtgExpansions = <String, ScrydexExpansion>{
    'FDN': ScrydexExpansion(
      id: 'FDN',
      gamePath: 'magicthegathering',
      name: 'Foundations',
      type: 'Core',
      total: 775,
      printedTotal: 291,
      releaseDate: '2024/11/15',
      hasSymbol: true,
    ),
    'MH3': ScrydexExpansion(
      id: 'MH3',
      gamePath: 'magicthegathering',
      name: 'Modern Horizons 3',
      type: 'Supplemental',
      total: 657,
      printedTotal: 303,
      releaseDate: '2024/06/14',
      hasSymbol: true,
    ),
    'DSK': ScrydexExpansion(
      id: 'DSK',
      gamePath: 'magicthegathering',
      name: 'Duskmourn: House of Horror',
      type: 'Expansion',
      total: 391,
      printedTotal: 276,
      releaseDate: '2024/09/27',
      hasSymbol: true,
    ),
    'BLB': ScrydexExpansion(
      id: 'BLB',
      gamePath: 'magicthegathering',
      name: 'Bloomburrow',
      type: 'Expansion',
      total: 400,
      printedTotal: 281,
      releaseDate: '2024/08/02',
      hasSymbol: true,
    ),
    'OTJ': ScrydexExpansion(
      id: 'OTJ',
      gamePath: 'magicthegathering',
      name: 'Outlaws of Thunder Junction',
      type: 'Expansion',
      total: 443,
      printedTotal: 276,
      releaseDate: '2024/04/19',
      hasSymbol: true,
    ),
    'DFT': ScrydexExpansion(
      id: 'DFT',
      gamePath: 'magicthegathering',
      name: 'Aetherdrift',
      type: 'Expansion',
      total: 536,
      printedTotal: 276,
      releaseDate: '2025/02/14',
      hasSymbol: true,
    ),
  };

  static Set<String> get riftboundSets => riftboundExpansions.keys.toSet();

  static ScrydexExpansion? riftboundExpansion(String setCode) =>
      riftboundExpansions[setCode.toUpperCase()];

  static ScrydexExpansion? pokemonExpansion(String setCode) =>
      pokemonExpansions[setCode.toUpperCase()];

  static ScrydexExpansion? mtgExpansion(String setCode) =>
      mtgExpansions[setCode.toUpperCase()];

  /// Resolve expansion chrome for any franchise by Bindora setCode.
  static ScrydexExpansion? expansionForSet(String setCode) {
    final key = setCode.toUpperCase();
    return pokemonExpansions[key] ??
        riftboundExpansions[key] ??
        mtgExpansions[key];
  }

  static ScrydexExpansion? expansionFor(CardDef def) {
    if (def.isPokemonCard) return pokemonExpansion(def.setCode);
    if (def.isMtgCard) return mtgExpansion(def.setCode);
    return riftboundExpansion(def.setCode);
  }

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
    final exp = expansionFor(def);
    final n = normalizeNumber(raw);
    if (n == null) return '#$raw';
    if (exp != null) {
      final pad = n.startsWith('T') ? n : n.padLeft(3, '0');
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

    if (def.isMtgCard) {
      final set = def.setCode.toUpperCase();
      if (!mtgExpansions.containsKey(set)) return null;
      return '$set-$num';
    }

    final set = def.setCode.toUpperCase();
    if (riftboundExpansions.containsKey(set)) return '$set-$num';
    return null;
  }

  static String? gamePath(CardDef def) {
    if (def.isPokemonCard) {
      return pokemonExpansionId(def.setCode) != null ? 'pokemon' : null;
    }
    if (def.isMtgCard) {
      return mtgExpansions.containsKey(def.setCode.toUpperCase())
          ? 'magicthegathering'
          : null;
    }
    if (riftboundExpansions.containsKey(def.setCode.toUpperCase())) {
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

  static String? expansionLogoUrl(CardDef def) =>
      expansionFor(def)?.logoUrl;

  static String? expansionSymbolUrl(CardDef def) =>
      expansionFor(def)?.symbolUrl;

  /// Prefer Scrydex expansion name when we have it.
  static String displaySetName(CardDef def) {
    final exp = expansionFor(def);
    return exp?.name ?? def.setName;
  }

  /// Expansion subtitle when known, else display set name.
  static String displaySetLine(CardDef def) {
    final exp = expansionFor(def);
    return exp?.subtitle ?? displaySetName(def);
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
    final exp = ScrydexArt.expansionForSet(setCode);
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

/// Small set symbol (Pokémon / MTG) for detail chrome.
class ScrydexExpansionSymbol extends StatelessWidget {
  const ScrydexExpansionSymbol({
    super.key,
    required this.setCode,
    this.height = 16,
  });

  final String setCode;
  final double height;

  @override
  Widget build(BuildContext context) {
    final exp = ScrydexArt.expansionForSet(setCode);
    final url = exp?.symbolUrl;
    if (url == null) return const SizedBox.shrink();
    return Image.network(
      url,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
