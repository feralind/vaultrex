import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/models.dart';
import 'database.dart';
import 'pricing.dart';
import 'riftbound_catalog.dart';

const kCollectionFranchiseIds = ['riftbound', 'pokemon', 'mtg'];

String franchiseLabel(String id) => switch (id) {
      'pokemon' => 'Pokémon',
      'mtg' => 'Magic',
      _ => 'Riftbound',
    };

class UnifiedCardEntry {
  const UnifiedCardEntry({
    required this.owned,
    required this.def,
    required this.franchiseId,
    required this.fair,
  });

  final OwnedCard owned;
  final CardDef def;
  final String franchiseId;
  final double fair;
}

class UnifiedSetEntry {
  const UnifiedSetEntry({
    required this.franchiseId,
    required this.setCode,
    required this.setName,
    required this.ownedUnique,
    required this.total,
    required this.cards,
  });

  final String franchiseId;
  final String setCode;
  final String setName;
  final int ownedUnique;
  final int total;
  final List<CardDef> cards;

  double get pct => total == 0 ? 0 : ownedUnique / total;
}

class UnifiedCollectionSnapshot {
  const UnifiedCollectionSnapshot({
    required this.cards,
    required this.sets,
  });

  final List<UnifiedCardEntry> cards;
  final List<UnifiedSetEntry> sets;

  double get totalValue =>
      cards.fold<double>(0, (s, e) => s + e.fair);

  int get uniqueCardIds => cards.map((e) => e.owned.cardId).toSet().length;

  List<UnifiedCardEntry> cardsForFranchise(String? franchiseId) {
    if (franchiseId == null || franchiseId == 'ALL') return cards;
    return cards.where((c) => c.franchiseId == franchiseId).toList();
  }

  List<UnifiedSetEntry> setsForFranchise(String? franchiseId) {
    if (franchiseId == null || franchiseId == 'ALL') return sets;
    return sets.where((s) => s.franchiseId == franchiseId).toList();
  }
}

/// Rebuilds when active collection / franchise / day changes.
final unifiedCollectionProvider =
    FutureProvider.autoDispose<UnifiedCollectionSnapshot>((ref) async {
  final state = ref.watch(gameProvider);
  ref.watch(
    gameProvider.select(
      (s) => Object.hash(s.franchiseId, s.collection.length, s.day, s.ready),
    ),
  );
  if (!state.ready) {
    return const UnifiedCollectionSnapshot(cards: [], sets: []);
  }
  return loadUnifiedCollection(
    db: ref.read(databaseProvider),
    active: state,
  );
});

/// Loads every franchise slot + catalog so Collection is not gated by Instapacks.
Future<UnifiedCollectionSnapshot> loadUnifiedCollection({
  required AppDatabase db,
  required GameState active,
}) async {
  final outCards = <UnifiedCardEntry>[];
  final outSets = <UnifiedSetEntry>[];

  for (final id in kCollectionFranchiseIds) {
    final catalog = await GameCatalog.load(id);
    List<OwnedCard> collection;
    List<MarketEvent> events;
    if (id == active.franchiseId && active.ready) {
      collection = active.collection;
      events = active.events;
    } else {
      final payload = await db.loadPayload(id);
      if (payload == null) {
        collection = const [];
        events = const [];
      } else {
        try {
          final gs = GameState.fromJson(payload);
          collection = gs.collection;
          events = gs.events;
        } catch (_) {
          collection = const [];
          events = const [];
        }
      }
    }

    final ownedBySet = <String, Set<String>>{};
    for (final o in collection) {
      final def = catalog.byId[o.cardId];
      if (def == null) continue;
      outCards.add(
        UnifiedCardEntry(
          owned: o,
          def: def,
          franchiseId: id,
          fair: Pricing.fairValue(def, o, events: events),
        ),
      );
      (ownedBySet[def.setCode] ??= {}).add(o.cardId);
    }

    final setCodes = catalog.bySet.keys.toList()..sort();
    for (final code in setCodes) {
      final all = catalog.bySet[code] ?? const <CardDef>[];
      if (all.isEmpty) continue;
      outSets.add(
        UnifiedSetEntry(
          franchiseId: id,
          setCode: code,
          setName: all.first.setName,
          ownedUnique: ownedBySet[code]?.length ?? 0,
          total: all.length,
          cards: all,
        ),
      );
    }
  }

  return UnifiedCollectionSnapshot(cards: outCards, sets: outSets);
}
