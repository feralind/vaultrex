import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/models.dart';

/// One dated close for market charts (Y = $, X = timeline).
class PricePoint {
  const PricePoint({required this.date, required this.price});
  final DateTime date;
  final double price;
}

/// Spot + optional daily history from [assets/data/price_history.json].
///
/// Spot values come from TCGCSV / TCGPlayer (category 89). Free historical
/// series are not published by TCGPlayer, so missing history is synthesized
/// as mean-reverting daily closes around the researched spot (±realistic vol).
class PriceHistoryStore {
  PriceHistoryStore._(this._byId, this.attribution);

  final Map<String, List<PricePoint>> _byId;
  final String attribution;

  static PriceHistoryStore? _instance;

  static Future<PriceHistoryStore> load() async {
    if (_instance != null) return _instance!;
    final byId = <String, List<PricePoint>>{};
    var attribution =
        'TCGCSV category 89 (TCGPlayer market). History anchored to spot.';
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
    _instance = PriceHistoryStore._(byId, attribution);
    return _instance!;
  }

  /// Prefer asset history; otherwise build a dated series ending at [spot].
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
      final end = asOf ?? DateTime.utc(2026, 7, 16);
      return [PricePoint(date: end, price: 0.01)];
    }
    final end = asOf ?? DateTime.utc(2026, 7, 16);
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
