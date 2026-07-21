import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

class SeasonQuestsScreen extends ConsumerWidget {
  const SeasonQuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(gameProvider.select((s) => s.activeSeason));
    final notifier = ref.read(gameProvider.notifier);

    if (season == null) {
      return Scaffold(
        backgroundColor: CC.bg,
        appBar: AppBar(
          title: Text(
            'Season Quests',
            style: AppText.jakarta(fontWeight: FontWeight.w800),
          ),
          backgroundColor: CC.bg,
        ),
        body: Center(
          child: FilledButton(
            onPressed: () {
              notifier.ensureActiveSeason();
            },
            child: const Text('Start season'),
          ),
        ),
      );
    }

    final days = season.daysRemaining();
    final done = season.quests.where((q) => q.complete).length;

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text(
          'Season Quests',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CC.line),
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  season.name,
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  season.isExpired()
                      ? 'Season ended'
                      : '$days day${days == 1 ? '' : 's'} left · $done/${season.quests.length} quests done',
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...season.quests.map((q) => _QuestTile(quest: q)),
        ],
      ),
    );
  }
}

class _QuestTile extends ConsumerWidget {
  const _QuestTile({required this.quest});

  final SeasonQuest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = quest.progress.clamp(0, quest.target);
    final frac = quest.target == 0 ? 0.0 : progress / quest.target;
    final rewardLabel = switch (quest.rewardType) {
      RewardType.candy => '+${quest.rewardAmount} candy',
      RewardType.xp => '+${quest.rewardAmount} XP',
      RewardType.cash => '+\$${quest.rewardAmount}',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CC.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CC.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quest.title,
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  rewardLabel,
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: quest.claimed ? CC.inkMuted : CC.candy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              quest.description,
              style: AppText.jakarta(
                color: CC.inkMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: frac.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: CC.cardSoft,
                color: quest.complete ? CC.scan : CC.accent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$progress / ${quest.target}',
                  style: AppText.jakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CC.inkMuted,
                  ),
                ),
                const Spacer(),
                if (quest.claimed)
                  Text(
                    'Claimed',
                    style: AppText.jakarta(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CC.inkMuted,
                    ),
                  )
                else if (quest.complete)
                  TextButton(
                    onPressed: () => ref
                        .read(gameProvider.notifier)
                        .claimSeasonQuestReward(quest.id),
                    child: Text(
                      'Claim',
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        color: CC.scan,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
