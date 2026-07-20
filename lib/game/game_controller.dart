import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../data/engagement_defs.dart';
import '../data/featured_packs.dart';
import '../data/pricing.dart';
import '../data/onboarding.dart';
import '../data/price_history.dart';
import '../data/riftbound_catalog.dart';
import '../data/rival_personas.dart';
import '../data/tcgcsv_price_refresh.dart';
import '../models/enums.dart';
import '../models/models.dart';
import 'featured_pack_opener.dart';
import 'pack_opener.dart';

part 'rip_session.dart';
part 'shop_actions.dart';
part 'grading_actions.dart';
part 'engagement_actions.dart';

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
  'SleeveSniper',
  'HoloHarbor',
  'MintCornerCo',
  'BinderBunny',
  'ChaseCatcher',
  'FoilFoxCards',
  'SlabStacker',
  'PullRatePete',
  'CaseCrackChris',
  'NMOnlyNick',
  'BudgetBinder',
  'AltArtAnnie',
  'GradeGate',
  'ShipFastSam',
  'CompsChecker',
  'VaultFlipVince',
  // Expanded seller pool — denser market personalities
  'ManaMarketMaya',
  'MythicMintMike',
  'PlanarPortDeals',
  'CounterspellCarl',
  'TapLandTrades',
  'EDHEmpire',
  'FoilFetchFran',
  'ReservedListRex',
  'DraftNightDan',
  'CommanderCove',
  'ScryStackSarah',
  'BoltBudgetBob',
  'IslandIsle',
  'ShockLandSue',
  'ProxyPolicePat', // will still be legitimate seller alias
  'ModernMaven',
  'PioneerPete',
  'StandardSteve',
  'LegacyLarry',
  'CubeCrate',
  'PrereleasePam',
  'CollectorCrypt',
  'GradedGrailGuy',
  'RawRipRita',
  'PsaPrepPaul',
  'NightOwlNexus',
  'WeekendWhale',
  'MicroMintMart',
  'MidRangeMike',
  'SpikeSeller',
  'JohnnyJank',
  'TimmyTrades',
  'VorthosVault',
  'MelvinMath',
  'QuickShipQuinn',
  'SlowboatSam',
  'TrustMeTCG',
  'VerifiedVince',
  'LocalLGS_Lisa',
  'MailDayMax',
  'BubbleMailerBen',
  'ToploaderTom',
  'PennySleevePat',
  'OneTouchOwen',
  'MagneticMike',
  'KmcKay',
  'DragonShieldDee',
  'UltimateGuardU',
  'CardKingdomCarl',
  'TcgPlayerTess',
  'EbayEddie',
  'MercariMia',
  'WhatnotWes',
  'TikTokTrades',
  'DiscordDealsDan',
  'RedditRipper',
  'FBGroupGabe',
  'ConBoothBarb',
  'TableTopTina',
  'SideEventSam',
  'JudgeCallJess',
  'RulesLawyerRon',
  'StackMaster',
  'PriorityPete',
  'PassPriorityPam',
  'UntapUpkeep',
  'DrawGoDoug',
  'AgroAlice',
  'ControlCraig',
  'ComboChris',
  'MidrangeMona',
  'RampRalph',
  'TempoTess',
  'ValueVince',
  'GrindstoneGus',
  'TutorTom',
  'FetchlandFaye',
  'ShocklandSal',
  'DualLandDee',
  'TriomeTara',
  'PathwayPete',
  'FastlandFran',
  'SlowlandSam',
  'ChecklandCal',
  'FilterlandFay',
  'UtilityUlysses',
  'ManabaseMax',
];

enum _MarketTier { hot, mid, budget }

enum _OfferDecision { accept, counter, reject }

const upgrades = [
  UpgradeDef(
    id: 'fee_cut',
    name: 'Fee Negotiator',
    description: 'Online listing fees drop to 10%.',
    cost: 250,
    requiredXp: 40,
  ),
  UpgradeDef(
    id: 'quick_flip_pro',
    name: 'Quick Flip Pro',
    description: 'Quick Flip pays 78% of fair instead of 70%.',
    cost: 350,
    requiredXp: 60,
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
    this.marketOffers = const [],
    this.lastPlayedAtMs,
    this.engagement = const EngagementState(),
  });

  final bool ready;
  final bool catalogLoaded;
  /// Active TCG franchise for this save slot (`riftbound` | `pokemon` | `mtg`).
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
  final List<MarketOffer> marketOffers;
  /// Wall-clock ms of last session tick (listing catch-up).
  final int? lastPlayedAtMs;
  final EngagementState engagement;

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
        marketOffers: const [],
        lastPlayedAtMs: null,
        engagement: const EngagementState(),
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
    List<MarketOffer>? marketOffers,
    int? lastPlayedAtMs,
    EngagementState? engagement,
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
      marketOffers: marketOffers ?? this.marketOffers,
      lastPlayedAtMs: lastPlayedAtMs ?? this.lastPlayedAtMs,
      engagement: engagement ?? this.engagement,
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
        'marketOffers': marketOffers.map((e) => e.toJson()).toList(),
        'lastPlayedAtMs': lastPlayedAtMs,
        'engagement': engagement.toJson(),
      };

  factory GameState.fromJson(Map<String, dynamic> j) {
    final v = j['v'] as int? ?? 1;
    if (v < 2) {
      // Wipe incompatible parody saves.
      return GameState(
        ready: true,
        catalogLoaded: true,
        franchiseId: 'riftbound',
        player: const PlayerStats(cash: 350, candy: 25000),
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
        marketOffers: const [],
        lastPlayedAtMs: null,
        engagement: const EngagementState(),
      );
    }
    final fid = GameCatalog.normalizeId(
      (j['franchiseId'] as String?) ?? 'riftbound',
    );
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
      marketOffers: (j['marketOffers'] as List? ?? [])
          .map((e) => MarketOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastPlayedAtMs: j['lastPlayedAtMs'] as int?,
      engagement: EngagementState.fromJson(
        j['engagement'] as Map<String, dynamic>?,
      ),
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

  /// Engagement hooks (overridden by [_EngagementActions]).
  void _onEngagementPackOpened() {}
  void _onEngagementCardListed() {}
  void _onEngagementGradeSent() {}
  void _onEngagementGradeRevealed() {}
  void _recordPullHistory(List<OwnedCard> pulls, {String? packLabel}) {}
  EngagementState _afterFeaturedRipHook({
    required String packId,
    required bool hitChase,
  }) =>
      state.engagement;
  Future<void> checkSetMilestones() async {}
}

class GameNotifier extends _GameNotifierBase
    with _RipSession, _ShopActions, _GradingActions, _EngagementActions {
  RiftboundCatalog get catalog => _catalog;

  String get activeGameId => _catalog.gameId;

  /// Switch franchise (Riftbound ↔ Pokémon). Each franchise keeps its own
  /// market / sealed / collection slot; wallet (cash/candy/xp) stays shared.
  Future<void> switchFranchise(String gameId) async {
    final id = GameCatalog.normalizeId(gameId);
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
          message: switch (id) {
            'pokemon' =>
              'Switched to Pokémon — your Pokémon market restored.',
            'mtg' => 'Switched to Magic — your Magic market restored.',
            _ => 'Switched to Riftbound — your Riftbound market restored.',
          },
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
      message: switch (id) {
        'pokemon' => 'Switched to Pokémon — sealed & singles stocked.',
        'mtg' => 'Switched to Magic — sealed & singles stocked.',
        _ => 'Switched to Riftbound — sealed & singles stocked.',
      },
      migrationNotice: null,
      valueHistory: [
        CollectionValuePoint(date: DateTime.now(), value: 0),
      ],
      binders: const [],
      recentlyKeptIds: const {},
      marketOffers: const [],
      lastPlayedAtMs: DateTime.now().millisecondsSinceEpoch,
      engagement: const EngagementState(),
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
        await catchUpOnlineSales();
        await catchUpGrading();
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
      player: sharedWallet ?? const PlayerStats(cash: 350, candy: 25000),
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
      message: switch (gameId) {
        'pokemon' => 'Welcome to Bindora — Pokémon sealed & singles.',
        'mtg' => 'Welcome to Bindora — Magic sealed & singles.',
        _ => 'Welcome to Bindora — Riftbound sealed & singles.',
      },
      migrationNotice: null,
      valueHistory: [
        CollectionValuePoint(date: DateTime.now(), value: 0),
      ],
      binders: const [],
      recentlyKeptIds: const {},
      marketOffers: const [],
      lastPlayedAtMs: DateTime.now().millisecondsSinceEpoch,
      engagement: const EngagementState(),
    );
    state = fresh;
    await catchUpOnlineSales();
    await catchUpGrading();
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
    final id = GameCatalog.normalizeId(state.franchiseId);
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

    // Hot chase: top ~20 by spot, 3–7 competing asks.
    final hot = rawWeighted.take(min(20, rawWeighted.length)).toList();
    for (final c in hot) {
      final n = 3 + _rng.nextInt(5); // 3–7
      final usedConds = <Condition>{};
      final usedPairs = <String>{};
      for (var i = 0; i < n; i++) {
        final listing = _makeMarketListing(
          c,
          graded: false,
          preferUnusedCondition: usedConds,
          usedSellerPairs: usedPairs,
          tier: _MarketTier.hot,
        );
        usedConds.add(listing.condition);
        usedPairs.add('${listing.sellerType.name}|${listing.sellerAlias}');
        out.add(listing);
      }
    }

    // Mid: next ~40 with 2–3 asks.
    final mid = rawWeighted.skip(hot.length).take(40).toList();
    for (final c in mid) {
      final n = 2 + (_rng.nextDouble() < 0.4 ? 1 : 0); // 2–3
      final usedPairs = <String>{};
      for (var i = 0; i < n; i++) {
        final listing = _makeMarketListing(
          c,
          graded: false,
          usedSellerPairs: usedPairs,
          tier: _MarketTier.mid,
        );
        usedPairs.add('${listing.sellerType.name}|${listing.sellerAlias}');
        out.add(listing);
      }
    }

    // Warm: next ~30 with 1–2 asks.
    final warm = rawWeighted.skip(hot.length + mid.length).take(30).toList();
    for (final c in warm) {
      final n = 1 + (_rng.nextDouble() < 0.45 ? 1 : 0);
      final usedPairs = <String>{};
      for (var i = 0; i < n; i++) {
        final listing = _makeMarketListing(
          c,
          graded: false,
          usedSellerPairs: usedPairs,
          tier: _MarketTier.mid,
        );
        usedPairs.add('${listing.sellerType.name}|${listing.sellerAlias}');
        out.add(listing);
      }
    }

    // Budget long-tail: sample ~40 lower-priced real cards.
    final budgetPool = rawWeighted.where((c) => c.marketPrice < 8).toList()
      ..shuffle(_rng);
    final seen = out.map((m) => m.cardId).toSet();
    for (final c in budgetPool.take(40)) {
      if (seen.contains(c.id) && _rng.nextDouble() < 0.6) continue;
      out.add(_makeMarketListing(c, graded: false, tier: _MarketTier.budget));
      seen.add(c.id);
    }

    // PSA slabs: priced chase only.
    final slabPool = pool.where(isSlabEligibleCard).toList()
      ..sort((a, b) => b.marketPrice.compareTo(a.marketPrice));
    final slabHot = slabPool.take(min(12, slabPool.length)).toList();
    for (final c in slabHot) {
      final n = 3 + _rng.nextInt(3); // 3–5
      final usedPairs = <String>{};
      for (var i = 0; i < n; i++) {
        final listing = _makeMarketListing(
          c,
          graded: true,
          usedSellerPairs: usedPairs,
          tier: _MarketTier.hot,
        );
        usedPairs.add('${listing.sellerType.name}|${listing.sellerAlias}');
        out.add(listing);
      }
    }
    for (final c in slabPool.skip(slabHot.length).take(12)) {
      final n = 1 + (_rng.nextDouble() < 0.5 ? 1 : 0); // 1–2
      final usedPairs = <String>{};
      for (var i = 0; i < n; i++) {
        final listing = _makeMarketListing(
          c,
          graded: true,
          usedSellerPairs: usedPairs,
          tier: _MarketTier.hot,
        );
        usedPairs.add('${listing.sellerType.name}|${listing.sellerAlias}');
        out.add(listing);
      }
    }

    out.shuffle(_rng);
    return out.take(min(180, out.length)).toList();
  }

  /// Keep bargains; replace ~35%+ so the shop feels alive. Cap 180.
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
      // Hotter turnover so the shop feels alive between days.
      final keepChance = bargain ? 0.62 : 0.32;
      if (_rng.nextDouble() < keepChance) {
        keep.add(m);
      } else {
        drop.add(m);
      }
    }
    final fresh = _generateSinglesMarket();
    final replaceN = max(drop.length, (valid.length * 0.45).round());
    final next = [...keep, ...fresh.take(replaceN)];
    next.shuffle(_rng);
    return next.take(min(180, next.length)).toList();
  }

  /// Soft market restock without advancing the day clock.
  Future<void> refreshMarketListings() async {
    if (!state.ready) return;
    final before = state.market.length;
    final next = _churnSinglesMarket(state.market);
    final sealed = _generateSealedShop(state.events);
    state = state.copyWith(
      market: next,
      sealedListings: sealed,
      message:
          'Market refreshed — ${next.length} live listings (was $before).',
    );
    await _persist();
  }

  MarketListing _makeMarketListing(
    CardDef c, {
    required bool graded,
    Set<Condition>? preferUnusedCondition,
    Set<String>? usedSellerPairs,
    _MarketTier tier = _MarketTier.mid,
  }) {
    final seller = _pickSellerType(tier: tier, graded: graded);
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

    // Slightly soft asks — deals exist, not 20%+ steals every day.
    if (seller == SellerType.clueless) price *= 0.88 + _rng.nextDouble() * 0.08;
    if (seller == SellerType.scammy) price *= 0.92 + _rng.nextDouble() * 0.08;
    if (seller == SellerType.serious) price *= 0.98 + _rng.nextDouble() * 0.07;
    if (seller == SellerType.goblin) price *= 0.94 + _rng.nextDouble() * 0.10;
    price *= 0.98 + _rng.nextDouble() * 0.05;

    final alias = _pickSellerAlias(seller, usedSellerPairs);
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

  SellerType _pickSellerType({
    required _MarketTier tier,
    required bool graded,
  }) {
    final r = _rng.nextDouble();
    if (graded || tier == _MarketTier.hot) {
      if (r < 0.45) return SellerType.serious;
      if (r < 0.70) return SellerType.goblin;
      if (r < 0.88) return SellerType.clueless;
      return SellerType.scammy;
    }
    if (tier == _MarketTier.budget) {
      if (r < 0.45) return SellerType.clueless;
      if (r < 0.70) return SellerType.goblin;
      if (r < 0.88) return SellerType.serious;
      return SellerType.scammy;
    }
    return SellerType.values[_rng.nextInt(SellerType.values.length)];
  }

  String _pickSellerAlias(SellerType seller, Set<String>? usedPairs) {
    if (usedPairs == null || usedPairs.isEmpty) {
      return _sellerNames[_rng.nextInt(_sellerNames.length)];
    }
    final shuffled = [..._sellerNames]..shuffle(_rng);
    for (final alias in shuffled) {
      final key = '${seller.name}|$alias';
      if (!usedPairs.contains(key)) return alias;
    }
    // Exhausted unique pairs — pick any alias (still try a fresh name).
    return _sellerNames[_rng.nextInt(_sellerNames.length)];
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
        rivalName: rivalByIndex(_rng.nextInt(9999)).handle,
      );
    }).toList();
  }

  MarketEvent _randomEvent() {
    final keys = _catalog.bySet.keys.toList();
    final set = keys.isEmpty
        ? (_catalog.isPokemon
            ? 'MEW'
            : _catalog.isMtg
                ? 'FDN'
                : 'OGN')
        : keys[_rng.nextInt(keys.length)];
    final hot = _rng.nextBool();
    final game = _catalog.isPokemon
        ? 'Pokémon'
        : _catalog.isMtg
            ? 'Magic'
            : 'Riftbound';
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
    // Rival pressure — sometimes counters immediately (Phase 7).
    String? msg = 'You are high bidder.';
    if (_rng.nextDouble() < 0.42) {
      final rival = rivalByIndex(_rng.nextInt(9999)).handle;
      lot.rivalName = rival;
      final rivalBid = next + lot.minIncrement;
      lot.currentBid = rivalBid;
      lot.playerIsHighBidder = false;
      msg = '$rival outbid you to \$${rivalBid.toStringAsFixed(2)}.';
    } else {
      lot.rivalName ??= rivalByIndex(lot.id.hashCode).handle;
    }
    state = state.copyWith(auctions: [...state.auctions], message: msg);
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

  /// Seller response when a pending offer is evaluated on Advance Day.
  _OfferDecision _sellerOfferDecision(SellerType seller, double offerOverAsk) {
    switch (seller) {
      case SellerType.clueless:
        if (offerOverAsk >= 0.86) return _OfferDecision.accept;
        if (_rng.nextDouble() < 0.40) return _OfferDecision.counter;
        return _OfferDecision.reject;
      case SellerType.serious:
        if (offerOverAsk >= 0.95) return _OfferDecision.accept;
        // Serious counters once (at ~98% ask) then rejects lowballs.
        if (offerOverAsk >= 0.88) return _OfferDecision.counter;
        return _OfferDecision.reject;
      case SellerType.goblin:
        if (offerOverAsk >= 0.90) return _OfferDecision.accept;
        if (_rng.nextDouble() < 0.55) return _OfferDecision.counter;
        return _OfferDecision.reject;
      case SellerType.scammy:
        if (offerOverAsk >= 0.88) return _OfferDecision.accept;
        return _OfferDecision.reject;
    }
  }

  /// Shared online-listing fill used by Advance Day and wall-clock catch-up.
  ({
    PlayerStats player,
    List<OwnedCard> collection,
    List<OnlineListing> online,
    int soldCount,
  }) _tryFillOnlineListings({
    required PlayerStats player,
    required List<OwnedCard> collection,
    required List<OnlineListing> online,
    required List<MarketEvent> events,
    double chanceMult = 1.0,
  }) {
    var p = player;
    var coll = [...collection];
    var listings = [...online];
    final soldIds = <String>[];
    for (final listing
        in listings.where((l) => l.status == OnlineListingStatus.active)) {
      OwnedCard? card;
      for (final c in coll) {
        if (c.instanceId == listing.ownedInstanceId) {
          card = c;
          break;
        }
      }
      if (card == null) continue;
      final def = _catalog.byId[card.cardId];
      if (def == null) continue;
      final fair = Pricing.fairValue(def, card, events: events);
      // NPC buyers: fairBias shifts what they'll pay relative to ask.
      final buyer = npcForIndex(listing.id.hashCode + listing.listedDay);
      final willing = fair * buyer.fairBias;
      final ratio = listing.ask / max(0.01, willing);
      var chance = ratio <= 0.95
          ? 0.62
          : ratio <= 1.05
              ? 0.48
              : ratio <= 1.15
                  ? 0.22
                  : ratio <= 1.3
                      ? 0.08
                      : 0.02;
      chance = (chance * chanceMult * (0.85 + buyer.fairBias * 0.15))
          .clamp(0.0, 1.0);
      if (_rng.nextDouble() < chance) {
        final fee = listing.ask * Pricing.platformFeeRate(p);
        p = p.copyWith(
          cash: p.cash + listing.ask - fee,
          cardsSold: p.cardsSold + 1,
          xp: p.xp + 3,
        );
        soldIds.add(listing.id);
        coll = coll
            .where((c) => c.instanceId != listing.ownedInstanceId)
            .toList();
      }
    }
    listings = listings
        .map((l) {
          if (soldIds.contains(l.id)) {
            l.status = OnlineListingStatus.sold;
          }
          return l;
        })
        .where((l) => l.status == OnlineListingStatus.active)
        .toList();
    return (
      player: p,
      collection: coll,
      online: listings,
      soldCount: soldIds.length,
    );
  }

  static const _catchUpWindowMs = 20 * 60 * 60 * 1000; // 20 hours
  static const _catchUpMaxChecks = 3;
  static const _catchUpChanceMult = 0.85;

  /// Resolve missed listing sale rolls from real elapsed time (no background).
  Future<int> catchUpOnlineSales({int? nowMs}) async {
    if (!state.ready) return 0;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final last = state.lastPlayedAtMs;
    if (last == null) {
      state = state.copyWith(lastPlayedAtMs: now);
      await _persist();
      return 0;
    }
    final elapsed = now - last;
    final checks =
        max(0, min(_catchUpMaxChecks, elapsed ~/ _catchUpWindowMs));
    if (checks <= 0) {
      state = state.copyWith(lastPlayedAtMs: now);
      await _persist();
      return 0;
    }

    var player = state.player;
    var collection = [...state.collection];
    var online = [...state.onlineListings];
    var soldTotal = 0;
    for (var i = 0; i < checks; i++) {
      if (online.isEmpty) break;
      final fill = _tryFillOnlineListings(
        player: player,
        collection: collection,
        online: online,
        events: state.events,
        chanceMult: _catchUpChanceMult,
      );
      player = fill.player;
      collection = fill.collection;
      online = fill.online;
      soldTotal += fill.soldCount;
    }

    state = state.copyWith(
      player: player,
      collection: collection,
      onlineListings: online,
      lastPlayedAtMs: now,
      message: soldTotal > 0
          ? 'While you were away: $soldTotal listing(s) sold.'
          : state.message,
      engagement: soldTotal > 0
          ? state.engagement.copyWith(
              pendingResumeMessage:
                  'While away: $soldTotal listing(s) sold.',
            )
          : state.engagement,
    );
    if (soldTotal > 0) {
      _recordCollectionValue();
      _checkAchievements();
    }
    await _persist();
    return soldTotal;
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

    // Online listing fills — fair asks sell, bargains not auto-instant.
    final fill = _tryFillOnlineListings(
      player: state.player,
      collection: state.collection,
      online: state.onlineListings,
      events: events,
    );
    var player = fill.player;
    var collection = fill.collection;
    var online = fill.online;
    final soldCount = fill.soldCount;
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

    // Resolve pending market offers before listings churn.
    var market = [...state.market];
    var offers = [...state.marketOffers];
    var offerUpdates = 0;
    final acceptedListingIds = <String>{};
    final nextDay = state.day + 1;

    for (final o in offers) {
      if (o.status != MarketOfferStatus.pending) continue;

      if (nextDay > o.expiresOnDay) {
        o.status = MarketOfferStatus.expired;
        player = player.copyWith(cash: player.cash + o.offerAmount);
        offerUpdates++;
        continue;
      }

      final listingIdx = market.indexWhere((m) => m.id == o.listingId);
      if (listingIdx < 0) {
        o.status = MarketOfferStatus.cancelled;
        player = player.copyWith(cash: player.cash + o.offerAmount);
        offerUpdates++;
        continue;
      }
      final listing = market[listingIdx];
      final npc = o.npcId != null ? npcById(o.npcId!) : npcForIndex(o.id.hashCode);
      // fairBias softens/hardens how "fair" the offer looks to the NPC.
      final ratio =
          (o.offerAmount / max(0.01, listing.price)) / max(0.5, npc.fairBias);
      final decision = _sellerOfferDecision(listing.sellerType, ratio);

      if (decision == _OfferDecision.accept) {
        o.status = MarketOfferStatus.accepted;
        o.flavor = '${npc.name} accepted — ${npc.quirk}';
        collection.add(_ownedFromMarketListing(listing));
        acceptedListingIds.add(listing.id);
        offerUpdates++;
      } else if (decision == _OfferDecision.counter) {
        final counterMult = switch (listing.sellerType) {
          SellerType.clueless => 0.92,
          SellerType.serious => 0.98,
          SellerType.goblin => 0.94,
          SellerType.scammy => 0.95,
        };
        // Cheapskate NPCs push counters higher; generous ones meet closer.
        final biasMult = (1.04 - (npc.fairBias - 1.0) * 0.08).clamp(0.90, 1.08);
        o.counterAmount = double.parse(
          max(o.offerAmount + 0.01, listing.price * counterMult * biasMult)
              .toStringAsFixed(2),
        );
        // Soft-counter never above ask.
        if (o.counterAmount! >= listing.price) {
          o.counterAmount =
              double.parse((listing.price - 0.01).toStringAsFixed(2));
        }
        if (o.counterAmount! <= o.offerAmount) {
          o.status = MarketOfferStatus.rejected;
          o.flavor = '${npc.name} walked — ${npc.quirk}';
          player = player.copyWith(cash: player.cash + o.offerAmount);
        } else {
          o.status = MarketOfferStatus.countered;
          o.flavor =
              '${npc.name} countered at \$${o.counterAmount!.toStringAsFixed(2)} — ${npc.quirk}';
        }
        offerUpdates++;
      } else {
        o.status = MarketOfferStatus.rejected;
        o.flavor = '${npc.name} rejected — ${npc.quirk}';
        player = player.copyWith(cash: player.cash + o.offerAmount);
        offerUpdates++;
      }
    }

    if (acceptedListingIds.isNotEmpty) {
      market = market.where((m) => !acceptedListingIds.contains(m.id)).toList();
    }

    market = _churnSinglesMarket(market);
    if (_marketNeedsRegen(market)) {
      market = _generateSinglesMarket();
    }

    // Refund open offers whose listing vanished in churn.
    final liveIds = market.map((m) => m.id).toSet();
    for (final o in offers) {
      if (!o.isOpen) continue;
      if (!liveIds.contains(o.listingId)) {
        o.status = MarketOfferStatus.cancelled;
        player = player.copyWith(cash: player.cash + o.offerAmount);
        offerUpdates++;
      }
    }

    final msgParts = <String>[];
    if (soldCount > 0) {
      msgParts.add('sold $soldCount online listing(s)');
    }
    if (offerUpdates > 0) {
      msgParts.add('$offerUpdates offer(s) updated');
    }
    final dayMsg = msgParts.isEmpty
        ? 'Day $nextDay — shop restocked.'
        : 'Day $nextDay — ${msgParts.join('; ')}.';

    var next = state.copyWith(
      day: nextDay,
      player: player,
      collection: collection,
      onlineListings: online,
      grading: grading,
      auctions: auctions,
      events: events,
      sealedListings: sealed,
      market: market,
      marketOffers: offers,
      lastPlayedAtMs: nowMs,
      message: dayMsg,
      engagement: state.engagement.copyWith(
        lastRivalBoardSize:
            rivalBoardSizeForLevel(player.businessLevel),
        rivalMoodSeed: state.day * 17 + nextDay,
      ),
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
    if (p.packsOpened >= 50) next.add('ripper_50');
    if (p.gemsPulled >= 1) next.add('first_gem');
    if (p.cardsSold >= 5) next.add('seller_5');
    if (p.cardsSold >= 25) next.add('seller_25');
    if (state.collection.length >= 50) next.add('binder_50');
    if (state.collection.length >= 150) next.add('binder_150');
    if (state.engagement.gradedRevealedCount >= 1) next.add('grader_1');
    if (state.engagement.dailyStreak >= 3) next.add('streak_3');
    for (final key in state.engagement.setMilestonesClaimed) {
      if (key.endsWith(':100')) {
        next.add('set_complete');
        break;
      }
    }
    if (next.length == p.unlockedAchievements.length &&
        next.containsAll(p.unlockedAchievements)) {
      return;
    }
    final newly = next.difference(p.unlockedAchievements).toList();
    final level = businessLevelFromXp(p.xp);
    state = state.copyWith(
      player: p.copyWith(
        unlockedAchievements: next,
        businessLevel: level,
      ),
      engagement: state.engagement.copyWith(
        pendingAchievementIds: [
          ...newly,
          ...state.engagement.pendingAchievementIds,
        ],
        binderPagesUnlocked: max(
          state.engagement.binderPagesUnlocked,
          binderPagesForLevel(level),
        ),
      ),
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
