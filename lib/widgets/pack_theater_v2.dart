import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding.dart';
import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'brand.dart';
import 'foil_slab.dart';
import 'game_widgets.dart';

Future<void> showPackTheaterV2(
  BuildContext context,
  WidgetRef ref, {
  bool alreadyOpened = false,
  String? packImageUrl,
  String? packId,
}) async {
  final notifier = ref.read(gameProvider.notifier);
  if (!alreadyOpened) {
    try {
      final opened = await notifier.openPack(packId: packId);
      if (!opened) {
        if (!context.mounted) return;
        final msg = ref.read(gameProvider).message ??
            'Could not open pack — try again.';
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Could not open pack: $e')),
      );
      return;
    }
  }
  if (!context.mounted) return;
  final state = ref.read(gameProvider);
  final pulls = state.lastRip;
  if (pulls == null || pulls.isEmpty) {
    final msg = state.message ?? 'Pack opened with no cards — try again.';
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(msg)),
    );
    return;
  }

  for (final o in pulls) {
    final def = notifier.cardById(o.cardId);
    final url = def?.imageUrl ?? '';
    if (url.isEmpty) continue;
    // ignore: unawaited_futures
    precacheImage(CachedNetworkImageProvider(url), context);
  }

  await showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, anim, secondary, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: child,
      );
    },
    pageBuilder: (dialogContext, anim, secondary) {
      return PackRipTheaterV2(
        pulls: List<OwnedCard>.from(pulls),
        packImageUrl: packImageUrl,
        onDone: () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        },
      );
    },
  );
}

enum _RipPhaseV2 { sealed, ripping, lineup, deciding }

class PackRipTheaterV2 extends ConsumerStatefulWidget {
  const PackRipTheaterV2({
    super.key,
    required this.pulls,
    required this.onDone,
    this.packImageUrl,
  });

  final List<OwnedCard> pulls;
  final VoidCallback onDone;
  final String? packImageUrl;

  @override
  ConsumerState<PackRipTheaterV2> createState() => _PackRipTheaterV2State();
}

class _PackRipTheaterV2State extends ConsumerState<PackRipTheaterV2>
    with TickerProviderStateMixin {
  late final AnimationController _sealedTilt;
  late final AnimationController _ripPeel;
  late final AnimationController _cardTumble;
  late final AnimationController _revealFlip;
  late final AnimationController _glowPulse;

  _RipPhaseV2 _phase = _RipPhaseV2.sealed;
  int _cardIndex = 0;
  int _tumblingCardCount = 0;
  bool _deciding = false;
  bool _sessionBusy = false;
  double _swipeDx = 0;
  int _keptCount = 0;
  bool _fastMode = false;
  Future<void>? _inFlightDecide;

  final List<_TumblingCard> _tumblingCards = [];

  @override
  void initState() {
    super.initState();
    _sealedTilt = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _ripPeel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardTumble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _revealFlip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    OnboardingStore.isFastRip().then((v) {
      if (!mounted) return;
      setState(() => _fastMode = v);
    });
  }

  @override
  void dispose() {
    _sealedTilt.dispose();
    _ripPeel.dispose();
    _cardTumble.dispose();
    _revealFlip.dispose();
    _glowPulse.dispose();
    super.dispose();
  }

  OwnedCard get _currentCard => widget.pulls[_cardIndex];

  bool _isHit(OwnedCard owned, CardDef? def, double fair) {
    if (def == null) return false;
    if (owned.foil && fair >= 5) return true;
    if (def.rarity.isRarePlus) return true;
    if (fair >= 8) return true;
    return false;
  }

  Future<void> _ripPack() async {
    if (_phase != _RipPhaseV2.sealed || _sessionBusy) return;

    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);

    setState(() {
      _phase = _RipPhaseV2.ripping;
      _sessionBusy = true;
    });

    // Peel animation
    await _ripPeel.forward(from: 0);
    if (!mounted) return;

    // Generate tumbling cards
    _generateTumblingCards();

    // Tumble animation
    _cardTumble.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _phase = _RipPhaseV2.lineup;
      _cardIndex = 0;
      _sessionBusy = false;
      _tumblingCards.clear();
    });

    await _presentCard();
  }

  void _generateTumblingCards() {
    _tumblingCards.clear();
    for (var i = 0; i < widget.pulls.length; i++) {
      _tumblingCards.add(
        _TumblingCard(
          index: i,
          startX: 0,
          startY: -200,
          endX: (i.toDouble() - (widget.pulls.length / 2)) * 40,
          endY: 100,
          rotation: (math.pi * 2 * (i % 3)),
          delay: Duration(milliseconds: 100 * i),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  Future<void> _presentCard() async {
    if (_phase != _RipPhaseV2.lineup) return;

    setState(() {
      _deciding = false;
      _sessionBusy = true;
    });

    _revealFlip.forward(from: 0);
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final notifier = ref.read(gameProvider.notifier);
    final owned = _currentCard;
    final def = notifier.cardById(owned.cardId);
    final fair = notifier.fairFor(owned);
    final isHit = _isHit(owned, def, fair);

    if (isHit) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
      _glowPulse.forward(from: 0);
    }

    setState(() {
      _deciding = true;
      _sessionBusy = false;
    });
  }

  Future<void> _decide({required bool keep}) async {
    if (!_deciding || _phase != _RipPhaseV2.lineup) return;

    setState(() {
      _deciding = false;
      _sessionBusy = true;
    });

    final notifier = ref.read(gameProvider.notifier);
    final owned = _currentCard;

    final op = () async {
      await notifier.decideRipCard(owned.instanceId, keep: keep);
      if (keep) {
        HapticFeedback.lightImpact();
        if (mounted) setState(() => _keptCount += 1);
      } else {
        HapticFeedback.mediumImpact();
      }

      if (!mounted) return;
      if (_cardIndex < widget.pulls.length - 1) {
        setState(() {
          _cardIndex += 1;
          _sessionBusy = false;
          _revealFlip.reset();
        });
        await _presentCard();
      } else {
        await notifier.finalizeRip(keepRemaining: false);
        if (!mounted) return;
        widget.onDone();
      }
    }();

    _inFlightDecide = op;
    try {
      await op;
    } finally {
      _inFlightDecide = null;
    }
  }

  Future<void> _keepAll() async {
    if (_sessionBusy) return;

    setState(() => _sessionBusy = true);
    if (_inFlightDecide != null) {
      try {
        await _inFlightDecide;
      } catch (_) {}
    }
    final notifier = ref.read(gameProvider.notifier);
    final ripLeft = ref.read(gameProvider).lastRip?.length ?? 0;
    await notifier.finalizeRip(keepRemaining: true);
    if (mounted && ripLeft > 0) {
      setState(() => _keptCount += ripLeft);
    }
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(gameProvider.notifier);
    final candyBal = ref.watch(gameProvider.select((s) => s.player.candy));
    final inDeciding = _phase == _RipPhaseV2.deciding || _phase == _RipPhaseV2.lineup;

    return Material(
      color: CC.bg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: (_sessionBusy || _inFlightDecide != null)
                          ? null
                          : _keepAll,
                    ),
                    const Spacer(),
                    if (inDeciding)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CC.candy.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CC.candy, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: CC.candy,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_keptCount',
                              style: AppText.jakarta(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CC.candy,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.bolt_rounded,
                        color: _fastMode ? CC.accent : CC.inkMuted,
                      ),
                      onPressed: () async {
                        final next = !_fastMode;
                        setState(() => _fastMode = next);
                        await OnboardingStore.setFastRip(next);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _phase == _RipPhaseV2.sealed
                  ? _SealedStage(
                      packImageUrl: widget.packImageUrl,
                      tiltAnim: _sealedTilt,
                      onTap: _ripPack,
                    )
                  : _phase == _RipPhaseV2.ripping
                      ? _RippingStage(
                          ripAnim: _ripPeel,
                          packImageUrl: widget.packImageUrl,
                        )
                      : _RevealLineupV2(
                          currentCard: _currentCard,
                          cardDef: notifier.cardById(_currentCard.cardId),
                          fair: notifier.fairFor(_currentCard),
                          revealAnim: _revealFlip,
                          glowAnim: _glowPulse,
                          swipeDx: _swipeDx,
                          deciding: _deciding,
                          cardIndex: _cardIndex,
                          totalCards: widget.pulls.length,
                          isHit: _isHit(
                            _currentCard,
                            notifier.cardById(_currentCard.cardId),
                            notifier.fairFor(_currentCard),
                          ),
                          onHorizontalDragUpdate: (d) {
                            if (!_deciding) return;
                            setState(() => _swipeDx =
                                (_swipeDx + d.delta.dx).clamp(-160.0, 160.0));
                          },
                          onHorizontalDragEnd: (d) {
                            if (!_deciding) return;
                            final v = d.primaryVelocity ?? 0;
                            if (_swipeDx > 80 || v > 600) {
                              _decide(keep: true);
                            } else if (_swipeDx < -80 || v < -600) {
                              _decide(keep: false);
                            } else {
                              setState(() => _swipeDx = 0);
                            }
                          },
                        ),
            ),
            if (inDeciding && _deciding)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CandyBalance(candyBal),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _decide(keep: false),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Exchange'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _decide(keep: true),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Keep'),
                            style: FilledButton.styleFrom(
                              backgroundColor: CC.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Sealed pack with tilt effect
class _SealedStage extends StatelessWidget {
  const _SealedStage({
    required this.packImageUrl,
    required this.tiltAnim,
    required this.onTap,
  });

  final String? packImageUrl;
  final AnimationController tiltAnim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: tiltAnim,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(tiltAnim.value);
          final angle = (t - 0.5) * 0.1;

          return Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(angle)
                ..rotateZ(angle * 0.5),
              child: Stack(
                children: [
                  Container(
                    width: 200,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: packImageUrl != null
                          ? Image.network(
                              packImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: Color(0xFF1a1a2e)),
                            )
                          : const ColoredBox(color: Color(0xFF1a1a2e)),
                    ),
                  ),
                  // Shine effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.1 + t * 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Ripping animation
class _RippingStage extends StatelessWidget {
  const _RippingStage({
    required this.ripAnim,
    required this.packImageUrl,
  });

  final AnimationController ripAnim;
  final String? packImageUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ripAnim,
      builder: (context, _) {
        final t = ripAnim.value;
        final peelHeight = 100 * t;
        final gapHeight = 20 * t;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top flap
              Transform.rotate(
                angle: -t * 0.5,
                child: Container(
                  width: 200,
                  height: peelHeight.clamp(0, 100),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: packImageUrl != null
                        ? Image.network(
                            packImageUrl!,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : const ColoredBox(color: Color(0xFF1a1a2e)),
                  ),
                ),
              ),
              SizedBox(height: gapHeight.clamp(0, 20)),
              // Bottom (closed) pack
              Container(
                width: 200,
                height: 280 - peelHeight.clamp(0, 100),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: packImageUrl != null
                      ? Image.network(
                          packImageUrl!,
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                        )
                      : const ColoredBox(color: Color(0xFF1a1a2e)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Reveal & flip animation
class _RevealLineupV2 extends StatelessWidget {
  const _RevealLineupV2({
    required this.currentCard,
    required this.cardDef,
    required this.fair,
    required this.revealAnim,
    required this.glowAnim,
    required this.swipeDx,
    required this.deciding,
    required this.cardIndex,
    required this.totalCards,
    required this.isHit,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
  });

  final OwnedCard currentCard;
  final CardDef? cardDef;
  final double fair;
  final AnimationController revealAnim;
  final AnimationController glowAnim;
  final double swipeDx;
  final bool deciding;
  final int cardIndex;
  final int totalCards;
  final bool isHit;
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;
  final void Function(DragEndDetails) onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    final artUrl = cardDef?.imageUrl ?? '';

    return GestureDetector(
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([revealAnim, glowAnim]),
        builder: (context, _) {
          final t = revealAnim.value;
          final angle = t * math.pi;
          final showFront = angle >= math.pi / 2;

          final pulse = isHit
              ? (0.3 + 0.2 * math.sin(glowAnim.value * math.pi * 2))
              : 0.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background glow
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        (isHit ? CC.accentHot : CC.inkMuted)
                            .withValues(alpha: showFront ? 0.25 + pulse * 0.15 : 0.08),
                        CC.bg,
                      ],
                    ),
                  ),
                ),
              ),
              // Card + swipe transform
              Center(
                child: Transform.translate(
                  offset: Offset(swipeDx, 0),
                  child: _FlipCard(
                    angle: angle,
                    showFront: showFront,
                    artUrl: artUrl,
                    cardDef: cardDef,
                    currentCard: currentCard,
                    isHit: isHit,
                    pulse: pulse,
                  ),
                ),
              ),
              // Info panel
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: showFront ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cardDef?.name ?? 'Card',
                        textAlign: TextAlign.center,
                        style: AppText.jakarta(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (cardDef?.setName.isNotEmpty == true)
                        Text(
                          cardDef!.setName,
                          style: AppText.jakarta(
                            fontSize: 13,
                            color: CC.inkMuted,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Card ${cardIndex + 1} of $totalCards',
                        style: AppText.jakarta(
                          fontSize: 12,
                          color: CC.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.angle,
    required this.showFront,
    required this.artUrl,
    required this.cardDef,
    required this.currentCard,
    required this.isHit,
    required this.pulse,
  });

  final double angle;
  final bool showFront;
  final String artUrl;
  final CardDef? cardDef;
  final OwnedCard currentCard;
  final bool isHit;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final displayAngle = showFront ? angle - math.pi : angle;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(displayAngle),
      child: Container(
        width: 220,
        height: 310,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isHit
                  ? CC.accentHot.withValues(alpha: 0.4 + pulse * 0.2)
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: 30 + pulse * 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!showFront)
                Container(
                  color: const Color(0xFF0C1428),
                  child: Center(
                    child: Image.asset(
                      'assets/logos/riftbound_wordmark.png',
                      width: 100,
                      opacity: const AlwaysStoppedAnimation(0.3),
                    ),
                  ),
                )
              else
                CachedNetworkImage(
                  imageUrl: artUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF0C1428)),
                ),
              if (showFront && isHit)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            CC.accentHot.withValues(alpha: pulse * 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TumblingCard {
  _TumblingCard({
    required this.index,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
    required this.delay,
    required this.duration,
  });

  final int index;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;
  final Duration delay;
  final Duration duration;
}
