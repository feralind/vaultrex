import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../data/featured_packs.dart';
import '../data/pricing.dart';
import '../data/riftbound_catalog.dart';
import '../models/enums.dart';
import '../models/models.dart';
import 'featured_pack_opener.dart';
import 'pack_opener.dart';

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
    this.valueHistory = const [],
    this.binders = const [],
  });

  final bool ready;
  final bool catalogLoaded;
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

  factory GameState.loading() => GameState(
        ready: false,
        catalogLoaded: false,
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
      );

  GameState copyWith({
    bool? ready,
    bool? catalogLoaded,
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
  }) {
    return GameState(
      ready: ready ?? this.ready,
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'v': 2,
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
      );
    }
    return GameState(
      ready: true,
      catalogLoaded: true,
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
      lastRip: null,
      lastRipPaid: null,
      message: null,
      migrationNotice: null,
      valueHistory: (j['valueHistory'] as List? ?? [])
          .map((e) => CollectionValuePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      binders: (j['binders'] as List? ?? [])
          .map((e) => Binder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  final _uuid = const Uuid();
  final _rng = Random();
  late RiftboundCatalog _catalog;
  late RiftboundPackOpener _opener;
  late FeaturedPackOpener _featuredOpener;
  late AppDatabase _db;

  RiftboundCatalog get catalog => _catalog;

  @override
  GameState build() {
    _db = ref.read(databaseProvider);
    Future.microtask(_bootstrap);
    return GameState.loading();
  }

  Future<void> _bootstrap() async {
    _catalog = await RiftboundCatalog.load();
    _opener = RiftboundPackOpener(_catalog);
    _featuredOpener = FeaturedPackOpener(_catalog);
    final raw = await _db.loadPayload();
    if (raw != null) {
      try {
        var loaded = GameState.fromJson(raw);
        // Refresh Instapacks inventory from latest sealed catalog (prices/art).
        loaded = loaded.copyWith(
          sealedListings: _generateSealedShop(loaded.events),
        );
        // Upgrade thin / invalid markets (e.g. sealed kits slabbed as PSA).
        if (loaded.market.isEmpty ||
            !loaded.market.any((m) => m.graded) ||
            _marketNeedsRegen(loaded.market)) {
          loaded = loaded.copyWith(market: _generateSinglesMarket());
        }
        state = loaded.copyWith(ready: true, catalogLoaded: true);
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
      player: PlayerStats(cash: 500),
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
      message: 'Welcome to Vaultrex — Riftbound sealed & singles.',
      migrationNotice: null,
      valueHistory: [
        CollectionValuePoint(date: DateTime.now(), value: 0),
      ],
      binders: const [],
    );
    state = fresh;
    await _persist();
  }

  Future<void> _persist() async {
    await _db.savePayload(state.toJson());
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
      if (p.marketPrice <= 0) continue;
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

  /// True when saved market still references missing / sealed / non-slab IDs.
  bool _marketNeedsRegen(List<MarketListing> market) {
    for (final m in market) {
      final def = _catalog.byId[m.cardId];
      if (def == null) return true;
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
    return false;
  }

  List<MarketListing> _generateSinglesMarket() {
    // Raw listings: real catalog singles only (sealed kits never enter CardDef).
    final pool = _catalog.cards
        .where(
          (c) =>
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
    const rawCount = 40;
    const slabCount = 16;

    // Bias raw toward mid/high value so the shop feels like a real singles market.
    final rawWeighted = [...pool]
      ..sort((a, b) => b.marketPrice.compareTo(a.marketPrice));
    final rawFocus = [
      ...rawWeighted.take(min(80, rawWeighted.length)),
      ...pool.take(min(40, pool.length)),
    ]..shuffle(_rng);
    for (var i = 0; i < rawCount; i++) {
      out.add(_makeMarketListing(rawFocus[i % rawFocus.length], graded: false));
    }

    // PSA slabs: chase singles only (epics / showcases / signatures / $$$ rares).
    final slabPool = _catalog.cards.where(isSlabEligibleCard).toList()
      ..sort((a, b) => b.marketPrice.compareTo(a.marketPrice));
    if (slabPool.isEmpty) {
      out.shuffle(_rng);
      return out;
    }
    final slabPick = slabPool.take(min(64, slabPool.length)).toList()
      ..shuffle(_rng);
    for (var i = 0; i < slabCount && i < slabPick.length; i++) {
      out.add(_makeMarketListing(slabPick[i], graded: true));
    }

    out.shuffle(_rng);
    return out;
  }

  MarketListing _makeMarketListing(CardDef c, {required bool graded}) {
    final seller = SellerType.values[_rng.nextInt(SellerType.values.length)];
    final foil = _rng.nextDouble() < 0.35 && c.foilMarketPrice != null;
    final cond = graded
        ? Condition.nearMint
        : Condition.values[1 + _rng.nextInt(4)]; // HP..NM
    final base =
        (foil ? (c.foilMarketPrice ?? c.marketPrice * 2) : c.marketPrice) *
            cond.valueMult;

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
      price = base * gradeMult * 1.2; // PSA premium
    }

    if (seller == SellerType.clueless) price *= 0.55 + _rng.nextDouble() * 0.25;
    if (seller == SellerType.scammy) price *= 0.7 + _rng.nextDouble() * 0.2;
    if (seller == SellerType.serious) price *= 0.95 + _rng.nextDouble() * 0.2;
    if (seller == SellerType.goblin) price *= 0.8 + _rng.nextDouble() * 0.4;

    final alias = _sellerNames[_rng.nextInt(_sellerNames.length)];
    final gradeLabel = graded
        ? 'PSA ${grade >= 10 ? '10' : grade.toStringAsFixed(grade % 1 == 0 ? 0 : 1)}'
        : null;

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
    const sets = ['OGN', 'SFD', 'UNL', 'OGS'];
    final set = sets[_rng.nextInt(sets.length)];
    final hot = _rng.nextBool();
    return MarketEvent(
      id: _uuid.v4(),
      title: hot ? '$set hype spike' : '$set cools off',
      description: hot
          ? 'Chase cards from $set are moving — sealed floats up.'
          : 'Supply dump on $set — street prices soften.',
      setCode: set,
      multiplier: hot ? 1.08 + _rng.nextDouble() * 0.12 : 0.88 + _rng.nextDouble() * 0.08,
      turnsLeft: 2 + _rng.nextInt(3),
    );
  }

  Future<void> buySealed(
    String listingId, {
    int qty = 1,
    PaymentMethod payWith = PaymentMethod.cash,
  }) async {
    final listing = state.sealedListings.firstWhere((l) => l.id == listingId);
    final product =
        _catalog.sealed.firstWhere((s) => s.id == listing.sealedProductId);
    final total = listing.price * qty;
    final candyCost = (total * 100).round();
    final player = state.player;

    if (payWith == PaymentMethod.cash) {
      if (player.cash < total) {
        state = state.copyWith(message: 'Not enough cash.');
        return;
      }
      player.cash -= total;
    } else {
      if (player.candy < candyCost) {
        state = state.copyWith(message: 'Not enough Candy.');
        return;
      }
      player.candy -= candyCost;
    }

    if (listing.stock < qty) {
      state = state.copyWith(message: 'Not enough stock.');
      return;
    }
    final packs = <UnopenedPack>[];
    for (var i = 0; i < qty; i++) {
      if (product.kind == SealedKind.box) {
        for (var p = 0; p < (product.packsPerBox ?? 24); p++) {
          packs.add(UnopenedPack(
            id: _uuid.v4(),
            sealedProductId: product.id,
            setCode: product.setCode,
          ));
        }
      } else {
        packs.add(UnopenedPack(
          id: _uuid.v4(),
          sealedProductId: product.id,
          setCode: product.setCode,
        ));
      }
    }
    listing.stock -= qty;
    state = state.copyWith(
      player: player,
      unopened: [...state.unopened, ...packs],
      sealedListings: [...state.sealedListings],
      message: product.kind == SealedKind.box
          ? 'Bought box — ${(product.packsPerBox ?? 24) * qty} packs queued.'
          : 'Bought $qty pack(s).',
      lastRipPaid: total,
    );
    await _persist();
  }

  /// Buy a Featured Pack and open immediately into [lastRip].
  /// Returns true on success so UI can launch [showPackTheater] with
  /// `alreadyOpened: true`.
  Future<bool> buyFeaturedPack(
    String featuredPackId, {
    PaymentMethod payWith = PaymentMethod.cash,
  }) async {
    final pack = featuredPackById(featuredPackId);
    if (pack == null) {
      state = state.copyWith(message: 'Featured pack not found.');
      return false;
    }
    final total = pack.priceUsd;
    final candyCost = pack.candyPrice;
    final player = state.player;

    if (payWith == PaymentMethod.cash) {
      if (player.cash < total) {
        state = state.copyWith(message: 'Not enough cash.');
        return false;
      }
      player.cash -= total;
    } else {
      if (player.candy < candyCost) {
        state = state.copyWith(message: 'Not enough Candy.');
        return false;
      }
      player.candy -= candyCost;
    }

    final pulls = _featuredOpener.open(pack);
    if (pulls.isEmpty) {
      // Refund on empty open (should not happen with a loaded catalog).
      if (payWith == PaymentMethod.cash) {
        player.cash += total;
      } else {
        player.candy += candyCost;
      }
      state = state.copyWith(
        player: player,
        message: 'Could not open featured pack — catalog empty.',
      );
      return false;
    }

    player.packsOpened += 1;
    player.xp += 3;
    state = state.copyWith(
      player: player,
      lastRip: pulls,
      lastRipPaid: total,
      message: 'Ripping ${pack.name}…',
    );
    _checkAchievements();
    await _persist();
    return true;
  }

  /// Opens a sealed pack into [lastRip] without adding to collection yet.
  /// Keep / Exchange decide each card during the theater.
  /// When [packId] is null, opens the oldest pack in inventory.
  Future<void> openPack({String? packId}) async {
    if (state.unopened.isEmpty) {
      state = state.copyWith(message: 'No packs to open.');
      return;
    }
    final idx = packId == null
        ? 0
        : state.unopened.indexWhere((p) => p.id == packId);
    if (idx < 0) {
      state = state.copyWith(message: 'Pack not found.');
      return;
    }
    final pack = state.unopened[idx];
    final remain = [...state.unopened]..removeAt(idx);
    final pulls = _opener.openPack(pack.setCode);
    final player = state.player
      ..packsOpened += 1
      ..xp += 2;
    state = state.copyWith(
      player: player,
      unopened: remain,
      lastRip: pulls,
      message: 'Ripping ${pack.setCode}…',
    );
    _checkAchievements();
    await _persist();
  }

  /// Back-compat alias.
  Future<void> openNextPack() => openPack();

  /// Street value of one unopened pack (box lots pro-rated per pack).
  double sealedPackMarketValue(UnopenedPack pack) {
    final product = sealedById(pack.sealedProductId);
    if (product == null) return 4.99;
    if (product.kind == SealedKind.pack) {
      return product.marketPrice > 0 ? product.marketPrice : 4.99;
    }
    if (product.kind == SealedKind.box) {
      final n = (product.packsPerBox ?? 24).clamp(1, 99);
      return product.marketPrice / n;
    }
    try {
      final match = _catalog.sealed.firstWhere(
        (s) => s.setCode == pack.setCode && s.kind == SealedKind.pack,
      );
      return match.marketPrice > 0 ? match.marketPrice : 4.99;
    } catch (_) {
      return 4.99;
    }
  }

  /// Sell refund: ~80% of market as cash (or candy at 100¢/$).
  double sealedPackSellCash(UnopenedPack pack) =>
      double.parse((sealedPackMarketValue(pack) * 0.80).toStringAsFixed(2));

  Future<void> sellUnopenedPack(
    String packId, {
    PaymentMethod refundAs = PaymentMethod.cash,
  }) async {
    final idx = state.unopened.indexWhere((p) => p.id == packId);
    if (idx < 0) {
      state = state.copyWith(message: 'Pack not found.');
      return;
    }
    final pack = state.unopened[idx];
    final cash = sealedPackSellCash(pack);
    final candy = (cash * 100).round().clamp(1, 999999);
    final remain = [...state.unopened]..removeAt(idx);
    final player = state.player;
    if (refundAs == PaymentMethod.cash) {
      player.cash += cash;
      state = state.copyWith(
        player: player,
        unopened: remain,
        message: 'Sold sealed pack for \$${cash.toStringAsFixed(2)}.',
      );
    } else {
      player.candy += candy;
      state = state.copyWith(
        player: player,
        unopened: remain,
        message: 'Sold sealed pack for $candy Candy.',
      );
    }
    await _persist();
  }

  Future<void> keepRipCard(String instanceId) async {
    final rip = state.lastRip;
    if (rip == null) return;
    OwnedCard? card;
    for (final c in rip) {
      if (c.instanceId == instanceId) {
        card = c;
        break;
      }
    }
    if (card == null) return;
    state = state.copyWith(
      collection: [...state.collection, card],
      lastRip: rip.where((c) => c.instanceId != instanceId).toList(),
      message: 'Kept for collection.',
    );
    _recordCollectionValue();
    await _persist();
  }

  Future<void> exchangeRipCard(String instanceId) async {
    final rip = state.lastRip;
    if (rip == null) return;
    OwnedCard? card;
    for (final c in rip) {
      if (c.instanceId == instanceId) {
        card = c;
        break;
      }
    }
    if (card == null) return;
    final fair = fairFor(card);
    final candyGain = (fair * 100).round().clamp(1, 999999);
    final player = state.player
      ..candy += candyGain
      ..cardsSold += 1
      ..xp += 1;
    state = state.copyWith(
      player: player,
      lastRip: rip.where((c) => c.instanceId != instanceId).toList(),
      message: 'Exchanged for $candyGain Candy.',
    );
    await _persist();
  }

  /// Auto-keep any remaining rip cards (e.g. user closes early).
  Future<void> finalizeRip({bool keepRemaining = true}) async {
    final rip = state.lastRip;
    if (rip == null || rip.isEmpty) {
      state = state.copyWith(clearLastRip: true);
      await _persist();
      return;
    }
    if (keepRemaining) {
      state = state.copyWith(
        collection: [...state.collection, ...rip],
        clearLastRip: true,
        message: 'Cards added to collection.',
      );
      _recordCollectionValue();
    } else {
      state = state.copyWith(clearLastRip: true);
    }
    await _persist();
  }

  Future<void> openBoxBurst(String setCode) async {
    // Convenience: if player has 24 packs of set, open as box with correction.
    final matching = state.unopened.where((p) => p.setCode == setCode).take(24).toList();
    if (matching.length < 24) {
      state = state.copyWith(message: 'Need 24 $setCode packs queued.');
      return;
    }
    final pulls = _opener.openBox(setCode);
    final remain = [...state.unopened];
    for (final m in matching) {
      remain.removeWhere((p) => p.id == m.id);
    }
    final player = state.player
      ..packsOpened += 24
      ..xp += 40;
    state = state.copyWith(
      player: player,
      unopened: remain,
      lastRip: pulls,
      message: 'Box break: ${pulls.length} cards from $setCode.',
    );
    _checkAchievements();
    await _persist();
  }

  Future<void> buyMarketListing(String id) async {
    final listing = state.market.firstWhere((m) => m.id == id);
    if (state.player.cash < listing.price) {
      state = state.copyWith(message: 'Not enough cash.');
      return;
    }
    final owned = OwnedCard(
      instanceId: _uuid.v4(),
      cardId: listing.cardId,
      foil: listing.foil,
      condition: listing.condition,
      centeringLR: listing.centeringLR,
      centeringTB: listing.centeringTB,
      surface: listing.isFake ? 4 : (listing.graded ? 9.0 : 8.5),
      edges: listing.isFake ? 4 : (listing.graded ? 9.0 : 8.5),
      corners: listing.isFake ? 3.5 : (listing.graded ? 9.0 : 8.5),
      defects: listing.isFake ? [FactoryDefect.printLine] : const [],
      graded: listing.graded,
      grade: listing.grade,
      gradingCompany: listing.gradingCompany,
    );
    final player = state.player..cash -= listing.price;
    state = state.copyWith(
      player: player,
      collection: [...state.collection, owned],
      market: state.market.where((m) => m.id != id).toList(),
      message: listing.isFake
          ? 'Bought… looks suspicious. Might be fake.'
          : 'Purchased ${listing.title}.',
    );
    _recordCollectionValue();
    await _persist();
  }

  Future<void> listOnline(String instanceId, double ask) async {
    final card = state.collection.firstWhere((c) => c.instanceId == instanceId);
    if (card.listedAsk != null) {
      state = state.copyWith(message: 'Already listed.');
      return;
    }
    final listing = OnlineListing(
      id: _uuid.v4(),
      ownedInstanceId: instanceId,
      ask: ask,
      listedDay: state.day,
    );
    final updated = state.collection
        .map((c) => c.instanceId == instanceId ? c.copyWith(listedAsk: ask) : c)
        .toList();
    state = state.copyWith(
      collection: updated,
      onlineListings: [...state.onlineListings, listing],
      message: 'Listed online for \$${ask.toStringAsFixed(2)}.',
    );
    await _persist();
  }

  Future<void> cancelOnlineListing(String listingId) async {
    final listing = state.onlineListings.firstWhere((l) => l.id == listingId);
    state = state.copyWith(
      onlineListings:
          state.onlineListings.where((l) => l.id != listingId).toList(),
      collection: state.collection
          .map((c) => c.instanceId == listing.ownedInstanceId
              ? c.copyWith(clearListedAsk: true)
              : c)
          .toList(),
      message: 'Listing cancelled.',
    );
    await _persist();
  }

  Future<void> sendToGrading(String instanceId, GradingCompany company) async {
    final card = state.collection.firstWhere((c) => c.instanceId == instanceId);
    if (card.graded || card.listedAsk != null) {
      state = state.copyWith(message: 'Cannot grade this card right now.');
      return;
    }
    final fee = company.fee.toDouble();
    if (state.player.cash < fee) {
      state = state.copyWith(message: 'Need \$${fee.toStringAsFixed(0)} for grading.');
      return;
    }
    final player = state.player..cash -= fee;
    final job = GradingJob(
      id: _uuid.v4(),
      ownedInstanceId: instanceId,
      company: company,
      turnsLeft: company.turns,
    );
    state = state.copyWith(
      player: player,
      grading: [...state.grading, job],
      message: 'Sent to ${company.label}.',
    );
    await _persist();
  }

  Future<void> revealSlab(String jobId) async {
    final job = state.grading.firstWhere((g) => g.id == jobId);
    if (!job.ready || job.revealed) return;
    final card =
        state.collection.firstWhere((c) => c.instanceId == job.ownedInstanceId);
    final grade = _rollGrade(card, job.company);
    job.revealed = true;
    job.resultGrade = grade;
    final updated = state.collection.map((c) {
      if (c.instanceId != card.instanceId) return c;
      return c.copyWith(
        graded: true,
        grade: grade,
        gradingCompany: job.company,
      );
    }).toList();
    final player = state.player;
    if (grade >= 10) player.gemsPulled += 1;
    player.xp += grade >= 9.5 ? 15 : 5;
    state = state.copyWith(
      player: player,
      collection: updated,
      grading: [...state.grading],
      message: grade >= 10
          ? 'GEM MINT 10!'
          : '${job.company.label} ${grade.toStringAsFixed(1)}',
    );
    _checkAchievements();
    _recordCollectionValue();
    await _persist();
  }

  Future<void> massReveal() async {
    if (!state.player.ownedUpgrades.contains('mass_reveal')) {
      state = state.copyWith(message: 'Unlock Mass Reveal first.');
      return;
    }
    final ready = state.grading.where((g) => g.ready && !g.revealed).toList();
    for (final j in ready) {
      await revealSlab(j.id);
    }
  }

  double _rollGrade(OwnedCard card, GradingCompany _) {
    final center = card.centeringScore;
    final sub = (card.surface + card.edges + card.corners) / 3;
    var raw = (center / 10 + sub) / 2;
    // PSA — honest grades, no soft bump
    if (card.defects.contains(FactoryDefect.miscut)) raw -= 1.5;
    if (card.defects.contains(FactoryDefect.bentCorner)) raw -= 0.8;
    raw = raw.clamp(1.0, 10.0);
    // Snap to common grade steps
    final steps = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 8.5, 9.0, 9.5, 10.0];
    return steps.reduce((a, b) => (a - raw).abs() < (b - raw).abs() ? a : b);
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
    final player = state.player
      ..cash -= def.cost
      ..ownedUpgrades.add(id);
    state = state.copyWith(player: player, message: 'Unlocked ${def.name}.');
    await _persist();
  }

  Future<void> advanceDay() async {
    var events = state.events
        .map((e) => e.copyWith(turnsLeft: e.turnsLeft - 1))
        .where((e) => e.turnsLeft > 0)
        .toList();
    if (_rng.nextDouble() < 0.55) events = [...events, _randomEvent()];

    // Grading countdown
    final grading = state.grading.map((g) {
      if (!g.ready && !g.revealed) {
        g.turnsLeft -= 1;
        if (g.turnsLeft <= 0) g.ready = true;
      }
      return g;
    }).toList();

    // Online listing fills
    final player = state.player;
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
          ? 0.75
          : ratio <= 1.05
              ? 0.35
              : ratio <= 1.2
                  ? 0.12
                  : 0.03;
      if (_rng.nextDouble() < chance) {
        final fee = listing.ask * Pricing.platformFeeRate(player);
        player.cash += listing.ask - fee;
        player.cardsSold += 1;
        player.xp += 3;
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
      if (state.player.ownedUpgrades.contains('auto_snipe') &&
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
          player.cash -= a.currentBid;
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
    final market = _generateSinglesMarket();

    state = state.copyWith(
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
    _checkAchievements();
    _recordCollectionValue();
    await _persist();
  }

  void _checkAchievements() {
    final p = state.player;
    if (p.packsOpened >= 10) p.unlockedAchievements.add('ripper_10');
    if (p.gemsPulled >= 1) p.unlockedAchievements.add('first_gem');
    if (p.cardsSold >= 5) p.unlockedAchievements.add('seller_5');
    if (state.collection.length >= 50) p.unlockedAchievements.add('binder_50');
  }

  double totalCollectionValue() {
    var v = 0.0;
    for (final o in state.collection) {
      v += fairFor(o);
    }
    return v;
  }

  /// Snapshot portfolio value when it changes (same calendar day updates in place).
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

  double fairFor(OwnedCard card) {
    final def = _catalog.byId[card.cardId];
    if (def == null) return 0;
    return Pricing.fairValue(def, card, events: state.events);
  }

  SealedProduct? sealedById(String id) {
    try {
      return _catalog.sealed.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  CardDef? cardById(String id) => _catalog.byId[id];
}
