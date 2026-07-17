import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../data/featured_packs.dart';
import '../data/pricing.dart';
import '../data/onboarding.dart';
import '../data/price_history.dart';
import '../data/riftbound_catalog.dart';
import '../data/tcgcsv_price_refresh.dart';
import '../models/enums.dart';
import '../models/models.dart';
import 'featured_pack_opener.dart';
import 'pack_opener.dart';

part 'rip_session.dart';
part 'shop_actions.dart';
part 'grading_actions.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

const _sellerNames = [
  'PackDispenser_Pro',
  'SealedVault',
  'NexusNightDeals',
  'RuneRunnerCards',
  'BoxBreakBenny',
  'LaneSharkLGS',
  'TrendWatcherTCG',
  'BulkBaron',
];

const upgrades = [
  UpgradeDef(
    id: 'fee_cut',
    name: 'Fee Negotiator',
    description: 'Online listing fees drop to 8%.',
    cost: 250,
    requiredXp: 40,
  ),
  UpgradeDef(
    id: 'auto_snipe',
    name: 'Auto-Snipe',
    description: 'Auctions auto-bid once per day when under fair value.',
    cost: 400,
    requiredXp: 80,
  ),
  UpgradeDef(
    id: 'mass_reveal',
    name: 'Mass Reveal',
    description: 'Crack all ready slabs at once.',
    cost: 600,
    requiredXp: 120,
  ),
];

class GameState {
  const GameState({
    required this.ready,
    required this.catalogLoaded,
    required this.player,
    required this.collection,
    required this.unopened,
    required this.sealedListings,
    required this.market,
    required this.onlineListings,
    required this.grading,
    required this.auctions,
    required this.events,
    required this.day,
    required this.lastRip,
    required this.lastRipPaid,
    required this.message,
    required this.migrationNotice,
    this.franchiseId = 'riftbound',
    this.valueHistory = const [],
    this.binders = const [],
    this.recentlyKeptIds = const {},
  });

  final bool ready;
  final bool catalogLoaded;
  /// Active TCG franchise for this save slot (`riftbound` | `pokemon`).
  final String franchiseId;
  final PlayerStats player;
  final List<OwnedCard> collection;
  final List<UnopenedPack> unopened;
  final List<SealedListing> sealedListings;
  final List<MarketListing> market;
  final List<OnlineListing> onlineListings;
  final List<GradingJob> grading;
  final List<AuctionLot> auctions;
  final List<MarketEvent> events;
  final int day;
  final List<OwnedCard>? lastRip;
  final double? lastRipPaid;
  final String? message;
  final String? migrationNotice;
  final List<CollectionValuePoint> valueHistory;
  final List<Binder> binders;
  /// Session-only: instance ids just kept from a rip (for entrance pulse).
  final Set<String> recentlyKeptIds;

  factory GameState.loading() => GameState(
        ready: false,
        catalogLoaded: false,
        franchiseId: 'riftbound',
        player: PlayerStats(),
        collection: const [],
        unopened: const [],
        sealedListings: const [],
        market: const [],
        onlineListings: const [],
        grading: const [],
        auctions: const [],
        events: const [],
        day: 1,
        lastRip: null,
        lastRipPaid: null,
        message: null,
        migrationNotice: null,
        valueHistory: const [],
        binders: const [],
        recentlyKeptIds: const {},
      );

  GameState copyWith({
    bool? ready,
    bool? catalogLoaded,
    String? franchiseId,
    PlayerStats? player,
    List<OwnedCard>? collection,
    List<UnopenedPack>? unopened,
    List<SealedListing>? sealedListings,
    List<MarketListing>? market,
    List<OnlineListing>? onlineListings,
    List<GradingJob>? grading,
    List<AuctionLot>? auctions,
    List<MarketEvent>? events,
    int? day,
    List<OwnedCard>? lastRip,
    double? lastRipPaid,
    bool clearLastRip = false,
    String? message,
    bool clearMessage = false,
    String? migrationNotice,
    bool clearMigration = false,
    List<CollectionValuePoint>? valueHistory,
    List<Binder>? binders,
    Set<String>? recentlyKeptIds,
  }) {
    return GameState(
      ready: ready ?? this.ready,
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      franchiseId: franchiseId ?? this.franchiseId,
      player: player ?? this.player,
      collection: collection ?? this.collection,
      unopened: unopened ?? this.unopened,
      sealedListings: sealedListings ?? this.sealedListings,
      market: market ?? this.market,
      onlineListings: onlineListings ?? this.onlineListings,
      grading: grading ?? this.grading,
      auctions: auctions ?? this.auctions,
      events: events ?? this.events,
      day: day ?? this.day,
      lastRip: clearLastRip ? null : (lastRip ?? this.lastRip),
      lastRipPaid: clearLastRip ? null : (lastRipPaid ?? this.lastRipPaid),
      message: clearMessage ? null : (message ?? this.message),
      migrationNotice:
          clearMigration ? null : (migrationNotice ?? this.migrationNotice),
      valueHistory: valueHistory ?? this.valueHistory,
      binders: binders ?? this.binders,
      recentlyKeptIds: recentlyKeptIds ?? this.recentlyKeptIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'v': 2,
        'franchiseId': franchiseId,
        'player': player.toJson(),
        'collection': collection.map((e) => e.toJson()).toList(),
        'unopened': unopened.map((e) => e.toJson()).toList(),
        'sealedListings': sealedListings.map((e) => e.toJson()).toList(),
        'market': market.map((e) => e.toJson()).toList(),
        'onlineListings': onlineListings.map((e) => e.toJson()).toList(),
        'grading': grading.map((e) => e.toJson()).toList(),
        'auctions': auctions.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'day': day,
        'lastRip': lastRip?.map((e) => e.toJson()).toList(),
        'lastRipPaid': lastRipPaid,
        'valueHistory': valueHistory.map((e) => e.toJson()).toList(),
        'binders': binders.map((e) => e.toJson()).toList(),
      };

  factory GameState.fromJson(Map<String, dynamic> j) {
    final v = j['v'] as int? ?? 1;
    if (v < 2) {
      // Wipe incompatible parody saves.
      return GameState(
        ready: true,
        catalogLoaded: true,
        franchiseId: 'riftbound',
        player: PlayerStats(cash: 500),
        collection: const [],
        unopened: const [],
        sealedListings: const [],
        market: const [],
        onlineListings: const [],
        grading: const [],
        auctions: const [],
        events: const [],
        day: 1,
        lastRip: null,
        lastRipPaid: null,
        message: null,
        migrationNotice:
            'Save upgraded to Riftbound. Parody inventory was reset.',
        valueHistory: const [],
        binders: const [],
        recentlyKeptIds: const {},
      );
    }
    final fid = (j['franchiseId'] as String?) == 'pokemon'
        ? 'pokemon'
        : 'riftbound';
    return GameState(
      ready: true,
      catalogLoaded: true,
      franchiseId: fid,
      player: PlayerStats.fromJson(j['player'] as Map<String, dynamic>),
      collection: (j['collection'] as List? ?? [])
          .map((e) => OwnedCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      unopened: (j['unopened'] as List? ?? [])
          .map((e) => UnopenedPack.fromJson(e as Map<String, dynamic>))
          .toList(),
      sealedListings: (j['sealedListings'] as List? ?? [])
          .map((e) => SealedListing.fromJson(e as Map<String, dynamic>))
          .toList(),
      market: (j['market'] as List? ?? [])
          .map((e) => MarketListing.fromJson(e as Map<String, dynamic>))
          .toList(),
      onlineListings: (j['onlineListings'] as List? ?? [])
          .map((e) => OnlineListing.fromJson(e as Map<String, dynamic>))
          .toList(),
      grading: (j['grading'] as List? ?? [])
          .map((e) => GradingJob.fromJson(e as Map<String, dynamic>))
          .toList(),
      auctions: (j['auctions'] as List? ?? [])
          .map((e) => AuctionLot.fromJson(e as Map<String, dynamic>))
          .toList(),
      events: (j['events'] as List? ?? [])
          .map((e) => MarketEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      day: j['day'] as int? ?? 1,
      lastRip: (j['lastRip'] as List?)
          ?.map((e) => OwnedCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastRipPaid: (j['lastRipPaid'] as num?)?.toDouble(),
      message: null,
      migrationNotice: null,
      valueHistory: (j['valueHistory'] as List? ?? [])
          .map((e) => CollectionValuePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      binders: (j['binders'] as List? ?? [])
          .map((e) => Binder.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentlyKeptIds: const {},
    );
  }
}

/// Library-private base so part mixins can share fields without circular
/// `on GameNotifier` inheritance.
abstract class _GameNotifierBase extends Notifier<GameState> {
  final _uuid = const Uuid();
  final _rng = Random();
  late RiftboundCatalog _catalog;
  late RiftboundPackOpener _opener;
  late FeaturedPackOpener _featuredOpener;
  late AppDatabase _db;

  Future<void>? _ripChain;
  bool _shopBusy = false;

  bool get isShopBusy => _shopBusy;
  bool get isRipBusy => _ripChain != null;

  Future<T> _enqueueRip<T>(Future<T> Function() action) {
    final previous = _ripChain;
    final done = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      return action();
    }();
    final marker = done.then((_) {}, onError: (_) {});
    _ripChain = marker;
    marker.whenComplete(() {
      if (identical(_ripChain, marker)) {
        _ripChain = null;
      }
    });
    return done;
  }

  Future<void> _persist();
  void _checkAchievements();
  // ignore: unused_element_parameter — `force` is passed from GameNotifier callers
  void _recordCollectionValue({bool force = false});
  double fairFor(OwnedCard card);
  SealedProduct? sealedById(String id);
}

class GameNotifier extends _GameNotifierBase
    with _RipSession, _ShopActions, _GradingActions {
  RiftboundCatalog get catalog => _catalog;

  String get activeGameId => _catalog.gameId;

  /// Switch franchise (Riftbound ↔ Pokémon). Each franchise keeps its own
  /// market / sealed / collection slot; wallet (cash/candy/xp) stays shared.
  Future<void> switchFranchise(String gameId) async {
    final id = gameId == 'pokemon' ? 'pokemon' : 'riftbound';
    if (_catalog.gameId == id && state.ready) return;

    // Persist current franchise economy before leaving.
    if (state.ready && state.catalogLoaded) {
      await _persist();
    }

    final wallet = state.player;
    await OnboardingStore.complete(gameId: id);
    GameCatalog.clearCache();
    _catalog = await GameCatalog.load(id);
    await _applySpotRefresh();
    _opener = RiftboundPackOpener(_catalog);
    _featuredOpener = FeaturedPackOpener(_catalog);

    final raw = await _db.loadPayload(id);
    GameState next;
    if (raw != null) {
      try {
        next = GameState.fromJson(raw).copyWith(
          ready: true,
          catalogLoaded: true,
          franchiseId: id,
          player: wallet,
        );
        next = _sanitizeEconomy(next);
        if (next.market.isEmpty || _marketNeedsRegen(next.market)) {
          next = next.copyWith(market: _generateSinglesMarket());
        }
        if (next.sealedListings.isEmpty) {
          next = next.copyWith(sealedListings: _generateSealedShop(next.events));
        }
        next = next.copyWith(
          message: id == 'pokemon'
              ? 'Switched to Pokémon — your Pokémon market restored.'
              : 'Switched to Riftbound — your Riftbound market restored.',
        );
      } catch (_) {
        next = _freshFranchiseState(id, wallet);
      }
    } else {
      next = _freshFranchiseState(id, wallet);
    }

    state = next;
    await _persist();
  }

  GameState _freshFranchiseState(String id, PlayerStats wallet) {
    return GameState(
      ready: true,
      catalogLoaded: true,
      franchiseId: id,
      player: wallet,
      collection: const [],
      unopened: const [],
      sealedListings: _generateSealedShop(const []),
      market: _generateSinglesMarket(),
      onlineListings: const [],
      grading: const [],
      auctions: _generateAuctions(),
      events: [_randomEvent()],
      day: 1,
      lastRip: null,
      lastRipPaid: null,
      message: id == 'pokemon'
          ? 'Switched to Pokémon — sealed & singles stocked.'
          : 'Switched to Riftbound — sealed & singles stocked.',
      migrationNotice: null,
      valueHistory: [
        CollectionValuePoint(date: DateTime.now(), value: 0),
      ],
      binders: const [],
      recentlyKeptIds: const {},
    );
  }

  @override
  GameState build() {
    _db = ref.read(databaseProvider);
    Future.microtask(_bootstrap);
    return GameState.loading();
  }

  Future<void> _bootstrap() async {
    final gameId = await OnboardingStore.selectedGame();
    await _db.migrateLegacyIfNeeded(gameId);
    _catalog = await GameCatalog.load(gameId);
    await _applySpotRefresh();
    _opener = RiftboundPackOpener(_catalog);
    _featuredOpener = FeaturedPackOpener(_catalog);

    final walletRaw = await _db.loadWallet();
    PlayerStats? sharedWallet;
    if (walletRaw != null) {
      try {
        sharedWallet = PlayerStats.fromJson(walletRaw);
      } catch (_) {}
    }

    final raw = await _db.loadPayload(gameId);
    if (raw != null) {
      try {
        var loaded = GameState.fromJson(raw).copyWith(
          ready: true,
          catalogLoaded: true,
          franchiseId: gameId,
        );
        if (sharedWallet != null) {
          loaded = loaded.copyWith(player: sharedWallet);
        }
        loaded = _sanitizeEconomy(loaded);
        // Refresh Instapacks inventory from latest sealed catalog (prices/art).
        loaded = loaded.copyWith(
          sealedListings: _generateSealedShop(loaded.events),
        );
        if (loaded.market.isEmpty ||
            !loaded.market.any((m) => m.graded) ||
            _marketNeedsRegen(loaded.market)) {
          loaded = loaded.copyWith(market: _generateSinglesMarket());
        }
        state = loaded;
        if (state.valueHistory.isEmpty) {
          _recordCollectionValue(force: true);
        }
        await _persist();
        return;
      } catch (_) {
        // fall through to fresh
      }
    }

    final fresh = GameState(
      ready: true,
      catalogLoaded: true,
      franchiseId: gameId,
      player: sharedWallet ?? const PlayerStats(cash: 500),
      collection: const [],
      unopened: const [],
      sealedListings: _generateSealedShop(const []),
      market: _generateSinglesMarket(),
      onlineListings: const [],
      grading: const [],
      auctions: _generateAuctions(),
      events: [_randomEvent()],
      day: 1,
      lastRip: null,
      lastRipPaid: null,
      message: gameId == 'pokemon'
          ? 'Welcome to Vaultrex — Pokémon sealed & singles.'
          : 'Welcome to Vaultrex — Riftbound sealed & singles.',
      migrationNotice: null,
      valueHistory: [
        CollectionValuePoint(date: DateTime.now(), value: 0),
      ],
      binders: const [],
      recentlyKeptIds: const {},
    );
    state = fresh;
    await _persist();
  }

  /// TCGCSV spot refresh + local history append. Soft-fails offline.
  Future<void> _applySpotRefresh() async {
    try {
      final before = {for (final c in _catalog.cards) c.productId: c.marketPrice};
      _catalog = await TcgcsvPriceRefresh.refreshCatalog(_catalog);
      _opener = RiftboundPackOpener(_catalog);
      _featuredOpener = FeaturedPackOpener(_catalog);
      final spots = <String, double>{};
      for (final c in _catalog.cards) {
        final prev = before[c.productId];
        if (c.marketPrice > 0 && (prev == null || (prev - c.marketPrice).abs() > 0.001)) {
          spots[c.id] = c.marketPrice;
        } else if (c.marketPrice > 0 && TcgcsvPriceRefresh.lastRefreshAt != null) {
          // Still record a daily close when refresh succeeded.
          spots[c.id] = c.marketPrice;
        }
      }
      // Cap append size — top 400 by price to keep prefs lean.
      if (spots.length > 400) {
        final ranked = spots.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        spots
          ..clear()
          ..addEntries(ranked.take(400));
      }
      if (spots.isNotEmpty && TcgcsvPriceRefresh.lastRefreshAt != null) {
        await PriceHistoryStore.appendSpots(spots);
      }
    } catch (_) {}
  }

  @override
  Future<void> _persist() async {
    final id = state.franchiseId == 'pokemon' ? 'pokemon' : 'riftbound';
    await _db.savePayload(id, state.toJson());
    await _db.saveWallet(state.player.toJson());
  }

  /// Drop listings / inventory that do not belong to the active catalog.
  GameState _sanitizeEconomy(GameState s) {
    final sealedIds = {for (final p in _catalog.sealed) p.id};
    final market =
        s.market.where((m) => _catalog.byId.containsKey(m.cardId)).toList();
    final sealedListings = s.sealedListings
        .where((l) => sealedIds.contains(l.sealedProductId))
        .toList();
    final collection =
        s.collection.where((c) => _catalog.byId.containsKey(c.cardId)).toList();
    final keptIds = {for (final c in collection) c.instanceId};
    final unopened = s.unopened
        .where((u) => sealedIds.contains(u.sealedProductId))
        .toList();
    final online = s.onlineListings
        .where((l) => keptIds.contains(l.ownedInstanceId))
        .toList();
    final grading = s.grading
        .where((g) => keptIds.contains(g.ownedInstanceId))
        .toList();
    final auctions =
        s.auctions.where((a) => _catalog.byId.containsKey(a.cardId)).toList();
    return s.copyWith(
      franchiseId: _catalog.gameId,
      market: market,
      sealedListings: sealedListings,
      collection: collection,
      unopened: unopened,
      onlineListings: online,
      grading: grading,
      auctions: auctions,
    );
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);
  void clearMigration() => state = state.copyWith(clearMigration: true);
  void clearLastRip() => state = state.copyWith(clearLastRip: true);

  List<SealedListing> _generateSealedShop(List<MarketEvent> events) {
    final listings = <SealedListing>[];
    for (final p in _catalog.sealed) {
      // Instapacks: Riftbound sealed — packs, boxes, decks, kits (skip wholesale cases).
      if (p.kind == SealedKind.displayCase) continue;
      if (p.name.contains('Art Bundle') || p.name.contains('Case')) continue;
      if (p.name.toLowerCase().contains('code card')) continue;
      if (p.marketPrice <= 0) continue;
      // Prefer real booster pack art over near-zero SKUs floor-priced to $0.99.
      if (p.kind == SealedKind.pack && p.marketPrice < 1.0) continue;
      final mult = Pricing.trendMult(events, p.setCode);
      final jitter = 0.92 + _rng.nextDouble() * 0.2;
      final price = max(0.99, p.marketPrice * mult * jitter);
      final stock = switch (p.kind) {
        SealedKind.box => 40 + _rng.nextInt(80),
        SealedKind.deck || SealedKind.other => 60 + _rng.nextInt(140),
        _ => 120 + _rng.nextInt(380),
      };
      final hot = mult > 1.05;
      listings.add(SealedListing(
        id: _uuid.v4(),
        sealedProductId: p.id,
        price: double.parse(price.toStringAsFixed(2)),
        stock: stock,
        sellerAlias: _sellerNames[_rng.nextInt(_sellerNames.length)],
        trendTag: hot ? 'HOT' : (mult < 0.95 ? 'COLD' : null),
      ));
    }
    listings.sort((a, b) {
      final pa = _catalog.sealed.firstWhere((s) => s.id == a.sealedProductId);
      final pb = _catalog.sealed.firstWhere((s) => s.id == b.sealedProductId);
      // Packs & boxes first, then by market heat.
      int rank(SealedKind k) => switch (k) {
            SealedKind.pack => 0,
            SealedKind.box => 1,
            SealedKind.deck => 2,
            _ => 3,
          };
      final c = rank(pa.kind).compareTo(rank(pb.kind));
      if (c != 0) return c;
      final ta = Pricing.trendMult(events, pa.setCode);
      final tb = Pricing.trendMult(events, pb.setCode);
      return tb.compareTo(ta);
    });
    return listings;
  }

  /// True when saved market still references missing / foreign / sealed IDs.
  bool _marketNeedsRegen(List<MarketListing> market) {
    if (market.isEmpty) return true;
    var foreign = 0;
    for (final m in market) {
      final def = _catalog.byId[m.cardId];
      if (def == null) {
        foreign++;
        continue;
      }
      if (m.graded && !isSlabEligibleCard(def)) return true;
      final n = def.name.toLowerCase();
      if (n.contains('pre-rift') ||
          n.contains('event kit') ||
          RegExp(r'\bkit\b').hasMatch(n) ||
          n.contains('promo pack') ||
          n.contains('bulk runes')) {
        return true;
      }
    }
    // Any foreign-franchise SKU → regenerate this franchise's market only.
    if (foreign > 0) return true;
    return false;
  }

  List<MarketListing> _generateSinglesMarket() {
    // Real secondary-market singles only (TCGCSV spot > 0).
    final pool = _catalog.cards
        .where(
          (c) =>
              !c.isUnlisted &&
              c.marketPrice > 0 &&
              c.number != null &&
              c.number!.isNotEmpty &&
              c.rarity != Rarity.token &&
              c.cardType?.toLowerCase() != 'token',
        )
        .toList()
      ..shuffle(_rng);
    if (pool.isEmpty) return const [];

    final out = <MarketListing>[];
    final rawWeighted = [...pool]
      ..sort((a, b) => b.marketPrice.compareTo(a.marketPrice));

    // Hot chase: top ~20 by spot, 2–6 competing asks.
    final hot = rawWeighted.take(min(20, rawWeighted.length)).toList();
    for (final c in hot) {
      final n = 2 + _rng.nextInt(5); // 2–6
      final usedConds = <Condition>{};
      for (var i = 0; i < n; i++) {
        final listing = _makeMarketListing(
          c,
          graded: false,
          preferUnusedCondition: usedConds,
        );
        usedConds.add(listing.condition);
        out.add(listing);
      }
    }

    // Mid: next ~40 with 1–2 asks.
    final mid = rawWeighted.skip(hot.length).take(40).toList();
    for (final c in mid) {
      final n = 1 + (_rng.nextDouble() < 0.35 ? 1 : 0);
      for (var i = 0; i < n; i++) {
        out.add(_makeMarketListing(c, graded: false));
      }
    }

    // Budget long-tail: sample ~30 lower-priced real cards.
    final budgetPool = rawWeighted.where((c) => c.marketPrice < 8).toList()
      ..shuffle(_rng);
    final seen = out.map((m) => m.cardId).toSet();
    for (final c in budgetPool.take(30)) {
      if (seen.contains(c.id) && _rng.nextDouble() < 0.6) continue;
      out.add(_makeMarketListing(c, graded: false));
      seen.add(c.id);
    }

    // PSA slabs: priced chase only.
    final slabPool = pool.where(isSlabEligibleCard).toList()
      ..sort((a, b) => b.marketPrice.compareTo(a.marketPrice));
    final slabHot = slabPool.take(min(12, slabPool.length)).toList();
    for (final c in slabHot) {
      final n = 2 + _rng.nextInt(3);
      for (var i = 0; i < n; i++) {
        out.add(_makeMarketListing(c, graded: true));
      }
    }
    for (final c in slabPool.skip(slabHot.length).take(10)) {
      out.add(_makeMarketListing(c, graded: true));
    }

    out.shuffle(_rng);
    return out.take(min(120, out.length)).toList();
  }

  /// Keep bargains; replace ~35%+ so the shop feels alive. Cap 120.
  List<MarketListing> _churnSinglesMarket(List<MarketListing> current) {
    final valid =
        current.where((m) => _catalog.byId.containsKey(m.cardId)).toList();
    if (valid.isEmpty) return _generateSinglesMarket();
    final keep = <MarketListing>[];
    final drop = <MarketListing>[];
    for (final m in valid) {
      final def = _catalog.byId[m.cardId]!;
      if (def.isUnlisted) {
        drop.add(m);
        continue;
      }
      final fair =
          (m.foil ? (def.foilMarketPrice ?? def.marketPrice * 2) : def.marketPrice) *
              m.condition.valueMult *
              Pricing.trendMult(state.events, def.setCode);
      final bargain = m.price <= fair * 0.92;
      final keepChance = bargain ? 0.72 : 0.45;
      if (_rng.nextDouble() < keepChance) {
        keep.add(m);
      } else {
        drop.add(m);
      }
    }
    final fresh = _generateSinglesMarket();
    final replaceN = max(drop.length, (valid.length * 0.35).round());
    final next = [...keep, ...fresh.take(replaceN)];
    next.shuffle(_rng);
    return next.take(min(120, next.length)).toList();
  }

  MarketListing _makeMarketListing(
    CardDef c, {
    required bool graded,
    Set<Condition>? preferUnusedCondition,
  }) {
    final seller = SellerType.values[_rng.nextInt(SellerType.values.length)];
    final foil = _rng.nextDouble() < 0.35 && c.foilMarketPrice != null;
    Condition cond;
    if (graded) {
      cond = Condition.nearMint;
    } else {
      final pool = [
        Condition.heavilyPlayed,
        Condition.moderatelyPlayed,
        Condition.lightlyPlayed,
        Condition.nearMint,
        Condition.mint,
      ];
      final unused = preferUnusedCondition == null
          ? pool
          : pool.where((x) => !preferUnusedCondition.contains(x)).toList();
      final pickFrom = unused.isNotEmpty ? unused : pool;
      cond = pickFrom[_rng.nextInt(pickFrom.length)];
    }
    final trend = Pricing.trendMult(state.events, c.setCode);
    final base =
        (foil ? (c.foilMarketPrice ?? c.marketPrice * 2) : c.marketPrice) *
            cond.valueMult *
            trend;

    double grade = 0;
    var price = base;
    if (graded) {
      const steps = [8.0, 8.5, 9.0, 9.5, 10.0];
      grade = steps[_rng.nextInt(steps.length)];
      final gradeMult = grade >= 10
          ? 3.2
          : grade >= 9.5
              ? 2.2
              : grade >= 9
                  ? 1.55
                  : grade >= 8.5
                      ? 1.35
                      : 1.2;
      price = base * gradeMult * 1.2;
    }

    // Tighter to spot — less gamey seller noise.
    if (seller == SellerType.clueless) price *= 0.78 + _rng.nextDouble() * 0.12;
    if (seller == SellerType.scammy) price *= 0.85 + _rng.nextDouble() * 0.12;
    if (seller == SellerType.serious) price *= 0.97 + _rng.nextDouble() * 0.08;
    if (seller == SellerType.goblin) price *= 0.9 + _rng.nextDouble() * 0.15;
    price *= 0.97 + _rng.nextDouble() * 0.06;

    final alias = _sellerNames[_rng.nextInt(_sellerNames.length)];
    final gradeLabel = graded
        ? 'PSA ${grade >= 10 ? '10' : grade.toStringAsFixed(grade % 1 == 0 ? 0 : 1)}'
        : null;
    final ratingJitter = (seller.rating + (_rng.nextDouble() * 2.4 - 1.2))
        .clamp(55.0, 99.9);
    final sales =
        (seller.typicalSales * (0.55 + _rng.nextDouble() * 0.9)).round();

    return MarketListing(
      id: _uuid.v4(),
      sellerType: seller,
      title: graded
          ? '${c.name} · #${c.number} · $gradeLabel${foil ? ' Foil' : ''}'
          : '${c.name}${foil ? ' (Foil)' : ''} · #${c.number} · ${c.setCode}',
      price: double.parse(max(0.99, price).toStringAsFixed(2)),
      cardId: c.id,
      foil: foil,
      condition: cond,
      centeringLR: graded ? 48 + _rng.nextDouble() * 4 : 38 + _rng.nextDouble() * 24,
      centeringTB: graded ? 48 + _rng.nextDouble() * 4 : 38 + _rng.nextDouble() * 24,
      isFake: !graded && seller == SellerType.scammy && _rng.nextDouble() < 0.18,
      graded: graded,
      grade: graded ? grade : null,
      gradingCompany: graded ? GradingCompany.psa : null,
      sellerAlias: alias,
      rating: double.parse(ratingJitter.toStringAsFixed(1)),
      salesCount: sales,
      shipsInDays: seller.shipsInDays,
    );
  }

  List<AuctionLot> _generateAuctions() {
    final cards = List<CardDef>.from(_catalog.cards)..shuffle(_rng);
    return cards.take(6).map((c) {
      final foil = _rng.nextDouble() < 0.35;
      final base = foil ? (c.foilMarketPrice ?? c.marketPrice * 2) : c.marketPrice;
      return AuctionLot(
        id: _uuid.v4(),
        cardId: c.id,
        foil: foil,
        condition: Condition.nearMint,
        centeringLR: 45 + _rng.nextDouble() * 10,
        centeringTB: 45 + _rng.nextDouble() * 10,
        isFake: false,
        currentBid: max(0.5, base * (0.4 + _rng.nextDouble() * 0.3)),
        minIncrement: max(0.5, base * 0.05),
        endsInTurns: 1 + _rng.nextInt(3),
      );
    }).toList();
  }

  MarketEvent _randomEvent() {
    final keys = _catalog.bySet.keys.toList();
    final set = keys.isEmpty
        ? (_catalog.isPokemon ? 'MEW' : 'OGN')
        : keys[_rng.nextInt(keys.length)];
    final hot = _rng.nextBool();
    final game = _catalog.isPokemon ? 'Pokémon' : 'Riftbound';
    return MarketEvent(
      id: _uuid.v4(),
      title: hot ? '$set hype spike' : '$set cools off',
      description: hot
          ? '$game chase from $set is moving — sealed floats up.'
          : 'Supply dump on $set — street prices soften.',
      setCode: set,
      multiplier: hot ? 1.08 + _rng.nextDouble() * 0.12 : 0.88 + _rng.nextDouble() * 0.08,
      turnsLeft: 2 + _rng.nextInt(3),
    );
  }

  /// Sibling market asks for the same card/foil/condition (sell comps).
  List<double> marketAsksFor({
    required String cardId,
    required bool foil,
    required Condition condition,
    bool graded = false,
  }) {
    final prices = state.market
        .where(
          (m) =>
              m.cardId == cardId &&
              m.foil == foil &&
              m.graded == graded &&
              (graded || m.condition == condition),
        )
        .map((m) => m.price)
        .toList()
      ..sort();
    return prices;
  }

  double? suggestedAskFor(OwnedCard owned) {
    final comps = marketAsksFor(
      cardId: owned.cardId,
      foil: owned.foil,
      condition: owned.condition,
      graded: owned.graded,
    );
    if (comps.isEmpty) return null;
    final mid = comps[comps.length ~/ 2];
    return double.parse(mid.toStringAsFixed(2));
  }

  Future<void> bidAuction(String id) async {
    final lot = state.auctions.firstWhere((a) => a.id == id);
    final next = lot.currentBid + lot.minIncrement;
    if (state.player.cash < next) {
      state = state.copyWith(message: 'Not enough cash to bid.');
      return;
    }
    lot.currentBid = next;
    lot.playerIsHighBidder = true;
    state = state.copyWith(auctions: [...state.auctions], message: 'You are high bidder.');
    await _persist();
  }

  Future<void> buyUpgrade(String id) async {
    final def = upgrades.firstWhere((u) => u.id == id);
    if (state.player.ownedUpgrades.contains(id)) return;
    if (state.player.xp < def.requiredXp || state.player.cash < def.cost) {
      state = state.copyWith(message: 'Need more XP or cash.');
      return;
    }
    final player = state.player.copyWith(
      cash: state.player.cash - def.cost,
      ownedUpgrades: {...state.player.ownedUpgrades, id},
    );
    state = state.copyWith(player: player, message: 'Unlocked ${def.name}.');
    await _persist();
  }

  Future<void> advanceDay() async {
    var events = state.events
        .map((e) => e.copyWith(turnsLeft: e.turnsLeft - 1))
        .where((e) => e.turnsLeft > 0)
        .toList();
    if (_rng.nextDouble() < 0.55) events = [...events, _randomEvent()];

    // Grading: realtime jobs by readyAtMs; legacy day-tick jobs still advance.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final grading = state.grading.map((g) {
      if (!g.ready && !g.revealed) {
        if (g.readyAtMs != null) {
          if (nowMs >= g.readyAtMs!) {
            g.ready = true;
            g.turnsLeft = 0;
          }
        } else {
          g.turnsLeft -= 1;
          if (g.turnsLeft <= 0) g.ready = true;
        }
      }
      return g;
    }).toList();

    // Online listing fills — easier near-fair asks (app tempo, not grind).
    var player = state.player;
    var collection = [...state.collection];
    var online = [...state.onlineListings];
    final soldIds = <String>[];
    for (final listing in online.where((l) => l.status == OnlineListingStatus.active)) {
      final card = collection.firstWhere((c) => c.instanceId == listing.ownedInstanceId);
      final def = _catalog.byId[card.cardId];
      if (def == null) continue;
      final fair = Pricing.fairValue(def, card, events: events);
      final ratio = listing.ask / max(0.01, fair);
      var chance = ratio <= 0.95
          ? 0.92
          : ratio <= 1.05
              ? 0.68
              : ratio <= 1.15
                  ? 0.28
                  : ratio <= 1.3
                      ? 0.08
                      : 0.02;
      if (_rng.nextDouble() < chance) {
        final fee = listing.ask * Pricing.platformFeeRate(player);
        player = player.copyWith(
          cash: player.cash + listing.ask - fee,
          cardsSold: player.cardsSold + 1,
          xp: player.xp + 3,
        );
        soldIds.add(listing.id);
        collection = collection
            .where((c) => c.instanceId != listing.ownedInstanceId)
            .toList();
      }
    }
    online = online
        .map((l) {
          if (soldIds.contains(l.id)) {
            l.status = OnlineListingStatus.sold;
          }
          return l;
        })
        .where((l) => l.status == OnlineListingStatus.active)
        .toList();

    // Auctions resolve
    var auctions = [...state.auctions];
    final finished = <AuctionLot>[];
    for (final a in auctions) {
      a.endsInTurns -= 1;
      if (a.endsInTurns <= 0) finished.add(a);
      if (player.ownedUpgrades.contains('auto_snipe') &&
          a.endsInTurns == 0 &&
          !a.playerIsHighBidder) {
        final def = _catalog.byId[a.cardId];
        if (def != null) {
          final fair = (a.foil ? (def.foilMarketPrice ?? def.marketPrice * 2) : def.marketPrice);
          if (a.currentBid + a.minIncrement < fair * 0.9 &&
              player.cash >= a.currentBid + a.minIncrement) {
            a.currentBid += a.minIncrement;
            a.playerIsHighBidder = true;
          }
        }
      }
    }
    for (final a in finished) {
      if (a.playerIsHighBidder) {
        if (player.cash >= a.currentBid) {
          player = player.copyWith(cash: player.cash - a.currentBid);
          collection.add(OwnedCard(
            instanceId: _uuid.v4(),
            cardId: a.cardId,
            foil: a.foil,
            condition: a.condition,
            centeringLR: a.centeringLR,
            centeringTB: a.centeringTB,
            surface: 8.5,
            edges: 8.5,
            corners: 8.5,
            defects: const [],
          ));
        }
      }
    }
    auctions = auctions.where((a) => a.endsInTurns > 0).toList();
    if (auctions.length < 6) {
      auctions = [...auctions, ..._generateAuctions().take(6 - auctions.length)];
    }

    final sealed = _generateSealedShop(events);
    await _applySpotRefresh();
    var market = _churnSinglesMarket(state.market);
    if (_marketNeedsRegen(market)) {
      market = _generateSinglesMarket();
    }

    var next = state.copyWith(
      day: state.day + 1,
      player: player,
      collection: collection,
      onlineListings: online,
      grading: grading,
      auctions: auctions,
      events: events,
      sealedListings: sealed,
      market: market,
      message: soldIds.isEmpty
          ? 'Day ${state.day + 1} — shop restocked.'
          : 'Day ${state.day + 1} — sold ${soldIds.length} online listing(s).',
    );
    state = _sanitizeEconomy(next);
    _checkAchievements();
    _recordCollectionValue();
    await _persist();
  }

  @override
  void _checkAchievements() {
    final p = state.player;
    final next = {...p.unlockedAchievements};
    if (p.packsOpened >= 10) next.add('ripper_10');
    if (p.gemsPulled >= 1) next.add('first_gem');
    if (p.cardsSold >= 5) next.add('seller_5');
    if (state.collection.length >= 50) next.add('binder_50');
    if (next.length == p.unlockedAchievements.length &&
        next.containsAll(p.unlockedAchievements)) {
      return;
    }
    state = state.copyWith(
      player: p.copyWith(unlockedAchievements: next),
    );
  }

  double totalCollectionValue() {
    var v = 0.0;
    for (final o in state.collection) {
      v += fairFor(o);
    }
    return v;
  }

  /// Snapshot portfolio value when it changes (same calendar day updates in place).
  @override
  void _recordCollectionValue({bool force = false}) {
    final value = double.parse(totalCollectionValue().toStringAsFixed(2));
    final now = DateTime.now();
    final history = [...state.valueHistory];
    if (history.isNotEmpty) {
      final last = history.last;
      final sameDay = last.date.year == now.year &&
          last.date.month == now.month &&
          last.date.day == now.day;
      if (!force && (last.value - value).abs() < 0.005 && sameDay) return;
      if (sameDay) {
        history[history.length - 1] =
            CollectionValuePoint(date: now, value: value);
      } else {
        if (!force && (last.value - value).abs() < 0.005) {
          // Still append a daily tick so the chart advances with real days.
          history.add(CollectionValuePoint(date: now, value: value));
        } else {
          history.add(CollectionValuePoint(date: now, value: value));
        }
      }
    } else {
      history.add(CollectionValuePoint(date: now, value: value));
    }
    while (history.length > 90) {
      history.removeAt(0);
    }
    state = state.copyWith(valueHistory: history);
  }

  Future<void> createBinder({
    String? name,
    int colorHex = 0xFF5B8CFF,
    bool isPrivate = false,
  }) async {
    final n = (name ?? '').trim();
    final label = n.isEmpty ? 'Binder ${state.binders.length + 1}' : n;
    final binder = Binder(
      id: _uuid.v4(),
      name: label,
      colorHex: colorHex,
      isPrivate: isPrivate,
    );
    state = state.copyWith(
      binders: [...state.binders, binder],
      message: 'Created $label.',
    );
    await _persist();
  }

  Future<void> renameBinder(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      binders: state.binders
          .map((b) => b.id == id ? b.copyWith(name: trimmed) : b)
          .toList(),
    );
    await _persist();
  }

  Future<void> deleteBinder(String id) async {
    state = state.copyWith(
      binders: state.binders.where((b) => b.id != id).toList(),
      message: 'Binder removed.',
    );
    await _persist();
  }

  @override
  double fairFor(OwnedCard card) {
    final def = _catalog.byId[card.cardId];
    if (def == null) return 0;
    return Pricing.fairValue(def, card, events: state.events);
  }

  @override
  SealedProduct? sealedById(String id) {
    try {
      return _catalog.sealed.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  CardDef? cardById(String id) => _catalog.byId[id];
}
