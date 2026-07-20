import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/rival_personas.dart';
import '../../game/game_controller.dart';
import '../../game/rival_sim.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import 'rival_profile_screen.dart';

class AuctionPitScreen extends ConsumerStatefulWidget {
  const AuctionPitScreen({super.key, this.focusRivalId});

  final String? focusRivalId;

  @override
  ConsumerState<AuctionPitScreen> createState() => _AuctionPitScreenState();
}

class _AuctionPitScreenState extends ConsumerState<AuctionPitScreen> {
  String? _focusId;
  int _tick = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final auctions = state.auctions;
    if (!state.ready) {
      return const Scaffold(
        backgroundColor: CC.bg,
        body: Center(child: CircularProgressIndicator(color: CC.accent)),
      );
    }

    if (auctions.isEmpty) {
      return Scaffold(
        backgroundColor: CC.bg,
        appBar: AppBar(
          title: Text('Auction Pit', style: AppText.jakarta(fontWeight: FontWeight.w800)),
          backgroundColor: CC.bg,
        ),
        body: Center(
          child: Text(
            'No live lots — Advance Day to restock.',
            style: AppText.jakarta(color: CC.inkMuted),
          ),
        ),
      );
    }

    _focusId ??= auctions.first.id;
    // Prefer lot matching focusRivalId when opening from a rival profile.
    if (widget.focusRivalId != null && _focusId == auctions.first.id) {
      final match = auctions.where((a) {
        final r = rivalByHandle(a.rivalName ?? '');
        return r?.id == widget.focusRivalId;
      });
      if (match.isNotEmpty) _focusId = match.first.id;
    }
    final focus = auctions.firstWhere(
      (a) => a.id == _focusId,
      orElse: () => auctions.first,
    );
    final def = notifier.cardById(focus.cardId);
    RivalPersona high = rivalByHandle(focus.rivalName ?? '') ??
        rivalByIndex(focus.id.hashCode);
    if (widget.focusRivalId != null) {
      high = rivalById(widget.focusRivalId!) ?? high;
    }

    final secsLeft = (focus.endsInTurns * 18 - (_tick % 18)).clamp(0, 99);
    final feed = RivalSim.pitFeedFor(
      highBidder: focus.playerIsHighBidder ? null : high,
      cardName: def?.name ?? focus.cardId,
      bid: focus.currentBid,
      endsInTurns: focus.endsInTurns,
    );

    final inPit = <RivalPersona>[
      high,
      rivalByIndex(focus.id.hashCode + 1),
      rivalByIndex(focus.id.hashCode + 2),
    ];

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text('Auction Pit', style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: auctions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final a = auctions[i];
                final d = notifier.cardById(a.cardId);
                final selected = a.id == focus.id;
                return InkWell(
                  onTap: () => setState(() => _focusId = a.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? CC.accent.withValues(alpha: 0.15)
                          : CC.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? CC.accent : CC.line,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d?.name ?? a.cardId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${a.currentBid.toStringAsFixed(2)} · ${a.endsInTurns}d',
                          style: AppText.jakarta(
                            color: CC.inkMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (def != null)
                  AspectRatio(
                    aspectRatio: 0.72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: def.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  def?.name ?? 'Lot',
                  style: AppText.jakarta(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  [
                    if (focus.foil) 'Foil',
                    focus.condition.name,
                    if (def != null) def.rarity.name,
                  ].join(' · '),
                  style: AppText.jakarta(color: CC.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        focus.playerIsHighBidder
                            ? 'You lead \$${focus.currentBid.toStringAsFixed(2)}'
                            : '${high.handle} · \$${focus.currentBid.toStringAsFixed(2)}',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF87171).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'CLOSES ~0:${secsLeft.toString().padLeft(2, '0')}',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: const Color(0xFFFCA5A5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'In the Pit',
                  style: AppText.jakarta(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in inPit)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RivalProfileScreen(personaId: p.id),
                          ),
                        ),
                        child: Chip(
                          avatar: CircleAvatar(
                            backgroundImage: AssetImage(p.avatarAsset),
                          ),
                          label: Text(p.handle),
                          backgroundColor: CC.card,
                          side: BorderSide(color: CC.line),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                ...feed.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '· $line',
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await notifier.bidAuction(focus.id);
                    if (!mounted) return;
                    final msg = ref.read(gameProvider).message;
                    if (msg != null) {
                      messenger.showSnackBar(SnackBar(content: Text(msg)));
                    }
                    setState(() {});
                  },
                  child: Text(
                    'Place bid · \$${(focus.currentBid + focus.minIncrement).toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
