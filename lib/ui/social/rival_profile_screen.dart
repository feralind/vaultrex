import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/rival_personas.dart';
import '../../game/game_controller.dart';
import '../../game/rival_sim.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import 'auction_pit_screen.dart';

class RivalProfileScreen extends ConsumerWidget {
  const RivalProfileScreen({super.key, required this.personaId});

  final String personaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = rivalById(personaId);
    if (persona == null) {
      return Scaffold(
        backgroundColor: CC.bg,
        appBar: AppBar(backgroundColor: CC.bg),
        body: Center(
          child: Text('Rival not found', style: AppText.jakarta(color: CC.inkMuted)),
        ),
      );
    }

    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final showcase = state.ready
        ? RivalSim.showcaseFor(persona, notifier.catalog)
        : const <RivalShowcaseCard>[];
    final board = RivalSim.buildBoard(
      playerValue: state.ready ? notifier.totalCollectionValue() : 0,
      businessLevel: state.player.businessLevel,
      metric: RivalBoardMetric.binder,
      playerCardsSold: state.player.cardsSold,
      playerGemsPulled: state.player.gemsPulled,
    );
    RivalBoardEntry? entry;
    for (final e in board) {
      if (e.persona?.id == persona.id) {
        entry = e;
        break;
      }
    }

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text(persona.handle, style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(persona.avatarAsset),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.title,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      persona.quirk,
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in persona.personality) _chip(tag),
                        if (entry != null) _chip(entry.status.label, hot: true),
                        if (entry != null)
                          _chip('#${entry.rank} binder · ${entry.scoreLabel}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _askToBuy(context, ref, persona),
                  child: const Text('Ask to buy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AuctionPitScreen(focusRivalId: persona.id),
                    ),
                  ),
                  child: const Text('Watch in Pit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Showcase collection',
            style: AppText.jakarta(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(
            'Seeded flavor inventory — appreciate, don\'t steal.',
            style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: showcase.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, i) {
              final c = showcase[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: c.def.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.def.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.jakarta(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    [
                      if (c.foil) 'foil',
                      if (c.graded) 'PSA ${c.grade?.toStringAsFixed(0) ?? '?'}',
                      if (!c.graded) c.condition.name,
                    ].join(' · '),
                    style: AppText.jakarta(color: CC.inkMuted, fontSize: 9),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _askToBuy(
    BuildContext context,
    WidgetRef ref,
    RivalPersona persona,
  ) async {
    final notifier = ref.read(gameProvider.notifier);
    final available = ref
        .read(gameProvider)
        .collection
        .where((c) => c.listedAsk == null)
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${persona.handle} has nothing free to buy from you.'),
        ),
      );
      return;
    }
    available.sort((a, b) => notifier.fairFor(b).compareTo(notifier.fairFor(a)));
    final card = available.first;
    final fair = notifier.fairFor(card);
    final offer = fair * persona.fairBias;
    final def = notifier.cardById(card.cardId);
    final name = def?.name ?? card.cardId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CC.card,
        title: Text(
          '${persona.handle} offers',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Buy your $name for \$${offer.toStringAsFixed(2)} '
          '(${(persona.fairBias * 100).round()}% of fair).\n\n${persona.quirk}',
          style: AppText.jakarta(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sell'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = await notifier.rivalAskToBuy(persona.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ??
              ref.read(gameProvider).message ??
              'Sold to ${persona.handle}.',
        ),
      ),
    );
  }

  Widget _chip(String label, {bool hot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (hot ? CC.accent : CC.line).withValues(alpha: hot ? 0.2 : 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppText.jakarta(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: hot ? CC.accent : CC.inkMuted,
        ),
      ),
    );
  }
}
