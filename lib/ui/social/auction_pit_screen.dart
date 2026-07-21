import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/rival_personas.dart';
import '../../game/game_controller.dart';
import '../../game/rival_sim.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
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
  final List<String> _liveFeed = [];
  String? _lastFeedKey;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!mounted) return;
      final notifier = ref.read(gameProvider.notifier);
      unawaited(notifier.tickAuctionsLive());

      // Rival nudges ~every 2.45s.
      if (_tick > 0 && _tick % 7 == 0) {
        final auctions = ref.read(gameProvider).auctions;
        for (final a in auctions) {
          notifier.nudgeAuctionRival(a.id);
        }
      }

      final state = ref.read(gameProvider);
      if (state.auctions.isNotEmpty) {
        final focus = state.auctions.firstWhere(
          (a) => a.id == _focusId,
          orElse: () => state.auctions.first,
        );
        final def = notifier.cardById(focus.cardId);
        final high = focus.playerIsHighBidder
            ? null
            : (rivalByHandle(focus.rivalName ?? '') ??
                rivalByIndex(focus.id.hashCode));
        final secs = _secsLeft(focus.endsAtMs);
        _pushFeed(
          RivalSim.pitFeedFor(
            highBidder: high,
            cardName: def?.name ?? focus.cardId,
            bid: focus.currentBid,
            endsInTurns: focus.endsInTurns,
            secsLeft: secs,
            paddleCount: 6,
          ),
        );
      }

      setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _secsLeft(int? endsAtMs) {
    if (endsAtMs == null) return 15;
    final left =
        ((endsAtMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    return left.clamp(0, 99);
  }

  void _pushFeed(List<String> lines) {
    final key = lines.join('|');
    if (key == _lastFeedKey) return;
    _lastFeedKey = key;
    for (final line in lines.reversed) {
      _liveFeed.insert(0, line);
    }
    while (_liveFeed.length > 12) {
      _liveFeed.removeLast();
    }
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
          title: const Text('Auction Pit'),
          backgroundColor: CC.bg,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Auction Pit', style: AppText.display()),
                const SizedBox(height: AppSpace.s8),
                Text(
                  'No live lots right now.\nAdvance Day to restock the floor.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySm(),
                ),
              ],
            ),
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
    if (!auctions.any((a) => a.id == _focusId)) {
      _focusId = auctions.first.id;
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

    final secsLeft = _secsLeft(focus.endsAtMs);
    final inPit = <RivalPersona>[
      high,
      rivalByIndex(focus.id.hashCode + 1),
      rivalByIndex(focus.id.hashCode + 2),
      rivalByIndex(focus.id.hashCode + 3),
      rivalByIndex(focus.id.hashCode + 4),
      rivalByIndex(focus.id.hashCode + 5),
    ];

    final feed = RivalSim.pitFeedFor(
      highBidder: focus.playerIsHighBidder ? null : high,
      cardName: def?.name ?? focus.cardId,
      bid: focus.currentBid,
      endsInTurns: focus.endsInTurns,
      secsLeft: secsLeft,
      paddleCount: inPit.length,
    );

    final urgent = secsLeft <= 5;

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: const Text('Auction Pit'),
        backgroundColor: CC.bg,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s16,
              AppSpace.s4,
              AppSpace.s16,
              AppSpace.s8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ScreenTitle(
                    'Auction Pit',
                    subtitle:
                        '${auctions.length} live lot${auctions.length == 1 ? '' : 's'} · hammer clock running',
                  ),
                ),
                BalanceBar(
                  candy: state.player.candy,
                  cash: state.player.cash,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
              itemCount: auctions.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s8),
              itemBuilder: (context, i) {
                final a = auctions[i];
                final d = notifier.cardById(a.cardId);
                final selected = a.id == focus.id;
                final lotSecs = _secsLeft(a.endsAtMs);
                return InkWell(
                  onTap: () => setState(() => _focusId = a.id),
                  borderRadius: BorderRadius.circular(AppSpace.rCard),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(AppSpace.s12),
                    decoration: BoxDecoration(
                      color: selected
                          ? CC.accent.withValues(alpha: 0.15)
                          : CC.card,
                      borderRadius: BorderRadius.circular(AppSpace.rCard),
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
                          style: AppText.titleSm().copyWith(fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '\$${a.currentBid.toStringAsFixed(2)} · ${lotSecs}s',
                          style: AppText.label(
                            color: lotSecs <= 5
                                ? const Color(0xFFFCA5A5)
                                : CC.inkMuted,
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
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s16,
                AppSpace.s12,
                AppSpace.s16,
                24,
              ),
              children: [
                if (def != null)
                  AspectRatio(
                    aspectRatio: 0.72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpace.rCard),
                      child: CachedNetworkImage(
                        imageUrl: def.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpace.s12),
                Text(
                  def?.name ?? 'Lot',
                  style: AppText.display().copyWith(fontSize: 24),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  [
                    if (focus.foil) 'Foil',
                    focus.condition.name,
                    if (def != null) def.rarity.name,
                  ].join(' · '),
                  style: AppText.bodySm(),
                ),
                const SizedBox(height: AppSpace.s12),
                Container(
                  padding: const EdgeInsets.all(AppSpace.s16),
                  decoration: BoxDecoration(
                    color: CC.card,
                    borderRadius: BorderRadius.circular(AppSpace.rCard),
                    border: Border.all(color: CC.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('High bid', style: AppText.label()),
                            const SizedBox(height: AppSpace.s4),
                            Text(
                              focus.playerIsHighBidder
                                  ? 'You lead'
                                  : high.handle,
                              style: AppText.titleSm(),
                            ),
                            Text(
                              '\$${focus.currentBid.toStringAsFixed(2)}',
                              style: AppText.tabular(
                                color: CC.cash,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s12,
                          vertical: AppSpace.s12,
                        ),
                        decoration: BoxDecoration(
                          color: urgent
                              ? const Color(0xFF7F1D1D).withValues(alpha: 0.55)
                              : const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                          borderRadius:
                              BorderRadius.circular(AppSpace.rChip),
                          border: Border.all(
                            color: const Color(0xFFF87171)
                                .withValues(alpha: urgent ? 0.85 : 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              urgent ? 'HAMMER' : '15s HAMMER',
                              style: AppText.label(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            Text(
                              '0:${secsLeft.toString().padLeft(2, '0')}',
                              style: AppText.tabular(
                                color: const Color(0xFFFCA5A5),
                                fontSize: urgent ? 22 : 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                Text('In the Pit', style: AppText.titleSm()),
                const SizedBox(height: AppSpace.s8),
                Wrap(
                  spacing: AppSpace.s8,
                  runSpacing: AppSpace.s8,
                  children: [
                    for (final p in inPit)
                      AppChip(
                        label: p.handle,
                        compact: true,
                        leading: CircleAvatar(
                          radius: 10,
                          backgroundImage: AssetImage(p.avatarAsset),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RivalProfileScreen(personaId: p.id),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.s16),
                Text('Floor chatter', style: AppText.titleSm()),
                const SizedBox(height: AppSpace.s8),
                Container(
                  padding: const EdgeInsets.all(AppSpace.s12),
                  decoration: BoxDecoration(
                    color: CC.card,
                    borderRadius: BorderRadius.circular(AppSpace.rCard),
                    border: Border.all(color: CC.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...(_liveFeed.isEmpty ? feed : _liveFeed).take(8).map(
                            (line) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpace.s8),
                              child: Text(
                                '· $line',
                                style: AppText.bodySm(),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: CC.accent,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpace.s16,
                      horizontal: AppSpace.s24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpace.rCard),
                    ),
                  ),
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
