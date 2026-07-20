import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/rival_personas.dart';
import '../../game/game_controller.dart';
import '../../game/rival_sim.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import 'rival_profile_screen.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  RivalBoardMetric _metric = RivalBoardMetric.binder;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final binder = state.ready ? notifier.totalCollectionValue() : 0.0;
    final p = state.player;
    final board = RivalSim.buildBoard(
      playerValue: binder,
      businessLevel: p.businessLevel,
      metric: _metric,
      playerCardsSold: p.cardsSold,
      playerGemsPulled: p.gemsPulled,
    );
    final unlocked = rivalBoardSizeForLevel(p.businessLevel);
    final you = board.where((e) => e.isPlayer).firstOrNull;

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text(
          'Weekly boards',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        backgroundColor: CC.bg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Flavor rivals only — not real players. Unlock more as you level ($unlocked/16).',
              style: AppText.jakarta(
                color: CC.inkMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<RivalBoardMetric>(
              segments: const [
                ButtonSegment(
                  value: RivalBoardMetric.binder,
                  label: Text('Binder'),
                  icon: Icon(Icons.collections_bookmark_outlined, size: 16),
                ),
                ButtonSegment(
                  value: RivalBoardMetric.flips,
                  label: Text('Flips'),
                  icon: Icon(Icons.payments_outlined, size: 16),
                ),
                ButtonSegment(
                  value: RivalBoardMetric.greens,
                  label: Text('Greens'),
                  icon: Icon(Icons.auto_awesome, size: 16),
                ),
              ],
              selected: {_metric},
              onSelectionChanged: (s) => setState(() => _metric = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  AppText.jakarta(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _metric.label,
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _metric.blurb,
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (you != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'You · #${you.rank} · ${you.scoreLabel} ${_metric.unitHint}',
                    style: AppText.jakarta(
                      color: CC.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: board.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = board[i];
                final persona = e.persona;
                final scoreColor = switch (_metric) {
                  RivalBoardMetric.binder => const Color(0xFF34D399),
                  RivalBoardMetric.flips => const Color(0xFFFBBF24),
                  RivalBoardMetric.greens => const Color(0xFF4ADE80),
                };
                return Material(
                  color: e.isPlayer
                      ? CC.accent.withValues(alpha: 0.12)
                      : CC.card,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: e.isPlayer || persona == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    RivalProfileScreen(personaId: persona.id),
                              ),
                            ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: e.isPlayer
                              ? CC.accent.withValues(alpha: 0.45)
                              : CC.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '#${e.rank}',
                              style: AppText.jakarta(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          _Avatar(persona: persona, isPlayer: e.isPlayer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.displayName,
                                  style: AppText.jakarta(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                if (!e.isPlayer && persona != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${persona.personality.first} · ${e.status.label}',
                                    style: AppText.jakarta(
                                      color: CC.inkMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ] else if (e.isPlayer) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _metric.unitHint,
                                    style: AppText.jakarta(
                                      color: CC.inkMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                e.scoreLabel,
                                style: AppText.jakarta(
                                  fontWeight: FontWeight.w800,
                                  color: scoreColor,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _metric == RivalBoardMetric.greens
                                    ? 'hits'
                                    : 'this week',
                                style: AppText.jakarta(
                                  color: CC.inkMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.persona, required this.isPlayer});

  final RivalPersona? persona;
  final bool isPlayer;

  @override
  Widget build(BuildContext context) {
    if (isPlayer) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: CC.cardSoft,
        child: Text(
          'B',
          style: AppText.jakarta(
            fontWeight: FontWeight.w800,
            color: CC.accent,
          ),
        ),
      );
    }
    final asset = persona?.avatarAsset;
    return CircleAvatar(
      radius: 22,
      backgroundColor: CC.cardSoft,
      backgroundImage: asset != null ? AssetImage(asset) : null,
    );
  }
}
