import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/engagement_defs.dart';
import '../../data/rival_personas.dart';
import '../../game/game_controller.dart';
import '../../game/rival_sim.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
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
        title: const Text('Account'),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          AppSpace.s8,
          AppSpace.s16,
          28,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ScreenTitle(
                  'Account',
                  subtitle: '$title · Lv ${p.businessLevel}',
                ),
              ),
              BalanceBar(candy: p.candy, cash: p.cash),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(AppSpace.rCard),
              border: Border.all(color: CC.line),
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: [
                  CC.accent.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CC.accent, width: 2),
                    color: CC.cardSoft,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'B',
                    style: AppText.display(color: CC.accent).copyWith(
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You', style: AppText.titleSm()),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        '\$${value.toStringAsFixed(0)} portfolio',
                        style: AppText.bodySm(),
                      ),
                      const SizedBox(height: AppSpace.s8),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        ),
                        child: AppChip(
                          label: '#$rank binder · $unlocked rivals',
                          selected: true,
                          compact: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            '${p.gemsPulled} greens · \$${flipCash.toStringAsFixed(0)} flipped · '
            '${state.engagement.dailyStreak}d streak',
            style: AppText.bodySm(),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('Stats', style: AppText.titleSm()),
          const SizedBox(height: AppSpace.s8),
          _statGrid([
            ('Cash', '\$${p.cash.toStringAsFixed(2)}', CC.cash),
            ('Candy', '${p.candy}', CC.candy),
            ('XP', '${p.xp}', CC.accent),
            ('Streak', '${state.engagement.dailyStreak}d', CC.scan),
            ('Packs', '${p.packsOpened}', CC.ink),
            ('Sold', '${p.cardsSold}', CC.ink),
            ('Gems', '${p.gemsPulled}', CC.scan),
            (
              'Vault',
              '${state.engagement.vaultInstanceIds.length}/12',
              CC.candy
            ),
          ]),
          const SizedBox(height: AppSpace.s24),
          Text('Collection highlights', style: AppText.titleSm()),
          const SizedBox(height: AppSpace.s4),
          Text(
            '\$${value.toStringAsFixed(2)} portfolio · '
            '${state.engagement.binderPagesUnlocked} binder pages',
            style: AppText.bodySm(),
          ),
          const SizedBox(height: AppSpace.s12),
          if (topCards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s24),
              child: Center(
                child: Text(
                  'Rip packs to fill your account showcase.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySm(),
                ),
              ),
            )
          else
            ...topCards.map((o) {
              final def = notifier.cardById(o.cardId);
              if (def == null) return const SizedBox.shrink();
              final fair = notifier.fairFor(o);
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpace.s8),
                padding: const EdgeInsets.all(AppSpace.s12),
                decoration: BoxDecoration(
                  color: CC.card,
                  borderRadius: BorderRadius.circular(AppSpace.rCard),
                  border: Border.all(color: CC.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titleSm(),
                    ),
                    const SizedBox(height: AppSpace.s8),
                    Wrap(
                      spacing: AppSpace.s8,
                      runSpacing: AppSpace.s4,
                      children: [
                        AppChip(label: o.condition.name, compact: true),
                        if (o.foil)
                          const AppChip(label: 'Foil', compact: true),
                        if (o.graded)
                          AppChip(
                            label: 'PSA ${o.grade?.toStringAsFixed(1) ?? ''}',
                            compact: true,
                          ),
                        AppChip(
                          label: '\$${fair.toStringAsFixed(2)}',
                          compact: true,
                          selected: true,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statGrid(List<(String, String, Color)> items) {
    return Wrap(
      spacing: AppSpace.s8,
      runSpacing: AppSpace.s8,
      children: items
          .map(
            (e) => Container(
              width: 104,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s12,
                vertical: AppSpace.s12,
              ),
              decoration: BoxDecoration(
                color: CC.card,
                borderRadius: BorderRadius.circular(AppSpace.rChip),
                border: Border.all(color: CC.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.$1, style: AppText.label()),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    e.$2,
                    style: AppText.tabular(color: e.$3, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
