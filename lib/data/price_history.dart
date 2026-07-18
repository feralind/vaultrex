import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// One dated close for market charts (Y = $, X = timeline).
class PricePoint {
  const PricePoint({required this.date, required this.price});
  final DateTime date;
  final double price;
}

/// Spot + optional daily history from asset + local prefs appends.
///
/// Spot values come from TCGCSV / TCGPlayer. Free historical series are not
/// published by TCGplayer, so missing history is synthesized as mean-reverting
/// daily closes around the researched spot (±realistic vol). Successful online
/// refreshes append today's close into SharedPreferences.
class PriceHistoryStore {
  PriceHistoryStore._(this._byId, this.attribution);

  final Map<String, List<PricePoint>> _byId;
  final String attribution;

  static PriceHistoryStore? _instance;
  static const _localKey = 'vaultrex_price_history_local_v1';

  static Future<PriceHistoryStore> load() async {
    if (_instance != null) return _instance!;
    final byId = <String, List<PricePoint>>{};
    var attribution =
        'TCGCSV / TCGplayer spot · Bindora local history.';
    try {
      final raw = jsonDecode(
        await rootBundle.loadString('assets/data/price_history.json'),
      ) as Map<String, dynamic>;
      attribution = (raw['attribution'] as String?) ?? attribution;
      for (final e in (raw['cards'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        final id = m['id'] as String?;
        if (id == null) continue;
        final hist = <PricePoint>[];
        for (final h in (m['history'] as List? ?? const [])) {
          final row = h as Map<String, dynamic>;
          final d = DateTime.tryParse(row['date'] as String? ?? '');
          final p = (row['price'] as num?)?.toDouble();
          if (d == null || p == null) continue;
          hist.add(PricePoint(date: d, price: p));
        }
        if (hist.isNotEmpty) byId[id] = hist;
      }
    } catch (_) {
      // Asset optional until generated; fall back to synthetic series.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          final hist = <PricePoint>[];
          for (final h in (e.value as List? ?? const [])) {
            final row = h as Map<String, dynamic>;
            final d = DateTime.tryParse(row['d'] as String? ?? '');
            final p = (row['p'] as num?)?.toDouble();
            if (d == null || p == null) continue;
            hist.add(PricePoint(date: d, price: p));
          }
          if (hist.isEmpty) continue;
          final existing = byId[e.key] ?? <PricePoint>[];
          byId[e.key] = _mergeHistory(existing, hist);
        }
      }
    } catch (_) {}

    _instance = PriceHistoryStore._(byId, attribution);
    return _instance!;
  }

  static void clearInstance() => _instance = null;

  static List<PricePoint> _mergeHistory(
    List<PricePoint> a,
    List<PricePoint> b,
  ) {
    final byDay = <String, PricePoint>{};
    for (final p in [...a, ...b]) {
      final key =
          '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}';
      byDay[key] = p;
    }
    final out = byDay.values.toList()
      ..sort((x, y) => x.date.compareTo(y.date));
    while (out.length > 180) {
      out.removeAt(0);
    }
    return out;
  }

  /// Append today's spot closes for [cardId → price]. Reloads singleton.
  static Future<void> appendSpots(Map<String, double> cardSpots) async {
    if (cardSpots.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = <String, List<Map<String, dynamic>>>{};
    try {
      final raw = prefs.getString(_localKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          existing[e.key] = [
            for (final h in (e.value as List? ?? const []))
              Map<String, dynamic>.from(h as Map),
          ];
        }
      }
    } catch (_) {}

    final today = DateTime.now().toUtc();
    final dayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    for (final e in cardSpots.entries) {
      if (e.value <= 0) continue;
      final list = existing.putIfAbsent(e.key, () => []);
      list.removeWhere((h) => (h['d'] as String? ?? '').startsWith(dayKey));
      list.add({'d': today.toIso8601String(), 'p': e.value});
      while (list.length > 180) {
        list.removeAt(0);
      }
    }
    await prefs.setString(_localKey, jsonEncode(existing));
    clearInstance();
    await load();
  }

  /// Prefer local+asset history; otherwise build a dated series ending at [spot].
  List<PricePoint> seriesFor(CardDef def, {double? spot, int days = 90}) {
    final cached = _byId[def.id];
    if (cached != null && cached.length >= 2) {
      if (cached.length <= days) return cached;
      return cached.sublist(cached.length - days);
    }
    final current = spot ?? def.marketPrice;
    return synthesize(def.id, current, days: days);
  }

  /// Deterministic mean-reverting path ending at [current] on "today".
  static List<PricePoint> synthesize(
    String cardId,
    double current, {
    int days = 90,
    DateTime? asOf,
  }) {
    if (current <= 0) {
      final end = asOf ?? DateTime.now().toUtc();
      return [PricePoint(date: end, price: 0.01)];
    }
    final end = asOf ?? DateTime.now().toUtc();
    final rng = Random(cardId.hashCode ^ (current * 100).round());
    final vol = current >= 500
        ? 0.028
        : current >= 50
            ? 0.035
            : 0.045;
    final prices = List<double>.filled(days, 0);
    prices[days - 1] = current;
    var v = current;
    for (var i = days - 2; i >= 0; i--) {
      final drift = (rng.nextDouble() - 0.50) * vol;
      final pull = (current - v) / current * 0.04;
      v = (v * (1 + drift + pull)).clamp(current * 0.55, current * 1.45);
      prices[i] = double.parse(v.toStringAsFixed(2));
    }
    return List.generate(days, (i) {
      return PricePoint(
        date: end.subtract(Duration(days: days - 1 - i)),
        price: prices[i],
      );
    });
  }
}
