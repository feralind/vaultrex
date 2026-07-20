import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/engagement_defs.dart';
import '../../data/rival_personas.dart';
import '../../game/game_controller.dart';
import '../../game/rival_sim.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import 'leaderboard_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (!state.ready) {
      return const Scaffold(
        backgroundColor: CC.bg,
        body: Center(child: CircularProgressIndicator(color: CC.accent)),
      );
    }

    final p = state.player;
    final title = businessTitleForLevel(p.businessLevel);
    final value = notifier.totalCollectionValue();
    final rank = RivalSim.playerRank(
      playerValue: value,
      businessLevel: p.businessLevel,
      metric: RivalBoardMetric.binder,
      playerCardsSold: p.cardsSold,
      playerGemsPulled: p.gemsPulled,
    );
    final unlocked = rivalBoardSizeForLevel(p.businessLevel);
    final flipCash = RivalSim.playerFlipCash(
      cardsSold: p.cardsSold,
      binderValue: value,
    );
    final top = [...state.collection]
      ..sort((a, b) => notifier.fairFor(b).compareTo(notifier.fairFor(a)));
    final topCards = top.take(8).toList();

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text('Account', style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CC.accent, width: 2),
                  color: CC.card,
                ),
                alignment: Alignment.center,
                child: Text(
                  'B',
                  style: AppText.jakarta(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: CC.accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You',
                      style: AppText.jakarta(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$title · Lv ${p.businessLevel}',
                      style: AppText.jakarta(color: CC.inkMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      ),
                      child: Text(
                        '#$rank binder · ${p.gemsPulled} greens · \$${flipCash.toStringAsFixed(0)} flipped · $unlocked rivals',
                        style: AppText.jakarta(
                          color: CC.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _statGrid([
            ('Cash', '\$${p.cash.toStringAsFixed(2)}'),
            ('Candy', '${p.candy}'),
            ('XP', '${p.xp}'),
            ('Streak', '${state.engagement.dailyStreak}d'),
            ('Packs', '${p.packsOpened}'),
            ('Sold', '${p.cardsSold}'),
            ('Gems', '${p.gemsPulled}'),
            ('Vault', '${state.engagement.vaultInstanceIds.length}/12'),
          ]),
          const SizedBox(height: 18),
          Text(
            'Collection highlights',
            style: AppText.jakarta(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(
            '\$${value.toStringAsFixed(2)} portfolio · ${state.engagement.binderPagesUnlocked} binder pages',
            style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (topCards.isEmpty)
            Text(
              'Rip packs to fill your account showcase.',
              style: AppText.jakarta(color: CC.inkMuted),
            )
          else
            ...topCards.map((o) {
              final def = notifier.cardById(o.cardId);
              if (def == null) return const SizedBox.shrink();
              final fair = notifier.fairFor(o);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CC.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CC.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            def.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.jakarta(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _chip(o.condition.name),
                              if (o.foil) _chip('Foil'),
                              if (o.graded)
                                _chip(
                                  'PSA ${o.grade?.toStringAsFixed(1) ?? ''}',
                                ),
                              _chip('\$${fair.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statGrid(List<(String, String)> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (e) => Container(
              width: 104,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: CC.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CC.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.$1,
                    style: AppText.jakarta(color: CC.inkMuted, fontSize: 11),
                  ),
                  Text(
                    e.$2,
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: CC.cardSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppText.jakarta(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
