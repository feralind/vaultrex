part of 'game_controller.dart';

mixin _RipSession on _GameNotifierBase {
  /// Opens a sealed pack into [lastRip] without adding to collection yet.
  /// Keep / Exchange decide each card during the theater.
  /// When [packId] is null, opens the oldest pack in inventory.
  Future<void> openPack({String? packId}) async {
    if (_shopBusy) return;
    if (state.lastRip?.isNotEmpty == true) {
      state = state.copyWith(message: 'Finish current rip first.');
      return;
    }
    _shopBusy = true;
    try {
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
      final player = state.player.copyWith(
        packsOpened: state.player.packsOpened + 1,
        xp: state.player.xp + 2,
      );
      state = state.copyWith(
        player: player,
        unopened: remain,
        lastRip: pulls,
        message: 'Ripping ${pack.setCode}…',
      );
      _checkAchievements();
      await _persist();
    } finally {
      _shopBusy = false;
    }
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
      state = state.copyWith(
        player: player.copyWith(cash: player.cash + cash),
        unopened: remain,
        message: 'Sold sealed pack for \$${cash.toStringAsFixed(2)}.',
      );
    } else {
      state = state.copyWith(
        player: player.copyWith(candy: player.candy + candy),
        unopened: remain,
        message: 'Sold sealed pack for $candy Candy.',
      );
    }
    await _persist();
  }

  Future<void> keepRipCard(String instanceId) => _enqueueRip(() async {
        final inCollection =
            state.collection.any((c) => c.instanceId == instanceId);
        final rip = state.lastRip;
        final inRip =
            rip?.any((c) => c.instanceId == instanceId) ?? false;

        if (inCollection) {
          if (inRip) {
            state = state.copyWith(
              lastRip:
                  rip!.where((c) => c.instanceId != instanceId).toList(),
            );
            await _persist();
          }
          return;
        }
        if (!inRip) return;

        final card = rip!.firstWhere((c) => c.instanceId == instanceId);
        state = state.copyWith(
          collection: [...state.collection, card],
          lastRip: rip.where((c) => c.instanceId != instanceId).toList(),
          message: 'Kept for collection.',
          recentlyKeptIds: {...state.recentlyKeptIds, instanceId},
        );
        _recordCollectionValue();
        await _persist();
      });

  Future<void> exchangeRipCard(String instanceId) => _enqueueRip(() async {
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
        // Already kept into collection — just drop from rip if still there.
        if (state.collection.any((c) => c.instanceId == instanceId)) {
          state = state.copyWith(
            lastRip: rip.where((c) => c.instanceId != instanceId).toList(),
          );
          await _persist();
          return;
        }
        final fair = fairFor(card);
        final candyGain = (fair * 100).round().clamp(1, 999999);
        final player = state.player.copyWith(
          candy: state.player.candy + candyGain,
          cardsSold: state.player.cardsSold + 1,
          xp: state.player.xp + 1,
        );
        state = state.copyWith(
          player: player,
          lastRip: rip.where((c) => c.instanceId != instanceId).toList(),
          message: 'Exchanged for $candyGain Candy.',
        );
        await _persist();
      });

  Future<void> decideRipCard(String instanceId, {required bool keep}) =>
      keep ? keepRipCard(instanceId) : exchangeRipCard(instanceId);

  /// Auto-keep any remaining rip cards (e.g. user closes early).
  Future<void> finalizeRip({bool keepRemaining = true}) =>
      _enqueueRip(() async {
        final rip = state.lastRip;
        if (rip == null || rip.isEmpty) {
          state = state.copyWith(clearLastRip: true);
          await _persist();
          return;
        }
        if (keepRemaining) {
          final ownedIds = {for (final c in state.collection) c.instanceId};
          final toAdd =
              rip.where((c) => !ownedIds.contains(c.instanceId)).toList();
          state = state.copyWith(
            collection: [...state.collection, ...toAdd],
            clearLastRip: true,
            message: 'Cards added to collection.',
            recentlyKeptIds: {
              ...state.recentlyKeptIds,
              ...toAdd.map((c) => c.instanceId),
            },
          );
          _recordCollectionValue();
        } else {
          state = state.copyWith(clearLastRip: true);
        }
        await _persist();
      });

  void acknowledgeRecentlyKept(String instanceId) {
    if (!state.recentlyKeptIds.contains(instanceId)) return;
    final next = {...state.recentlyKeptIds}..remove(instanceId);
    state = state.copyWith(recentlyKeptIds: next);
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
    final player = state.player.copyWith(
      packsOpened: state.player.packsOpened + 24,
      xp: state.player.xp + 40,
    );
    state = state.copyWith(
      player: player,
      unopened: remain,
      lastRip: pulls,
      message: 'Box break: ${pulls.length} cards from $setCode.',
    );
    _checkAchievements();
    await _persist();
  }
}
