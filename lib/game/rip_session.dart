part of 'game_controller.dart';

mixin _RipSession on _GameNotifierBase {
  /// Opens a sealed pack into [lastRip] without adding to collection yet.
  /// Keep / Exchange decide each card during the theater.
  /// When [packId] is null, opens the oldest pack in inventory.
  /// Returns false if the pack was not opened (busy / unfinished rip / missing).
  Future<bool> openPack({String? packId}) async {
    if (_shopBusy) {
      state = state.copyWith(message: 'Shop busy — try again.');
      return false;
    }
    if (state.lastRip?.isNotEmpty == true) {
      state = state.copyWith(message: 'Finish current rip first.');
      return false;
    }
    _shopBusy = true;
    try {
      if (state.unopened.isEmpty) {
        state = state.copyWith(message: 'No packs to open.');
        return false;
      }
      final idx = packId == null
          ? 0
          : state.unopened.indexWhere((p) => p.id == packId);
      if (idx < 0) {
        state = state.copyWith(message: 'Pack not found.');
        return false;
      }
      final pack = state.unopened[idx];
      final remain = [...state.unopened]..removeAt(idx);
      final pulls = _opener.openPack(pack.setCode);
      final packArt = resolveUnopenedPackImageUrl(pack);
      final player = state.player.copyWith(
        packsOpened: state.player.packsOpened + 1,
        xp: state.player.xp + 2,
        businessLevel: businessLevelFromXp(state.player.xp + 2),
      );
      state = state.copyWith(
        player: player,
        unopened: remain,
        lastRip: pulls,
        lastRipPackImageUrl: packArt,
        message: 'Ripping ${pack.setCode}…',
      );
      _recordPullHistory(pulls, packLabel: pack.setCode);
      _onEngagementPackOpened();
      _checkAchievements();
      await _persist();
      return true;
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
        final def = _catalog.byId[card.cardId];
        final alreadyOwned = state.collection.any((c) => c.cardId == card.cardId);
        String msg = 'Kept for collection.';
        if (alreadyOwned) {
          final fair = fairFor(card);
          final candyWorth = exchangeCandyForFair(fair);
          msg = 'Dupe kept — also ~$candyWorth candy if exchanged.';
        } else if (def != null) {
          final setCards = _catalog.bySet[def.setCode] ?? [];
          if (setCards.length >= 2) {
            final owned = state.collection
                .map((c) => c.cardId)
                .where((id) => _catalog.byId[id]?.setCode == def.setCode)
                .toSet()
                .length;
            final after = owned + 1;
            final left = setCards.length - after;
            if (left == 0) {
              msg = 'Kept — ${def.setName} complete!';
            } else if (left == 1) {
              msg = 'Kept — 1 away from completing ${def.setName}!';
            } else if (left <= 5) {
              msg = 'Kept — $after/${setCards.length} in ${def.setName}.';
            }
          }
        }
        state = state.copyWith(
          collection: [...state.collection, card],
          lastRip: rip.where((c) => c.instanceId != instanceId).toList(),
          message: msg,
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
        final alreadyOwned =
            state.collection.any((c) => c.cardId == card.cardId);
        final def = _catalog.byId[card.cardId];
        var fillsHole = false;
        if (!alreadyOwned && def != null) {
          final setCards = _catalog.bySet[def.setCode] ?? [];
          if (setCards.length >= 2) {
            final owned = state.collection
                .map((c) => c.cardId)
                .where((id) => _catalog.byId[id]?.setCode == def.setCode)
                .toSet()
                .length;
            fillsHole = owned < setCards.length;
          }
        }
        final candyGain =
            exchangeCandyForFair(fair, fillsSetHole: fillsHole);
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
          // Fire-and-forget set milestone candy (Phase 3).
          unawaited(checkSetMilestones());
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
    // Franchise-accurate pack count (matches sealed box defaults).
    final need = _catalog.isPokemon
        ? 36
        : _catalog.isMtg
            ? 30
            : 24;
    final matching =
        state.unopened.where((p) => p.setCode == setCode).take(need).toList();
    if (matching.length < need) {
      state = state.copyWith(
        message: 'Need $need $setCode packs queued for a box break.',
      );
      return;
    }
    final pulls = _opener.openBox(setCode, packCount: need);
    final remain = [...state.unopened];
    for (final m in matching) {
      remain.removeWhere((p) => p.id == m.id);
    }
    final player = state.player.copyWith(
      packsOpened: state.player.packsOpened + need,
      xp: state.player.xp + (need >= 30 ? 50 : 40),
    );
    final packArt = matching.isNotEmpty
        ? resolveUnopenedPackImageUrl(matching.first)
        : null;
    state = state.copyWith(
      player: player,
      unopened: remain,
      lastRip: pulls,
      lastRipPackImageUrl: packArt,
      message: 'Box break: ${pulls.length} cards from $setCode ($need packs).',
    );
    _checkAchievements();
    await _persist();
  }
}
