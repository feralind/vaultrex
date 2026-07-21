import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding.dart';
import '../dev/dev_studio.dart';
import '../dev/dev_studio_panel.dart';
import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'brand.dart';
import 'foil_slab.dart';
import 'game_widgets.dart';
import 'pack_peel_scrub.dart';
import 'pack_theater_v2.dart' show cardBackAssetForFranchise, resolvePackTheaterImageUrl;

Future<void> showPackTheater(
  BuildContext context,
  WidgetRef ref, {
  bool alreadyOpened = false,
  String? packImageUrl,
  String? packId,
}) async {
  final notifier = ref.read(gameProvider.notifier);
  final resolvedArt = resolvePackTheaterImageUrl(
    ref,
    packImageUrl: packImageUrl,
    packId: packId,
  );
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

  final art = resolvedArt ?? state.lastRipPackImageUrl;
  final cardBack = cardBackAssetForFranchise(state.franchiseId);

  // Skip network precache on Web — CanvasKit CORS decode spam (EncodingError).
  if (!kIsWeb) {
    for (final o in pulls) {
      final def = notifier.cardById(o.cardId);
      final url = def?.imageUrl ?? '';
      if (url.isEmpty) continue;
      // ignore: unawaited_futures
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  await showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, anim, secondary, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (dialogContext, anim, secondary) {
      return PackRipTheater(
        pulls: List<OwnedCard>.from(pulls),
        packImageUrl: art,
        cardBackAsset: cardBack,
        onDone: () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        },
      );
    },
  );
}

/// Frame map (reference Shorts samples):
/// sealed idle → center V peel → flaps clear → card back hold → Y-flip → settle.
enum _RipPhase { sealed, peeling, reveal }

class PackRipTheater extends ConsumerStatefulWidget {
  const PackRipTheater({
    super.key,
    required this.pulls,
    required this.onDone,
    this.packImageUrl,
    this.cardBackAsset,
  });

  final List<OwnedCard> pulls;
  final VoidCallback onDone;
  final String? packImageUrl;
  final String? cardBackAsset;

  @override
  ConsumerState<PackRipTheater> createState() => _PackRipTheaterState();
}

class _PackRipTheaterState extends ConsumerState<PackRipTheater>
    with TickerProviderStateMixin {
  _RipPhase _phase = _RipPhase.sealed;
  double _tear = 0;
  final PeelDragMapper _peelDrag = PeelDragMapper();
  int _cardIndex = 0;
  bool _flipped = false;
  bool _deciding = false;
  bool _glow = false;
  double _swipeDx = 0;
  int _keptCount = 0;
  int _presentGen = 0;
  bool _sessionBusy = false;
  bool _fastRip = false;
  Future<void>? _inFlightDecide;
  double _peelStartTear = 0;

  late final AnimationController _peelOut;
  late final AnimationController _flip;
  late final AnimationController _glowPulse;

  bool get _closeEnabled =>
      (_phase == _RipPhase.sealed || _phase == _RipPhase.reveal) &&
      !_sessionBusy &&
      _inFlightDecide == null;

  @override
  void initState() {
    super.initState();
    // ~frames 32–46 peel clear, 46–55 back hold, 55–70 flip (trimmed ~15%).
    _peelOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    OnboardingStore.isFastRip().then((v) {
      if (!mounted) return;
      setState(() {
        _fastRip = v;
        _flip.duration = Duration(milliseconds: v ? 180 : 340);
      });
    });
  }

  @override
  void dispose() {
    _presentGen++;
    _peelOut.dispose();
    _flip.dispose();
    _glowPulse.dispose();
    super.dispose();
  }

  OwnedCard get _current => widget.pulls[_cardIndex];

  bool _isGood(OwnedCard owned, CardDef? def, double fair) {
    if (def == null) return false;
    if (owned.foil && fair >= 5) return true;
    if (def.rarity.isRarePlus) return true;
    if (fair >= 8) return true;
    return false;
  }

  Future<void> _toggleFastRip() async {
    final next = !_fastRip;
    setState(() {
      _fastRip = next;
      _flip.duration = Duration(milliseconds: next ? 180 : 340);
    });
    await OnboardingStore.setFastRip(next);
  }

  void _onTearUpdate(DragUpdateDetails d) {
    if (_phase != _RipPhase.sealed || _sessionBusy) return;
    if (_fastRip) {
      setState(() => _tear = 1.0);
      unawaited(_openPack());
      return;
    }
    // Swipe top → bottom only (ignore upward / mostly-horizontal).
    final dy = d.delta.dy;
    if (dy <= 0) return;
    setState(() => _tear = _peelDrag.applyDelta(dy));
    if (_tear >= 1) unawaited(_openPack());
  }

  void _onTearEnd(DragEndDetails details) {
    if (_phase != _RipPhase.sealed || _sessionBusy) return;
    if (_fastRip) {
      unawaited(_openPack());
      return;
    }
    // Velocity settle — short inertia so scrub doesn't hard-stop mid-frame.
    final boosted =
        (_tear + _peelDrag.inertiaBoost(details)).clamp(0.0, 1.0);
    if (boosted > _tear) {
      setState(() => _tear = boosted);
    }
    if (_tear >= 0.72) {
      unawaited(_openPack());
    }
  }

  Future<void> _openPack() async {
    if (_phase != _RipPhase.sealed || _sessionBusy) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionBusy = true;
      _phase = _RipPhase.peeling;
      _tear = 0;
      _peelStartTear = 0;
    });

    if (_fastRip) {
      setState(() => _tear = 1.0);
    } else {
      _peelOut.duration = const Duration(milliseconds: 720);
      _peelOut
        ..removeListener(_onPeelOutTick)
        ..addListener(_onPeelOutTick);
      await _peelOut.forward(from: 0);
      _peelOut.removeListener(_onPeelOutTick);
      if (!mounted) return;
      setState(() => _tear = 1.0);
    }

    // Brief hold on last peel frame before card reveal.
    await Future<void>.delayed(
      Duration(milliseconds: _fastRip ? 40 : 140),
    );
    if (!mounted) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _phase = _RipPhase.reveal;
      _cardIndex = 0;
      _flipped = false;
      _deciding = false;
      _glow = false;
      _swipeDx = 0;
      _sessionBusy = false;
    });
    if (!mounted || _phase != _RipPhase.reveal) return;
    await _presentCard();
  }

  void _onPeelOutTick() {
    if (!mounted || _phase != _RipPhase.peeling) return;
    final t = Curves.easeInOutCubic.transform(_peelOut.value);
    setState(() => _tear = t);
  }

  Future<void> _presentCard() async {
    final gen = ++_presentGen;
    _flip.value = 0;
    setState(() {
      _flipped = false;
      _deciding = false;
      _glow = false;
      _swipeDx = 0;
      _sessionBusy = true;
    });
    final holdMs = _fastRip ? 0 : 220;
    if (holdMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: holdMs));
    }
    if (!mounted || gen != _presentGen || _phase != _RipPhase.reveal) return;
    await _flip.forward(from: 0);
    if (!mounted || gen != _presentGen) return;
    await _finishPresent(gen);
  }

  Future<void> _finishPresent(int gen) async {
    if (!mounted || gen != _presentGen || _phase != _RipPhase.reveal) return;
    if (_flipped || _deciding) return;
    final notifier = ref.read(gameProvider.notifier);
    final owned = _current;
    final def = notifier.cardById(owned.cardId);
    final fair = notifier.fairFor(owned);
    final good = _isGood(owned, def, fair);
    if (good) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
      setState(() => _glow = true);
      _glowPulse.forward(from: 0);
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _flipped = true;
      _deciding = true;
      _sessionBusy = false;
    });
  }

  /// Tap during flip jumps to decide.
  Future<void> _skipFlip() async {
    if (_phase != _RipPhase.reveal || _deciding || _flipped) return;
    final gen = _presentGen;
    _flip.stop();
    _flip.value = 1;
    await _finishPresent(gen);
  }

  Future<void> _decide({required bool keep}) async {
    if (!_deciding || _phase != _RipPhase.reveal || _inFlightDecide != null) {
      return;
    }
    setState(() {
      _deciding = false;
      _sessionBusy = true;
    });

    final notifier = ref.read(gameProvider.notifier);
    final owned = _current;

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

  Future<void> _closeOrKeepAll({required bool keepRemaining}) async {
    if (!_closeEnabled) return;
    _presentGen++;
    setState(() {
      _sessionBusy = true;
      _deciding = false;
    });
    if (_inFlightDecide != null) {
      try {
        await _inFlightDecide;
      } catch (_) {}
    }
    final notifier = ref.read(gameProvider.notifier);
    if (keepRemaining) {
      final ripLeft = ref.read(gameProvider).lastRip?.length ?? 0;
      await notifier.finalizeRip(keepRemaining: true);
      if (mounted && ripLeft > 0) {
        setState(() => _keptCount += ripLeft);
      }
    } else {
      await notifier.finalizeRip(keepRemaining: true);
    }
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(gameProvider.notifier);
    final candyBal = ref.watch(gameProvider.select((s) => s.player.candy));
    final inReveal = _phase == _RipPhase.reveal;

    return Material(
      color: CC.bg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    if (_phase == _RipPhase.sealed || inReveal)
                      IconButton(
                        tooltip: 'Keep remaining & close',
                        onPressed: _closeEnabled
                            ? () => _closeOrKeepAll(keepRemaining: true)
                            : null,
                        icon: const Icon(Icons.close_rounded),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: inReveal
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: CC.inkMuted,
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 24),
                                  height: 24,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: CC.candy,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                  ),
                                  child: Text(
                                    '$_keptCount',
                                    style: AppText.jakarta(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (inReveal || _phase == _RipPhase.sealed)
                      IconButton(
                        tooltip: _fastRip ? 'Fast rip on' : 'Fast rip off',
                        onPressed: _toggleFastRip,
                        icon: Icon(
                          Icons.bolt_rounded,
                          color: _fastRip ? CC.accent : CC.inkMuted,
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            Expanded(
              child: inReveal
                  ? _RevealStage(
                      pulls: widget.pulls,
                      cardIndex: _cardIndex,
                      def: notifier.cardById(_current.cardId),
                      fair: notifier.fairFor(_current),
                      flip: _flip,
                      flipped: _flipped,
                      glow: _glow,
                      glowAnim: _glowPulse,
                      swipeDx: _swipeDx,
                      deciding: _deciding,
                      onTapSkip: _skipFlip,
                      onHorizontalDragUpdate: (d) {
                        if (!_deciding) return;
                        setState(() =>
                            _swipeDx = (_swipeDx + d.delta.dx).clamp(-160.0, 160.0));
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
                    )
                  : ScrubPeelStage(
                      progress: _tear.clamp(0.0, 1.0),
                      showHint: _phase == _RipPhase.sealed && !_sessionBusy,
                      interactive: _phase == _RipPhase.sealed && !_sessionBusy,
                      packImageUrl: widget.packImageUrl,
                      cardBackAsset: widget.cardBackAsset ??
                          cardBackAssetForFranchise(
                            ref.read(gameProvider).franchiseId,
                          ),
                      onSwipeCommit: () => unawaited(_openPack()),
                    ),
            ),
            if (inReveal && _deciding)
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
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => _decide(keep: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CC.ink,
                            backgroundColor: CC.bgElevated,
                            side: BorderSide(
                              color: CC.line.withValues(alpha: 0.9),
                            ),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.center,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            '← Exchange',
                            style: AppText.jakarta(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: () => _decide(keep: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: CC.accent,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.center,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            'Keep →',
                            style: AppText.jakarta(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1,
                            ),
                          ),
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

/// Official card back art for face-down cards in theater.
class _CardBack extends StatelessWidget {
  const _CardBack({this.width = 200, this.height = 280});

  static const riftboundPath = 'assets/card_backs/riftbound_back.png';
  static const pokemonPath = 'assets/card_backs/pokemon_back.png';
  static const mtgPath = 'assets/card_backs/mtg_back.png';
  static const onepiecePath = 'assets/card_backs/onepiece_back.png';

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final franchise = refCatalogFranchise(context);
    final isPokemon = franchise == 'pokemon';
    final isMtg = franchise == 'mtg';
    final isOnePiece = franchise == 'onepiece';
    final rawPath = switch (franchise) {
      'pokemon' => pokemonPath,
      'mtg' => mtgPath,
      'onepiece' => onepiecePath,
      _ => riftboundPath,
    };

    return ListenableBuilder(
      listenable: DevStudio.instance,
      builder: (context, _) {
        final path = DevStudio.instance.resolveImage(rawPath);
        return GestureDetector(
          onLongPress: () =>
              devSelectImageSource(context, rawPath, label: 'Card back'),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: path.startsWith('http')
                  ? Image.network(
                      path,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _backFallback(
                        isPokemon: isPokemon,
                        isMtg: isMtg,
                        isOnePiece: isOnePiece,
                        width: width,
                      ),
                    )
                  : Image.asset(
                      path,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _backFallback(
                        isPokemon: isPokemon,
                        isMtg: isMtg,
                        isOnePiece: isOnePiece,
                        width: width,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _backFallback({
    required bool isPokemon,
    required bool isMtg,
    required bool isOnePiece,
    required double width,
  }) {
    return isPokemon
        ? ColoredBox(
            color: const Color(0xFF0D1B4C),
            child: Center(
              child: Text(
                'Pokémon',
                style: AppText.jakarta(
                  color: const Color(0xFFFFCB05),
                  fontWeight: FontWeight.w900,
                  fontSize: width * 0.16,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          )
        : ColoredBox(
            color: isMtg
                ? const Color(0xFF1A0A05)
                : isOnePiece
                    ? const Color(0xFF0A1628)
                    : const Color(0xFF0C1428),
            child: Center(
              child: Image.asset(
                isMtg
                    ? 'assets/logos/mtg.png'
                    : isOnePiece
                        ? 'assets/logos/onepiece.png'
                        : 'assets/logos/riftbound.png',
                width: width * 0.55,
                height: width * 0.28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    RiftMark(size: width * 0.42, framed: false),
              ),
            ),
          );
  }
}

/// Reads franchise id from the active game notifier when available.
String refCatalogFranchise(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(gameProvider.notifier).catalog.gameId;
  } catch (_) {
    return 'riftbound';
  }
}

/// Reads franchise from the active game notifier when available.
bool refCatalogIsPokemon(BuildContext context) =>
    refCatalogFranchise(context) == 'pokemon';

Color _ambientFor(Rarity? rarity, {bool foil = false}) {
  if (foil) return const Color(0xFFFBBF24);
  return switch (rarity) {
    Rarity.epic || Rarity.showcase || Rarity.ultimate || Rarity.signature =>
      const Color(0xFFA78BFA),
    Rarity.rare || Rarity.overnumbered => const Color(0xFF60A5FA),
    Rarity.uncommon => const Color(0xFF34D399),
    _ => const Color(0xFF64748B),
  };
}

class _RevealStage extends StatelessWidget {
  const _RevealStage({
    required this.pulls,
    required this.cardIndex,
    required this.def,
    required this.fair,
    required this.flip,
    required this.flipped,
    required this.glow,
    required this.glowAnim,
    required this.swipeDx,
    required this.deciding,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    this.onTapSkip,
  });

  final List<OwnedCard> pulls;
  final int cardIndex;
  final CardDef? def;
  final double fair;
  final AnimationController flip;
  final bool flipped;
  final bool glow;
  final Animation<double> glowAnim;
  final double swipeDx;
  final bool deciding;
  final VoidCallback? onTapSkip;
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;
  final void Function(DragEndDetails) onHorizontalDragEnd;

  OwnedCard get owned => pulls[cardIndex];

  @override
  Widget build(BuildContext context) {
    final artUrl = def?.imageUrl ?? '';
    final ambient = _ambientFor(def?.rarity, foil: owned.foil);

    return GestureDetector(
      onTap: deciding ? null : onTapSkip,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([flip, glowAnim]),
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(flip.value);
          final angle = t * math.pi;
          final showFront = angle >= math.pi / 2;
          final displayAngle = showFront ? angle - math.pi : angle;
          final pulse = glow
              ? (0.35 + 0.3 * math.sin(glowAnim.value * math.pi * 2))
              : 0.0;
          final keepHint = swipeDx > 24;
          final exchangeHint = swipeDx < -24;

          return LayoutBuilder(
            builder: (context, constraints) {
              // Rare Candy–style face-on framing (not edge-to-edge zoomed).
              final aspect = def?.artAspectRatio ?? (2.5 / 3.5);
              final maxH = math.min(
                constraints.maxHeight * 0.58,
                constraints.maxWidth *
                    (def?.isLandscapeCard == true ? 0.78 : 1.05),
              );
              final maxW = constraints.maxWidth *
                  (def?.isLandscapeCard == true ? 0.82 : 0.58);
              var cardW = maxW;
              var cardH = cardW / aspect;
              if (cardH > maxH) {
                cardH = maxH;
                cardW = cardH * aspect;
              }

              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.12),
                          radius: 1.0,
                          colors: [
                            ambient.withValues(
                              alpha: showFront ? 0.38 + pulse * 0.2 : 0.18,
                            ),
                            CC.bg.withValues(alpha: 0.25),
                            CC.bg,
                          ],
                          stops: const [0.0, 0.48, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _ActiveLineup(
                              remaining: pulls.length - cardIndex,
                              cardW: cardW,
                              cardH: cardH,
                              swipeDx: swipeDx,
                              ambient: ambient,
                              pulse: pulse,
                              displayAngle: displayAngle,
                              showFront: showFront,
                              owned: owned,
                              artUrl: artUrl,
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: flipped ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  def?.name ?? 'Card',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.jakarta(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    height: 1.2,
                                  ),
                                ),
                                if (def case final d?) ...[
                                  if (d.setName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      d.setName,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.jakarta(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: CC.inkMuted,
                                      ),
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 8),
                                if (def?.isUnlisted == true) ...[
                                  Text(
                                    'Not on market yet · Speculative value',
                                    textAlign: TextAlign.center,
                                    style: AppText.jakarta(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: CC.accentHot,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Exchange for ',
                                      style: AppText.jakarta(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: CC.inkMuted,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: CC.candy,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(fair * 100).round()}',
                                      style: AppText.jakarta(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: CC.candy,
                                      ),
                                    ),
                                  ],
                                ),
                                if (deciding) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    keepHint
                                        ? 'Release to Keep'
                                        : exchangeHint
                                            ? 'Release to Exchange'
                                            : 'Swipe left or right',
                                    style: AppText.jakarta(
                                      color: keepHint
                                          ? CC.accent
                                          : exchangeHint
                                              ? CC.candy
                                              : CC.inkMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ] else if (!flipped) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Tap to skip flip',
                                    style: AppText.jakarta(
                                      color: CC.inkMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ActiveLineup extends StatelessWidget {
  const _ActiveLineup({
    required this.remaining,
    required this.cardW,
    required this.cardH,
    required this.swipeDx,
    required this.ambient,
    required this.pulse,
    required this.displayAngle,
    required this.showFront,
    required this.owned,
    required this.artUrl,
  });

  final int remaining;
  final double cardW;
  final double cardH;
  final double swipeDx;
  final Color ambient;
  final double pulse;
  final double displayAngle;
  final bool showFront;
  final OwnedCard owned;
  final String artUrl;

  @override
  Widget build(BuildContext context) {
    final waiting = math.max(0, remaining - 1);
    final peekCount = math.min(waiting, 5);

    return SizedBox(
      width: cardW + 20,
      height: cardH + peekCount * 7.0 + 12,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var i = peekCount; i >= 1; i--)
            Transform.translate(
              offset: Offset(0, -i * 6.0),
              child: Opacity(
                opacity: (0.9 - i * 0.08).clamp(0.45, 0.92),
                child: _CardBack(width: cardW, height: cardH),
              ),
            ),
          Transform.translate(
            offset: Offset(swipeDx * 0.45, 0),
            child: Transform.rotate(
              angle: swipeDx / 480,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: ambient.withValues(alpha: 0.3 + pulse * 0.22),
                      blurRadius: 28 + pulse * 14,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0016 / (cardW / 200))
                    ..rotateY(displayAngle),
                  child: showFront
                      ? FoilChromatic(
                          enabled: owned.foil,
                          intensity: 0.78,
                          autoPlay: true,
                          child: CardArt(
                            url: artUrl,
                            width: cardW,
                            height: cardH,
                            foil: false,
                            radius: 16,
                          ),
                        )
                      : _CardBack(width: cardW, height: cardH),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
