part of 'game_controller.dart';

mixin _EngagementActions on _GameNotifierBase {
  EngagementState get _eng => state.engagement;

  @override
  void _onEngagementPackOpened() => _bumpDailyGoal('rip_2');

  @override
  void _onEngagementCardListed() => _bumpDailyGoal('list_1');

  @override
  void _onEngagementGradeSent() => _bumpDailyGoal('grade_1');

  @override
  void _onEngagementGradeRevealed() {
    _setEngagement(
      _eng.copyWith(gradedRevealedCount: _eng.gradedRevealedCount + 1),
    );
  }

  @override
  void _recordPullHistory(List<OwnedCard> pulls, {String? packLabel}) {
    _recordPulls(pulls, packLabel: packLabel);
  }

  @override
  EngagementState _afterFeaturedRipHook({
    required String packId,
    required bool hitChase,
  }) =>
      _afterFeaturedRip(packId: packId, hitChase: hitChase);

  void _setEngagement(EngagementState e, {String? message}) {
    state = state.copyWith(engagement: e, message: message);
  }

  PlayerStats _syncBusinessLevel(PlayerStats p) {
    final level = businessLevelFromXp(p.xp);
    final pages = binderPagesForLevel(level);
    var eng = _eng;
    if (pages > eng.binderPagesUnlocked) {
      eng = eng.copyWith(binderPagesUnlocked: pages);
    }
    if (level != p.businessLevel || eng != _eng) {
      // engagement may update pages; caller persists via state
    }
    return p.copyWith(businessLevel: level);
  }

  void _applyBusinessLevelSideEffects(PlayerStats p) {
    final pages = binderPagesForLevel(p.businessLevel);
    if (pages > _eng.binderPagesUnlocked) {
      _setEngagement(_eng.copyWith(binderPagesUnlocked: pages));
    }
  }

  /// Ensure daily goals map is for today.
  EngagementState _ensureDailyGoals(EngagementState e) {
    final today = engagementDayKey();
    if (e.dailyGoalsDate == today) return e;
    return e.copyWith(
      dailyGoalsDate: today,
      dailyGoalProgress: {for (final g in dailyGoalDefs) g.id: 0},
      claimedDailyGoals: {},
    );
  }

  void _bumpDailyGoal(String goalId, [int by = 1]) {
    var e = _ensureDailyGoals(_eng);
    final cur = e.dailyGoalProgress[goalId] ?? 0;
    final next = Map<String, int>.from(e.dailyGoalProgress)..[goalId] = cur + by;
    _setEngagement(e.copyWith(dailyGoalProgress: next));
  }

  Future<void> claimDailyLogin() async {
    final today = engagementDayKey();
    var e = _eng;
    if (e.dailyClaimDate == today) {
      state = state.copyWith(message: 'Already claimed today.');
      return;
    }
    final yesterday = engagementDayKey(DateTime.now().subtract(const Duration(days: 1)));
    final streak = e.dailyClaimDate == yesterday ? e.dailyStreak + 1 : 1;
    final candy = dailyClaimCandyForStreak(streak);
    e = e.copyWith(dailyClaimDate: today, dailyStreak: streak);
    var player = state.player.copyWith(candy: state.player.candy + candy);
    player = _syncBusinessLevel(player);
    state = state.copyWith(
      player: player,
      engagement: e,
      message: 'Day $streak streak — +$candy candy.',
    );
    _checkAchievements();
    await _persist();
  }

  Future<void> claimDailyGoal(String goalId) async {
    var e = _ensureDailyGoals(_eng);
    final def = dailyGoalDefs.firstWhere((g) => g.id == goalId);
    final progress = e.dailyGoalProgress[goalId] ?? 0;
    if (progress < def.target) {
      state = state.copyWith(message: 'Goal not finished yet.');
      return;
    }
    if (e.claimedDailyGoals.contains(goalId)) {
      state = state.copyWith(message: 'Already claimed.');
      return;
    }
    e = e.copyWith(
      claimedDailyGoals: {...e.claimedDailyGoals, goalId},
    );
    var player = state.player.copyWith(
      candy: state.player.candy + def.candyReward,
      xp: state.player.xp + def.xpReward,
    );
    player = _syncBusinessLevel(player);
    state = state.copyWith(
      player: player,
      engagement: e,
      message: 'Claimed ${def.title} — +${def.candyReward} candy.',
    );
    _applyBusinessLevelSideEffects(player);
    _checkAchievements();
    await _persist();
  }

  Future<void> clearPendingAchievements() async {
    if (_eng.pendingAchievementIds.isEmpty) return;
    _setEngagement(_eng.copyWith(pendingAchievementIds: const []));
  }

  Future<void> clearResumeMessage() async {
    if (_eng.pendingResumeMessage == null) return;
    _setEngagement(_eng.copyWith(clearResume: true));
  }

  void _recordPulls(List<OwnedCard> pulls, {String? packLabel}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final entries = [
      ...pulls.map(
        (o) => PullHistoryEntry(
          cardId: o.cardId,
          foil: o.foil,
          atMs: now,
          packLabel: packLabel,
          fairValue: fairFor(o),
        ),
      ),
      ..._eng.pullHistory,
    ].take(200).toList();
    _setEngagement(_eng.copyWith(pullHistory: entries));
  }

  Future<void> addToVault(String instanceId) async {
    if (!_eng.vaultInstanceIds.contains(instanceId) &&
        state.collection.any((c) => c.instanceId == instanceId)) {
      final next = [..._eng.vaultInstanceIds, instanceId].take(12).toList();
      _setEngagement(_eng.copyWith(vaultInstanceIds: next));
      await _persist();
    }
  }

  Future<void> removeFromVault(String instanceId) async {
    _setEngagement(
      _eng.copyWith(
        vaultInstanceIds:
            _eng.vaultInstanceIds.where((id) => id != instanceId).toList(),
      ),
    );
    await _persist();
  }

  /// Pity + chase heat after featured rip. Returns updated pity map.
  EngagementState _afterFeaturedRip({
    required String packId,
    required bool hitChase,
  }) {
    final pity = Map<String, int>.from(_eng.featuredPity);
    if (hitChase) {
      pity[packId] = 0;
    } else {
      pity[packId] = (pity[packId] ?? 0) + 1;
    }
    return _eng.copyWith(featuredPity: pity);
  }

  int featuredPityDry(String packId) => _eng.featuredPity[packId] ?? 0;

  /// Ensure timed featured drop clock exists (~4h cycle).
  Future<void> ensureFeaturedDropClock() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final end = _eng.featuredDropEndsAtMs;
    if (end != null && end > now) return;
    final nextEnd = now + const Duration(hours: 4).inMilliseconds;
    _setEngagement(_eng.copyWith(featuredDropEndsAtMs: nextEnd));
    await _persist();
  }

  /// Set completion milestones: 25 / 50 / 100%.
  @override
  Future<void> checkSetMilestones() async {
    var e = _eng;
    var candyGain = 0;
    var xpGain = 0;
    final unlocked = <String>{};
    for (final entry in _catalog.bySet.entries) {
      final code = entry.key;
      final all = entry.value;
      if (all.isEmpty) continue;
      final ownedIds = state.collection
          .map((c) => c.cardId)
          .where((id) => _catalog.byId[id]?.setCode == code)
          .toSet();
      final pct = ownedIds.length / all.length;
      for (final threshold in [25, 50, 100]) {
        final key = '$code:$threshold';
        if (pct * 100 + 0.001 < threshold) continue;
        if (e.setMilestonesClaimed.contains(key)) continue;
        unlocked.add(key);
        candyGain += threshold == 100
            ? 2000
            : threshold == 50
                ? 800
                : 350;
        xpGain += threshold == 100 ? 40 : threshold == 50 ? 18 : 8;
      }
    }
    if (unlocked.isEmpty) return;
    e = e.copyWith(
      setMilestonesClaimed: {...e.setMilestonesClaimed, ...unlocked},
    );
    var player = state.player.copyWith(
      candy: state.player.candy + candyGain,
      xp: state.player.xp + xpGain,
    );
    player = _syncBusinessLevel(player);
    final msg = unlocked.any((k) => k.endsWith(':100'))
        ? 'Set complete! +$candyGain candy.'
        : 'Set milestone! +$candyGain candy.';
    state = state.copyWith(player: player, engagement: e, message: msg);
    _applyBusinessLevelSideEffects(player);
    _checkAchievements();
    await _persist();
  }

  /// Sets that need exactly one more unique card.
  List<({String setCode, String setName, int owned, int total})> oneAwaySets() {
    final out = <({String setCode, String setName, int owned, int total})>[];
    for (final entry in _catalog.bySet.entries) {
      final all = entry.value;
      if (all.length < 2) continue;
      final owned = state.collection
          .map((c) => c.cardId)
          .where((id) => _catalog.byId[id]?.setCode == entry.key)
          .toSet()
          .length;
      if (owned == all.length - 1) {
        out.add((
          setCode: entry.key,
          setName: all.first.setName,
          owned: owned,
          total: all.length,
        ));
      }
    }
    return out;
  }

  Future<void> buyBinderPage() async {
    const cost = 1500;
    final maxPages = binderPagesForLevel(state.player.businessLevel) + 2;
    final current = _eng.binderPagesUnlocked;
    if (current >= maxPages) {
      state = state.copyWith(message: 'Raise business level for more pages.');
      return;
    }
    if (state.player.candy < cost) {
      state = state.copyWith(message: 'Need $cost candy for a binder page.');
      return;
    }
    final nextPages = current + 1;
    final player = state.player.copyWith(candy: state.player.candy - cost);
    state = state.copyWith(
      player: player,
      engagement: _eng.copyWith(binderPagesUnlocked: nextPages),
      message: 'Unlocked binder page $nextPages.',
    );
    await _persist();
  }

  /// Sealed draft: spend fixed candy for N featured-style rips from a set.
  Future<List<OwnedCard>?> runSealedDraft({
    required String setCode,
    int packCount = 3,
    int candyCost = 2400,
  }) async {
    if (state.player.candy < candyCost) {
      state = state.copyWith(message: 'Need $candyCost candy for sealed draft.');
      return null;
    }
    final pool = _catalog.bySet[setCode] ?? [];
    if (pool.isEmpty) {
      state = state.copyWith(message: 'No cards in that set.');
      return null;
    }
    final pulls = <OwnedCard>[];
    for (var p = 0; p < packCount; p++) {
      for (var i = 0; i < 5; i++) {
        final def = pool[_rng.nextInt(pool.length)];
        pulls.add(
          OwnedCard(
            instanceId: _uuid.v4(),
            cardId: def.id,
            foil: def.rarity.isRarePlus && _rng.nextDouble() < 0.4,
            condition: Condition.nearMint,
            centeringLR: 45 + _rng.nextDouble() * 10,
            centeringTB: 45 + _rng.nextDouble() * 10,
            surface: 9,
            edges: 9,
            corners: 9,
            defects: const [],
          ),
        );
      }
    }
    final player = state.player.copyWith(
      candy: state.player.candy - candyCost,
      packsOpened: state.player.packsOpened + packCount,
      xp: state.player.xp + packCount * 2,
    );
    state = state.copyWith(
      player: _syncBusinessLevel(player),
      lastRip: pulls,
      lastRipPaid: 0,
      message: 'Sealed draft — decide keep/exchange.',
    );
    _recordPulls(pulls, packLabel: 'Draft $setCode');
    _bumpDailyGoal('rip_2', packCount);
    _checkAchievements();
    await _persist();
    return pulls;
  }

  /// Weekly seeded challenge: deterministic pack from week seed.
  Future<List<OwnedCard>?> runWeeklyChallenge() async {
    const cost = 900;
    if (state.player.candy < cost) {
      state = state.copyWith(message: 'Need $cost candy for weekly challenge.');
      return null;
    }
    final now = DateTime.now();
    final week = now.year * 100 + (now.difference(DateTime(now.year)).inDays ~/ 7);
    final rng = Random(week);
    final cards = _catalog.cards.where((c) => c.marketPrice > 0).toList();
    if (cards.isEmpty) return null;
    final pulls = List.generate(8, (_) {
      final def = cards[rng.nextInt(cards.length)];
      return OwnedCard(
        instanceId: _uuid.v4(),
        cardId: def.id,
        foil: rng.nextDouble() < 0.2,
        condition: Condition.nearMint,
        centeringLR: 48 + rng.nextDouble() * 4,
        centeringTB: 48 + rng.nextDouble() * 4,
        surface: 9.2,
        edges: 9.1,
        corners: 9.0,
        defects: const [],
      );
    });
    final player = state.player.copyWith(
      candy: state.player.candy - cost,
      packsOpened: state.player.packsOpened + 1,
      xp: state.player.xp + 5,
    );
    state = state.copyWith(
      player: _syncBusinessLevel(player),
      lastRip: pulls,
      lastRipPaid: 0,
      message: 'Weekly seed #$week — same odds for everyone this week.',
    );
    _recordPulls(pulls, packLabel: 'Weekly #$week');
    _bumpDailyGoal('rip_2');
    await _persist();
    return pulls;
  }

  /// Endless survival: each round costs more; track best round.
  Future<bool> survivalRound({required int round}) async {
    final cost = 400 + round * 120;
    if (state.player.candy < cost) {
      state = state.copyWith(
        message: 'Survival ended at round $round — broke.',
        engagement: _eng.copyWith(
          survivalBestRound: max(_eng.survivalBestRound, round - 1),
        ),
      );
      await _persist();
      return false;
    }
    final cards = _catalog.cards.where((c) => c.marketPrice > 0.5).toList();
    if (cards.isEmpty) return false;
    final pulls = List.generate(5, (_) {
      final def = cards[_rng.nextInt(cards.length)];
      return OwnedCard(
        instanceId: _uuid.v4(),
        cardId: def.id,
        foil: _rng.nextDouble() < 0.15,
        condition: Condition.nearMint,
        centeringLR: 50,
        centeringTB: 50,
        surface: 9,
        edges: 9,
        corners: 9,
        defects: const [],
      );
    });
    // Auto-keep all; sell commons for candy to sustain.
    var candyGain = 0;
    final keep = <OwnedCard>[];
    for (final o in pulls) {
      final fair = fairFor(o);
      if (fair < 3) {
        candyGain += (fair * 80).round().clamp(20, 200);
      } else {
        keep.add(o);
      }
    }
    final player = state.player.copyWith(
      candy: state.player.candy - cost + candyGain,
      packsOpened: state.player.packsOpened + 1,
      xp: state.player.xp + 2,
    );
    state = state.copyWith(
      player: _syncBusinessLevel(player),
      collection: [...state.collection, ...keep],
      engagement: _eng.copyWith(
        survivalBestRound: max(_eng.survivalBestRound, round),
      ),
      message:
          'Survival round $round — spent $cost candy, +$candyGain from bulk.',
    );
    _recordPulls(pulls, packLabel: 'Survival r$round');
    await _persist();
    return true;
  }

  void queueResumeToast(String msg) {
    _setEngagement(_eng.copyWith(pendingResumeMessage: msg));
  }

  /// Rival offers to buy your top unlisted card at fair × fairBias.
  Future<String?> rivalAskToBuy(String personaId) async {
    final persona = rivalById(personaId);
    if (persona == null) return 'Rival not found.';
    final available = state.collection
        .where((c) => c.listedAsk == null)
        .where(
          (c) => !state.grading.any(
            (g) => g.ownedInstanceId == c.instanceId && !g.revealed,
          ),
        )
        .toList();
    if (available.isEmpty) {
      return '${persona.handle} shrugged — nothing free to buy.';
    }
    available.sort((a, b) => fairFor(b).compareTo(fairFor(a)));
    final card = available.first;
    final fair = fairFor(card);
    final offer = double.parse((fair * persona.fairBias).toStringAsFixed(2));
    if (offer < 0.5) {
      return '${persona.handle} passed — too cheap to bother.';
    }
    final def = _catalog.byId[card.cardId];
    final name = def?.name ?? card.cardId;
    final idx =
        state.collection.indexWhere((c) => c.instanceId == card.instanceId);
    if (idx < 0) return 'Card vanished.';
    final next = [...state.collection]..removeAt(idx);
    final player = state.player.copyWith(
      cash: state.player.cash + offer,
      cardsSold: state.player.cardsSold + 1,
      xp: state.player.xp + 2,
      businessLevel: businessLevelFromXp(state.player.xp + 2),
    );
    state = state.copyWith(
      player: player,
      collection: next,
      message:
          '${persona.handle} bought $name for \$${offer.toStringAsFixed(2)} '
          '(${(persona.fairBias * 100).round()}% fair) — ${persona.quirk}',
      engagement: _eng.copyWith(
        rivalMoodSeed: _eng.rivalMoodSeed + persona.seed,
      ),
    );
    _recordCollectionValue();
    await _persist();
    return null;
  }
}
