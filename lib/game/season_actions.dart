part of 'game_controller.dart';

mixin _SeasonActions on _GameNotifierBase {
  /// Ensure an active season exists (seed Dragon Hunt when missing/expired).
  Season ensureActiveSeason() {
    final current = state.activeSeason;
    if (current != null && current.isActive()) return current;
    final seeded = Season.dragonHunt();
    state = state.copyWith(activeSeason: seeded);
    return seeded;
  }

  @override
  void _bumpSeasonQuest(String trackId, [int by = 1]) {
    final season = state.activeSeason;
    if (season == null || !season.isActive()) return;
    var changed = false;
    final quests = season.quests.map((q) {
      if (q.trackId != trackId || q.claimed || q.complete) return q;
      changed = true;
      final next = (q.progress + by).clamp(0, q.target);
      return q.copyWith(progress: next);
    }).toList();
    if (!changed) return;
    state = state.copyWith(
      activeSeason: season.copyWith(quests: quests),
    );
  }

  Future<void> claimSeasonQuestReward(String questId) async {
    final season = state.activeSeason;
    if (season == null || !season.isActive()) {
      state = state.copyWith(message: 'No active season.');
      return;
    }
    final idx = season.quests.indexWhere((q) => q.id == questId);
    if (idx < 0) {
      state = state.copyWith(message: 'Quest not found.');
      return;
    }
    final quest = season.quests[idx];
    if (!quest.complete) {
      state = state.copyWith(message: 'Quest not finished yet.');
      return;
    }
    if (quest.claimed) {
      state = state.copyWith(message: 'Already claimed.');
      return;
    }
    var player = state.player;
    switch (quest.rewardType) {
      case RewardType.candy:
        player = player.copyWith(candy: player.candy + quest.rewardAmount);
      case RewardType.xp:
        player = player.copyWith(xp: player.xp + quest.rewardAmount);
      case RewardType.cash:
        player = player.copyWith(
          cash: player.cash + quest.rewardAmount.toDouble(),
        );
    }
    final quests = [...season.quests];
    quests[idx] = quest.copyWith(claimed: true);
    final rewardLabel = switch (quest.rewardType) {
      RewardType.candy => '+${quest.rewardAmount} candy',
      RewardType.xp => '+${quest.rewardAmount} XP',
      RewardType.cash => '+\$${quest.rewardAmount}',
    };
    state = state.copyWith(
      player: player,
      activeSeason: season.copyWith(quests: quests),
      message: 'Claimed ${quest.title} — $rewardLabel.',
    );
    await _persist();
  }
}
