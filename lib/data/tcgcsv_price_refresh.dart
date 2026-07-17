import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'riftbound_catalog.dart';

/// Online TCGCSV price refresh with SharedPreferences cache.
class TcgcsvPriceRefresh {
  TcgcsvPriceRefresh._();

  static const _prefsKey = 'vaultrex_tcgcsv_spots_v1';
  static const _prefsAtKey = 'vaultrex_tcgcsv_spots_at_v1';

  static const riftboundCategory = 89;
  static const pokemonCategory = 3;

  static const riftboundGroups = <String, int>{
    'OGS': 24439,
    'OGN': 24344,
    'SFD': 24519,
    'UNL': 24560,
  };

  static const pokemonGroups = <String, int>{
    'MEW': 23237,
    'OBF': 23228,
    'PAL': 23120,
    'TWM': 23473,
    'SSP': 23651,
    'PRE': 23821,
  };

  static DateTime? lastRefreshAt;

  static Map<String, int> groupsFor(String gameId) =>
      gameId == 'pokemon' ? pokemonGroups : riftboundGroups;

  static int categoryFor(String gameId) =>
      gameId == 'pokemon' ? pokemonCategory : riftboundCategory;

  /// Load cached spots for [gameId].
  static Future<Map<int, SpotPrice>> loadCache(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_prefsKey}_$gameId');
    final atMs = prefs.getInt('${_prefsAtKey}_$gameId');
    if (atMs != null) {
      lastRefreshAt = DateTime.fromMillisecondsSinceEpoch(atMs);
    }
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final out = <int, SpotPrice>{};
      for (final e in map.entries) {
        final id = int.tryParse(e.key);
        if (id == null) continue;
        final row = e.value as Map<String, dynamic>;
        final market = (row['m'] as num?)?.toDouble();
        if (market == null || market <= 0) continue;
        out[id] = SpotPrice(
          marketPrice: market,
          foilMarketPrice: (row['f'] as num?)?.toDouble(),
        );
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveCache(
    String gameId,
    Map<int, SpotPrice> spots,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    for (final e in spots.entries) {
      encoded['${e.key}'] = {
        'm': e.value.marketPrice,
        if (e.value.foilMarketPrice != null) 'f': e.value.foilMarketPrice,
      };
    }
    await prefs.setString('${_prefsKey}_$gameId', jsonEncode(encoded));
    final now = DateTime.now();
    lastRefreshAt = now;
    await prefs.setInt('${_prefsAtKey}_$gameId', now.millisecondsSinceEpoch);
  }

  /// Fetch latest prices for catalog sets. Returns empty map on total failure.
  static Future<Map<int, SpotPrice>> fetchSpots({
    required String gameId,
    http.Client? client,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final httpClient = client ?? http.Client();
    final owned = client == null;
    final category = categoryFor(gameId);
    final groups = groupsFor(gameId);
    final merged = <int, SpotPrice>{};

    try {
      for (final entry in groups.entries) {
        final uri = Uri.parse(
          'https://tcgcsv.com/tcgplayer/$category/${entry.value}/prices',
        );
        try {
          final res = await httpClient.get(uri).timeout(timeout);
          if (res.statusCode != 200) continue;
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final results = body['results'] as List? ?? const [];
          mergePriceRows(merged, results);
        } catch (_) {
          // Keep going on per-set failure.
        }
      }
    } finally {
      if (owned) httpClient.close();
    }
    return merged;
  }

  /// Parse TCGCSV price rows into productId → spot (Normal + foil subtypes).
  static void mergePriceRows(Map<int, SpotPrice> out, List<dynamic> results) {
    final normals = <int, double>{};
    final foils = <int, double>{};

    for (final raw in results) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final productId = (m['productId'] as num?)?.toInt();
      final market = (m['marketPrice'] as num?)?.toDouble();
      if (productId == null || market == null || market <= 0) continue;
      final sub = (m['subTypeName'] as String? ?? '').toLowerCase();
      final isFoil = sub.contains('foil') ||
          sub.contains('holo') ||
          sub == 'etched' ||
          sub.contains('reverse');
      if (isFoil) {
        final prev = foils[productId];
        if (prev == null || market > prev) foils[productId] = market;
      } else {
        final prev = normals[productId];
        if (prev == null || sub == 'normal' || market > prev) {
          normals[productId] = market;
        }
      }
    }

    final ids = {...normals.keys, ...foils.keys};
    for (final id in ids) {
      final market = normals[id] ?? foils[id]!;
      final foil = foils[id];
      out[id] = SpotPrice(
        marketPrice: market,
        foilMarketPrice: foil,
      );
    }
  }

  /// Apply cache then attempt online refresh. Returns updated catalog.
  static Future<GameCatalog> refreshCatalog(
    GameCatalog catalog, {
    http.Client? client,
  }) async {
    final gameId = catalog.gameId;
    var next = catalog;

    final cached = await loadCache(gameId);
    if (cached.isNotEmpty) {
      next = next.withPriceOverrides(cached);
    }

    try {
      final fresh = await fetchSpots(gameId: gameId, client: client);
      if (fresh.isNotEmpty) {
        await saveCache(gameId, fresh);
        GameCatalog.clearCache();
        final clean = await GameCatalog.load(gameId);
        next = clean.withPriceOverrides(fresh);
      }
    } catch (_) {
      // Offline / network error — keep cached or bundled.
    }
    return next;
  }
}
