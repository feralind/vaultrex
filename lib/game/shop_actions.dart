part of 'game_controller.dart';

mixin _ShopActions on _GameNotifierBase {
  Future<void> buySealed(
    String listingId, {
    int qty = 1,
    PaymentMethod payWith = PaymentMethod.cash,
  }) async {
    if (_shopBusy) return;
    _shopBusy = true;
    try {
      final listing = state.sealedListings.firstWhere((l) => l.id == listingId);
      final product =
          _catalog.sealed.firstWhere((s) => s.id == listing.sealedProductId);
      final total = listing.price * qty;
      final candyCost = (total * 100).round();
      var player = state.player;

      if (payWith == PaymentMethod.cash) {
        if (player.cash < total) {
          state = state.copyWith(message: 'Not enough cash.');
          return;
        }
        player = player.copyWith(cash: player.cash - total);
      } else {
        if (player.candy < candyCost) {
          state = state.copyWith(message: 'Not enough Candy.');
          return;
        }
        player = player.copyWith(candy: player.candy - candyCost);
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
    } finally {
      _shopBusy = false;
    }
  }

  /// Buy a Featured Pack and open immediately into [lastRip].
  /// Returns true on success so UI can launch [showPackTheater] with
  /// `alreadyOpened: true`.
  Future<bool> buyFeaturedPack(
    String featuredPackId, {
    PaymentMethod payWith = PaymentMethod.cash,
  }) async {
    if (_shopBusy) return false;
    if (state.lastRip?.isNotEmpty == true) {
      state = state.copyWith(message: 'Finish current rip first.');
      return false;
    }
    _shopBusy = true;
    try {
      final pack = featuredPackById(featuredPackId);
      if (pack == null) {
        state = state.copyWith(message: 'Featured pack not found.');
        return false;
      }
      final total = pack.priceUsd;
      final candyCost = pack.candyPrice;
      var player = state.player;

      if (payWith == PaymentMethod.cash) {
        if (player.cash < total) {
          state = state.copyWith(message: 'Not enough cash.');
          return false;
        }
        player = player.copyWith(cash: player.cash - total);
      } else {
        if (player.candy < candyCost) {
          state = state.copyWith(message: 'Not enough Candy.');
          return false;
        }
        player = player.copyWith(candy: player.candy - candyCost);
      }

      final pulls = _featuredOpener.open(pack);
      if (pulls.isEmpty) {
        // Refund on empty open (should not happen with a loaded catalog).
        player = payWith == PaymentMethod.cash
            ? player.copyWith(cash: player.cash + total)
            : player.copyWith(candy: player.candy + candyCost);
        state = state.copyWith(
          player: player,
          message: 'Could not open featured pack — catalog empty.',
        );
        return false;
      }

      player = player.copyWith(
        packsOpened: player.packsOpened + 1,
        xp: player.xp + 3,
      );
      state = state.copyWith(
        player: player,
        lastRip: pulls,
        lastRipPaid: total,
        message: 'Ripping ${pack.name}…',
      );
      _checkAchievements();
      await _persist();
      return true;
    } finally {
      _shopBusy = false;
    }
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
    final player =
        state.player.copyWith(cash: state.player.cash - listing.price);
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

  /// Simulated wallet top-up after fake Google Pay succeeds.
  Future<void> topUpCash(double amount) async {
    final add = double.parse(amount.clamp(1, 99999).toStringAsFixed(2));
    final player = state.player.copyWith(cash: state.player.cash + add);
    state = state.copyWith(
      player: player,
      message: add >= 1000
          ? 'Wallet topped up +\$${add.toStringAsFixed(0)} 😉'
          : 'Added \$${add.toStringAsFixed(2)} to wallet.',
    );
    await _persist();
  }
}
