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
  /// CDN path segment: `pokemon` | `riftbound` | `magicthegathering` | `onepiece`.
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

  /// One Piece expansions keyed by Bindora setCode (CDN path: onepiece).
  static const onepieceExpansions = <String, ScrydexExpansion>{
    'OP01': ScrydexExpansion(
      id: 'OP01',
      gamePath: 'onepiece',
      name: 'Romance Dawn',
      type: 'Expansion',
      total: 121,
      printedTotal: 121,
      releaseDate: '2022/12/02',
      hasSymbol: true,
    ),
    'OP02': ScrydexExpansion(
      id: 'OP02',
      gamePath: 'onepiece',
      name: 'Paramount War',
      type: 'Expansion',
      total: 121,
      printedTotal: 121,
      releaseDate: '2023/03/10',
      hasSymbol: true,
    ),
    'OP05': ScrydexExpansion(
      id: 'OP05',
      gamePath: 'onepiece',
      name: 'Awakening of the New Era',
      type: 'Expansion',
      total: 121,
      printedTotal: 121,
      releaseDate: '2023/12/08',
      hasSymbol: true,
    ),
    'OP09': ScrydexExpansion(
      id: 'OP09',
      gamePath: 'onepiece',
      name: 'Emperors in the New World',
      type: 'Expansion',
      total: 121,
      printedTotal: 121,
      releaseDate: '2024/12/13',
      hasSymbol: true,
    ),
    'OP13': ScrydexExpansion(
      id: 'OP13',
      gamePath: 'onepiece',
      name: 'Carrying On His Will',
      type: 'Expansion',
      total: 121,
      printedTotal: 121,
      releaseDate: '2025/09/05',
      hasSymbol: true,
    ),
    'PRB01': ScrydexExpansion(
      id: 'PRB01',
      gamePath: 'onepiece',
      name: 'Premium Booster -The Best-',
      type: 'Supplemental',
      total: 140,
      printedTotal: 140,
      releaseDate: '2024/08/02',
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

  static ScrydexExpansion? onepieceExpansion(String setCode) =>
      onepieceExpansions[setCode.toUpperCase()];

  /// Resolve expansion chrome for any franchise by Bindora setCode.
  static ScrydexExpansion? expansionForSet(String setCode) {
    final key = setCode.toUpperCase();
    return pokemonExpansions[key] ??
        riftboundExpansions[key] ??
        mtgExpansions[key] ??
        onepieceExpansions[key];
  }

  static ScrydexExpansion? expansionFor(CardDef def) {
    if (def.isPokemonCard) return pokemonExpansion(def.setCode);
    if (def.isMtgCard) return mtgExpansion(def.setCode);
    if (def.isOnePieceCard) return onepieceExpansion(def.setCode);
    return riftboundExpansion(def.setCode);
  }

  static String? pokemonExpansionId(String setCode) =>
      pokemonExpansionBySet[setCode.toUpperCase()];

  /// Collector number → Scrydex id suffix (`1`, `T03`, `299`, `307s`).
  ///
  /// Signature / star prints (`307*`) map to a lowercase `s` suffix on Scrydex
  /// (`OGN-307s`). Stripping `*` without the suffix wrongly loads the
  /// overnumbered non-signature art (`OGN-307`).
  ///
  /// One Piece numbers are often already `OP01-001` style — keep the set-number
  /// body and pad the numeric segment to 3 digits for CDN ids.
  static String? normalizeNumber(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var n = raw.split('/').first.trim();
    // Dual-faced catalog rows: "T01 // T05"
    if (n.contains('//')) {
      n = n.split('//').first.trim();
    }
    // One Piece: "OP01-001" / "OP01-001a" → keep as-is for cardIdFor.
    final opFull = RegExp(
      r'^(OP\d+|PRB-?\d+)[- ]?0*([0-9]+[a-zA-Z]?)$',
      caseSensitive: false,
    ).firstMatch(n);
    if (opFull != null) {
      final digits = opFull.group(2)!;
      return digits;
    }
    final isSignature = n.contains('*');
    n = n.replaceAll('*', '').trim();
    if (n.isEmpty) return null;

    // Domain runes: R01 / R01a — Scrydex coverage is incomplete; callers
    // should prefer catalog art via [preferCatalogArt].
    final rune = RegExp(r'^[Rr]0*([0-9]+[a-zA-Z]?)$').firstMatch(n);
    if (rune != null) {
      final body = rune.group(1)!;
      final digits = RegExp(r'^([0-9]+)').firstMatch(body);
      if (digits == null) return 'R${body.toUpperCase()}';
      final rest = body.substring(digits.group(0)!.length);
      final padded = digits.group(1)!.padLeft(2, '0');
      return 'R$padded$rest';
    }

    // Tokens keep T + 2-digit pad (CDN: SFD-T03, not SFD-T3).
    final tok = RegExp(r'^[Tt]0*([0-9]+)$').firstMatch(n);
    if (tok != null) {
      final padded = 'T${tok.group(1)!.padLeft(2, '0')}';
      return isSignature ? '${padded}s' : padded;
    }

    final m = RegExp(r'^0*([0-9]+[a-zA-Z]?)$').firstMatch(n);
    if (m != null) {
      final base = m.group(1)!;
      // Scrydex CDN: signature = number + 's' (e.g. OGN-307s).
      if (isSignature) return '${base}s';
      return base;
    }
    return n.isEmpty ? null : n;
  }

  /// Scrydex-style printed line, e.g. `#001/221`, `#307*/298`, or `#T03/221`.
  static String? printedNumberLabel(CardDef def) {
    final raw = def.number;
    if (raw == null || raw.isEmpty) return null;
    // Keep star / letter suffixes from the catalog (Signature = 307*).
    if (raw.contains('/')) return '#$raw';
    final exp = expansionFor(def);
    final n = normalizeNumber(raw);
    if (n == null) return '#$raw';
    if (exp != null) {
      final pad = n.startsWith('T')
          ? n
          : n.replaceFirst(RegExp(r's$'), '').padLeft(3, '0') +
              (n.endsWith('s') ? '*' : '');
      return '#$pad/${exp.printedTotal}';
    }
    return '#$n';
  }

  /// True when Scrydex CDN lacks a faithful scan — use TCGPlayer catalog art.
  ///
  /// Gaps today: oversized battlefields, domain runes (R01…), and a few tokens
  /// with no public CDN scan (local card-back fallback in catalog).
  static bool preferCatalogArt(CardDef def) {
    final name = def.name.toLowerCase();
    if (name.contains('oversized')) return true;
    final raw = (def.number ?? '').split('/').first.trim();
    if (RegExp(r'^[Rr]\d').hasMatch(raw)) return true;
    // Explicit missing-token ids / local asset overrides in catalog.
    if (def.imageUrl.startsWith('assets/')) return true;
    // OPTCG DON!! and non-main-set reprint numbers without Scrydex coverage.
    if (def.isOnePieceCard) {
      final up = raw.toUpperCase();
      if (up.startsWith('DON') || name.contains('don!!')) return true;
    }
    return false;
  }

  /// Best TCGPlayer-hosted art when Scrydex is unavailable.
  ///
  /// Prefers catalog `imageUrl` when already pointed at a reliable host
  /// (product-images / scrydex). Otherwise builds product-images from
  /// [CardDef.productId] — more reliable than tcgplayer-cdn for some SKUs.
  static String? catalogArtUrl(CardDef def) {
    final existing = def.imageUrl;
    if (existing.contains('product-images.tcgplayer.com') ||
        existing.contains('images.scrydex.com')) {
      return existing;
    }
    if (preferCatalogArt(def)) {
      if (existing.isNotEmpty) return existing;
      if (def.productId > 0) {
        return 'https://product-images.tcgplayer.com/${def.productId}.jpg';
      }
    }
    if (existing.isNotEmpty) return existing;
    if (def.imageUrlSmall.isNotEmpty) return def.imageUrlSmall;
    return null;
  }

  static String? cardIdFor(CardDef def) {
    if (preferCatalogArt(def)) return null;
    var num = normalizeNumber(def.number);
    if (num == null) return null;

    // Dual-face token rows "T02 // T05": prefer Gold face when named Gold.
    final rawNum = (def.number ?? '').trim();
    if (rawNum.contains('//') && def.name.toLowerCase().contains('gold')) {
      final right = rawNum.split('//').last.trim().split('/').first.trim();
      final alt = normalizeNumber(right);
      if (alt != null) num = alt;
    }

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

    if (def.isOnePieceCard) {
      final raw = (def.number ?? '').split('/').first.trim();
      // Already a full Scrydex id (OP01-001 / OP01-001A / ST01-012).
      final full = RegExp(
        r'^((?:OP|ST|EB|PRB)-?\d+)-(\d{1,3}[A-Za-z]?)$',
        caseSensitive: false,
      ).firstMatch(raw);
      if (full != null) {
        final setPart = full.group(1)!.toUpperCase().replaceAll('PRB-0', 'PRB0');
        // Scrydex uses PRB01 (no hyphen) and OP01-001A (upper letter).
        final setNorm = setPart.startsWith('PRB')
            ? setPart.replaceAll('-', '')
            : setPart;
        final body = full.group(2)!;
        final dm = RegExp(r'^(\d+)([A-Za-z]?)$').firstMatch(body)!;
        final padded =
            '${dm.group(1)!.padLeft(3, '0')}${dm.group(2)!.toUpperCase()}';
        return '$setNorm-$padded';
      }
      // DON!! and odd promo numbers — fall back to catalog art.
      if (raw.toUpperCase().startsWith('DON')) return null;

      final set = def.setCode.toUpperCase().replaceAll('-', '');
      if (!onepieceExpansions.containsKey(set) &&
          !onepieceExpansions.containsKey(def.setCode.toUpperCase())) {
        return null;
      }
      final setKey = onepieceExpansions.containsKey(set)
          ? set
          : def.setCode.toUpperCase().replaceAll('-', '');
      // CDN style: OP01-001 (3-digit pad when purely numeric).
      final m = RegExp(r'^(\d+)([a-zA-Z]?)$').firstMatch(num);
      if (m != null) {
        final padded = m.group(1)!.padLeft(3, '0');
        final suffix = (m.group(2) ?? '').toUpperCase();
        return '$setKey-$padded$suffix';
      }
      return null;
    }

    var set = def.setCode.toUpperCase();
    if (!riftboundExpansions.containsKey(set)) return null;
    // Catalog sometimes tags OGN over-numbers as OGS; OGS only prints 001–024.
    if (set == 'OGS') {
      final digits = RegExp(r'^(\d+)').firstMatch(num);
      if (digits != null && int.parse(digits.group(1)!) > 24) {
        set = 'OGN';
      }
    }
    return '$set-$num';
  }

  static String? gamePath(CardDef def) {
    if (preferCatalogArt(def)) return null;
    if (def.isPokemonCard) {
      return pokemonExpansionId(def.setCode) != null ? 'pokemon' : null;
    }
    if (def.isMtgCard) {
      return mtgExpansions.containsKey(def.setCode.toUpperCase())
          ? 'magicthegathering'
          : null;
    }
    if (def.isOnePieceCard) {
      final set = def.setCode.toUpperCase().replaceAll('-', '');
      if (onepieceExpansions.containsKey(set) ||
          onepieceExpansions.containsKey(def.setCode.toUpperCase())) {
        return 'onepiece';
      }
      return null;
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
