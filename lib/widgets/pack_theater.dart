import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'brand.dart';
import 'foil_slab.dart';
import 'game_widgets.dart';
import 'knockout_image.dart';

Future<void> showPackTheater(
  BuildContext context,
  WidgetRef ref, {
  bool alreadyOpened = false,
  String? packImageUrl,
  String? packId,
}) async {
  final notifier = ref.read(gameProvider.notifier);
  if (!alreadyOpened) {
    try {
      await notifier.openPack(packId: packId);
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

  // Preload the entire card stack art before the reveal phase (best-effort).
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
    barrierColor: Colors.black.withValues(alpha: 0.55),
    pageBuilder: (dialogContext, anim, secondary) {
      return FadeTransition(
        opacity: anim,
        child: PackRipTheater(
          pulls: List<OwnedCard>.from(pulls),
          packImageUrl: packImageUrl,
          onDone: () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          },
        ),
      );
    },
  );
}

enum _RipPhase { sealed, bursting, reveal }

class PackRipTheater extends ConsumerStatefulWidget {
  const PackRipTheater({
    super.key,
    required this.pulls,
    required this.onDone,
    this.packImageUrl,
  });

  final List<OwnedCard> pulls;
  final VoidCallback onDone;
  final String? packImageUrl;

  @override
  ConsumerState<PackRipTheater> createState() => _PackRipTheaterState();
}

class _PackRipTheaterState extends ConsumerState<PackRipTheater>
    with TickerProviderStateMixin {
  _RipPhase _phase = _RipPhase.sealed;
  double _tear = 0;
  double _dragAccum = 0;
  int _cardIndex = 0;
  bool _flipped = false;
  bool _deciding = false;
  bool _glow = false;
  double _swipeDx = 0;

  late final AnimationController _burst;
  late final AnimationController _flip;
  late final AnimationController _glowPulse;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _burst.dispose();
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

  void _onTearUpdate(DragUpdateDetails d) {
    if (_phase != _RipPhase.sealed) return;
    // Swipe across the top seal (horizontal). Small vertical drag still helps.
    final across = d.delta.dx.abs() + math.max(0.0, -d.delta.dy) * 0.15;
    _dragAccum = (_dragAccum + across).clamp(0.0, 200.0);
    setState(() => _tear = (_dragAccum / 130).clamp(0.0, 1.0));
    if (_tear >= 1) _openPack();
  }

  Future<void> _openPack() async {
    if (_phase != _RipPhase.sealed) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _RipPhase.bursting;
      _tear = 1;
    });
    await _burst.forward(from: 0);
    if (!mounted) return;
    // Skip preload lineup — cards already emerged from the pack mouth.
    setState(() {
      _phase = _RipPhase.reveal;
      _cardIndex = 0;
      _flipped = false;
      _deciding = false;
      _glow = false;
      _swipeDx = 0;
    });
    if (!mounted || _phase != _RipPhase.reveal) return;
    await _presentCard();
  }

  Future<void> _presentCard() async {
    _flip.value = 0;
    setState(() {
      _flipped = false;
      _deciding = false;
      _glow = false;
      _swipeDx = 0;
    });
    // Brief beat on the focused back, then auto-flip.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || _phase != _RipPhase.reveal) return;
    await _flip.forward(from: 0);
    if (!mounted) return;

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
    });
  }

  Future<void> _decide({required bool keep}) async {
    if (!_deciding || _phase != _RipPhase.reveal) return;
    setState(() => _deciding = false);

    final notifier = ref.read(gameProvider.notifier);
    final owned = _current;

    if (keep) {
      await notifier.keepRipCard(owned.instanceId);
      HapticFeedback.lightImpact();
    } else {
      await notifier.exchangeRipCard(owned.instanceId);
      HapticFeedback.mediumImpact();
    }

    if (!mounted) return;
    if (_cardIndex < widget.pulls.length - 1) {
      setState(() => _cardIndex += 1);
      await _presentCard();
    } else {
      // No Pack Summary — finalize and return to previous screen.
      await notifier.finalizeRip(keepRemaining: false);
      if (!mounted) return;
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(gameProvider.notifier);
    final candyBal = ref.watch(gameProvider.select((s) => s.player.candy));

    return Material(
      color: CC.bg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  if (_phase == _RipPhase.sealed || _phase == _RipPhase.reveal)
                    IconButton(
                      onPressed: () async {
                        await ref
                            .read(gameProvider.notifier)
                            .finalizeRip(keepRemaining: true);
                        if (context.mounted) widget.onDone();
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      switch (_phase) {
                        _RipPhase.sealed => 'Tear open',
                        _RipPhase.bursting => 'Opening…',
                        _RipPhase.reveal =>
                          'Card ${_cardIndex + 1}/${widget.pulls.length}',
                      },
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  CandyBalance(candyBal),
                ],
              ),
            ),
            Expanded(
              child: switch (_phase) {
                _RipPhase.sealed => _SealedPack(
                    tear: _tear,
                    imageUrl: widget.packImageUrl,
                    onTearUpdate: _onTearUpdate,
                    onTearEnd: () {
                      if (_tear >= 0.82) _openPack();
                    },
                  ),
                _RipPhase.bursting => AnimatedBuilder(
                    animation: _burst,
                    builder: (context, _) {
                      final t = Curves.easeOutCubic.transform(_burst.value);
                      // Finish top tear → strip flies off; cards rise from mouth.
                      final peel = 1.0 + t;
                      return _PackPeelStage(
                        tear: peel.clamp(0.0, 2.0),
                        imageUrl: widget.packImageUrl,
                        showHint: false,
                        interactive: false,
                      );
                    },
                  ),
                _RipPhase.reveal => _RevealStage(
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
              },
            ),
            if (_phase == _RipPhase.reveal && _deciding)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => _decide(keep: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CC.candy,
                            backgroundColor: CC.candy.withValues(alpha: 0.12),
                            side: BorderSide(
                              color: CC.candy.withValues(alpha: 0.7),
                            ),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.center,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Exchange',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
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
                            padding: EdgeInsets.zero,
                            alignment: Alignment.center,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Keep',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Reserve sticky-bar height so sealed/burst pack stays truly centered.
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SealedPack extends StatelessWidget {
  const _SealedPack({
    required this.tear,
    required this.onTearUpdate,
    required this.onTearEnd,
    this.imageUrl,
  });

  final double tear;
  final String? imageUrl;
  final void Function(DragUpdateDetails) onTearUpdate;
  final VoidCallback onTearEnd;

  @override
  Widget build(BuildContext context) {
    return _PackPeelStage(
      tear: tear,
      imageUrl: imageUrl,
      showHint: true,
      interactive: true,
      onTearUpdate: onTearUpdate,
      onTearEnd: onTearEnd,
    );
  }
}

/// Sealed pack: horizontal top-seal tear; cards rise out of the pack mouth
/// only after the pack is fully torn (burst), never while still sealed.
class _PackPeelStage extends StatelessWidget {
  const _PackPeelStage({
    required this.tear,
    required this.showHint,
    required this.interactive,
    this.imageUrl,
    this.onTearUpdate,
    this.onTearEnd,
  });

  final double tear;
  final String? imageUrl;
  final bool showHint;
  final bool interactive;
  final void Function(DragUpdateDetails)? onTearUpdate;
  final VoidCallback? onTearEnd;

  @override
  Widget build(BuildContext context) {
    // tear 0..1 = user rip across top; >1 = burst (strip flies, cards emerge).
    final t = tear.clamp(0.0, 1.0);
    final exit = (tear - 1.0).clamp(0.0, 1.0);
    final peel = Curves.easeOutCubic.transform(t);
    final emerge = Curves.easeOutCubic.transform(exit);
    final stripFly = Curves.easeIn.transform(exit);
    final packFade = (1.0 - exit * 0.9).clamp(0.0, 1.0);
    final showEmerging = exit > 0.02;
    // Start physically splitting once the swipe has real progress.
    final torn = peel > 0.05;

    return LayoutBuilder(
      builder: (context, constraints) {
        const targetPackW = 420.0;
        const targetPackH = 600.0;
        final availW = constraints.maxWidth * 0.88;
        final availH = constraints.maxHeight * 0.82;
        final scale = math.min(availW / targetPackW, availH / targetPackH);
        final packW = targetPackW * scale;
        final packH = targetPackH * scale;
        // Real top-seal height so the torn piece is a visible chunk of pack art.
        final stripH = packH * 0.18;
        final backW = packW * 0.72;
        final backH = packH * 0.70;

        // BoxFit.fill so clip coords match pack pixels (contain letterbox
        // was clipping empty padding → tiny "icon" strip + intact body).
        Widget packArt() => _PackBody(
              imageUrl: imageUrl,
              width: packW,
              height: packH,
              fit: BoxFit.fill,
            );

        return Center(
          child: SizedBox(
            width: packW,
            height: packH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (showEmerging)
                  Positioned(
                    top: stripH * 0.4,
                    left: (packW - backW) / 2,
                    width: backW,
                    height: backH,
                    child: Opacity(
                      opacity: (emerge * 1.15).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          packH * 0.42 * (1 - emerge) - emerge * packH * 0.18,
                        ),
                        child: _CardBack(width: backW, height: backH),
                      ),
                    ),
                  ),

                // Intact pack (pre-tear).
                if (!torn && packFade > 0.02)
                  Positioned.fill(
                    child: Opacity(
                      opacity: packFade,
                      child: packArt(),
                    ),
                  ),

                // Torn body: full-width pack with TOP stripH cut away.
                if (torn && packFade > 0.02)
                  Positioned(
                    top: stripH,
                    left: 0,
                    width: packW,
                    height: packH - stripH,
                    child: Opacity(
                      opacity: packFade,
                      child: Transform.translate(
                        offset: Offset(0, exit * packH * 0.04),
                        child: ClipRect(
                          child: OverflowBox(
                            maxWidth: packW,
                            maxHeight: packH,
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: packW,
                              height: packH,
                              child: packArt(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Torn-off top seal: same pack art, only the top stripH, peeling away.
                if (torn && stripFly < 0.98)
                  Positioned(
                    top: 0,
                    left: 0,
                    width: packW,
                    height: stripH,
                    child: Transform.translate(
                      offset: Offset(
                        peel * packW * 0.22 + stripFly * packW * 0.75,
                        -peel * stripH * 0.35 - stripFly * packH * 0.6,
                      ),
                      child: Transform.rotate(
                        alignment: Alignment.bottomLeft,
                        angle: -peel * 0.35 - stripFly * 1.05,
                        child: Opacity(
                          opacity: (1.0 - stripFly * 0.85).clamp(0.0, 1.0),
                          child: ClipRect(
                            child: OverflowBox(
                              maxWidth: packW,
                              maxHeight: packH,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: packW,
                                height: packH,
                                child: packArt(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Tear edge along the cut (on the body mouth).
                if (torn)
                  Positioned(
                    top: stripH - 7,
                    left: 0,
                    width: packW,
                    height: 14,
                    child: CustomPaint(
                      size: Size(packW, 14),
                      painter: _HorizontalTearPainter(
                        progress: 1.0,
                        glow: 0.55 + peel * 0.45,
                      ),
                    ),
                  ),

                if (exit > 0.45)
                  Positioned.fill(
                    child: Opacity(
                      opacity: ((exit - 0.45) / 0.55).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, -packH * 0.12 * exit),
                        child: Transform.scale(
                          scale: 0.94 + exit * 0.06,
                          child: Center(
                            child: _CardBack(width: backW, height: backH),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (interactive)
                  Positioned(
                    left: packW * 0.05,
                    right: packW * 0.05,
                    top: 0,
                    height: packH * 0.42,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: onTearUpdate,
                      onHorizontalDragEnd: (_) => onTearEnd?.call(),
                      child: showHint
                          ? AnimatedOpacity(
                              opacity: t < 0.12 ? 1 : (1 - t).clamp(0.0, 1.0),
                              duration: const Duration(milliseconds: 180),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(top: stripH + 6),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swipe_rounded,
                                        color: CC.accent.withValues(alpha: 0.9),
                                        size: 28,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CC.bgElevated
                                              .withValues(alpha: 0.72),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: CC.accent.withValues(
                                              alpha: 0.4 + t * 0.4,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          t <= 0
                                              ? 'SWIPE ACROSS TOP'
                                              : '${(t * 100).round()}%',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            color: CC.accent,
                                            letterSpacing: 1.0,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackBody extends StatelessWidget {
  const _PackBody({
    required this.width,
    required this.height,
    this.imageUrl,
    this.fit = BoxFit.fill,
  });
  final double width;
  final double height;
  final String? imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final hasArt = imageUrl != null && imageUrl!.isNotEmpty;
    // Fill the tear frame edge-to-edge so top/bottom clips cut real pack pixels.
    final art = hasArt
        ? KnockoutProductImage(
            url: imageUrl!,
            width: width,
            height: height,
            fit: fit,
            placeholder: const _FoilPackFallback(),
            error: const _FoilPackFallback(),
          )
        : ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            child: SizedBox(
              width: width,
              height: height,
              child: const _FoilPackFallback(),
            ),
          );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: width * 0.17,
            right: width * 0.17,
            top: height * 0.16,
            bottom: height * 0.11,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
            ),
          ),
          art,
        ],
      ),
    );
  }
}

class _FoilPackFallback extends StatelessWidget {
  const _FoilPackFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFDE68A),
            Color(0xFFF59E0B),
            Color(0xFF8B5CF6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 3),
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 42),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: Text(
              'VAULTREX\nRIFTBOUND',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                height: 1.2,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal jagged rip across the top seal (left → right with swipe).
class _HorizontalTearPainter extends CustomPainter {
  _HorizontalTearPainter({required this.progress, required this.glow});

  final double progress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.5;
    final len = size.width * progress.clamp(0.08, 1.0);
    final path = Path()..moveTo(0, midY);
    const segs = 22;
    for (var i = 1; i <= segs; i++) {
      final x = len * i / segs;
      final zig = math.sin(i * 1.7) * 3.2 + (i.isEven ? -1.4 : 1.4);
      path.lineTo(x, midY + zig);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = CC.accent.withValues(alpha: 0.28 * glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92 * glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HorizontalTearPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.glow != glow;
}

class _CardBack extends StatelessWidget {
  const _CardBack({this.width = 200, this.height = 280});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        // Vector paint stays crisp at every flip size; PNG is a shipped asset
        // for tooling / previews (1000×1400).
        child: CustomPaint(
          size: Size(width, height),
          painter: const _RiftboundCardBackPainter(),
        ),
      ),
    );
  }
}

/// Vector-style Riftbound main-deck back (navy + gold) — crisp at any scale.
class _RiftboundCardBackPainter extends CustomPainter {
  const _RiftboundCardBackPainter();

  static const _navy = Color(0xFF08163A);
  static const _gold = Color(0xFFD4AF5F);
  static const _goldLt = Color(0xFFE8CC8A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    canvas.drawRect(Offset.zero & size, Paint()..color = _navy);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF12285A),
          _navy,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: h * 0.55));
    canvas.drawRect(Offset.zero & size, glow);

    final goldStroke = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.008
      ..isAntiAlias = true;

    final goldStrokeThin = Paint()
      ..color = _goldLt
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0045
      ..isAntiAlias = true;

    final margin = w * 0.048;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTRB(margin, margin, w - margin, h - margin),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(outer, goldStroke);
    final innerM = margin + w * 0.018;
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTRB(innerM, innerM, w - innerM, h - innerM),
      Radius.circular(w * 0.028),
    );
    canvas.drawRRect(inner, goldStrokeThin);

    void drawDiamond(Offset c, double half, Paint p) {
      final path = Path()
        ..moveTo(c.dx, c.dy - half)
        ..lineTo(c.dx + half, c.dy)
        ..lineTo(c.dx, c.dy + half)
        ..lineTo(c.dx - half, c.dy)
        ..close();
      canvas.drawPath(path, p);
    }

    final corner = margin + w * 0.009;
    final ds = w * 0.012;
    for (final o in [
      Offset(corner, corner),
      Offset(w - corner, corner),
      Offset(corner, h - corner),
      Offset(w - corner, h - corner),
    ]) {
      drawDiamond(o, ds, goldStrokeThin);
    }

    final half = w * 0.21;
    drawDiamond(Offset(cx, cy), half, goldStroke);
    drawDiamond(Offset(cx, cy), half * 0.86, goldStrokeThin);

    // Wings
    for (final side in [-1.0, 1.0]) {
      final x0 = cx + side * (half - w * 0.008);
      final path = Path()
        ..moveTo(x0, cy - w * 0.018)
        ..lineTo(x0 + side * w * 0.028, cy - w * 0.006)
        ..lineTo(x0 + side * w * 0.095, cy)
        ..lineTo(x0 + side * w * 0.028, cy + w * 0.006)
        ..lineTo(x0, cy + w * 0.018)
        ..lineTo(x0 + side * w * 0.012, cy)
        ..close();
      canvas.drawPath(path, goldStrokeThin);
    }

    // Arcs
    for (final upward in [true, false]) {
      final yc = cy + (upward ? -half * 0.62 : half * 0.62);
      for (final r in [w * 0.155, w * 0.175, w * 0.195]) {
        final rect = Rect.fromCircle(center: Offset(cx, yc), radius: r);
        canvas.drawArc(
          rect,
          upward ? 3.6 : 0.35,
          upward ? 2.2 : 2.2,
          false,
          goldStrokeThin,
        );
      }
    }

    drawDiamond(Offset(cx, cy - half - w * 0.048), w * 0.014, goldStrokeThin);
    drawDiamond(Offset(cx, cy + half + w * 0.048), w * 0.014, goldStrokeThin);

    final leagueStyle = TextStyle(
      color: _goldLt,
      fontWeight: FontWeight.w800,
      fontSize: w * 0.07,
      letterSpacing: w * 0.004,
      height: 1,
    );
    final ofStyle = leagueStyle.copyWith(fontSize: w * 0.038);

    void paintBar(String text, double y, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final padX = w * 0.028;
      final padY = w * 0.012;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, y),
          width: tp.width + padX * 2,
          height: tp.height + padY * 2,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, Paint()..color = _navy);
      canvas.drawRRect(rect, goldStrokeThin);
      tp.paint(canvas, Offset(cx - tp.width / 2, y - tp.height / 2));
    }

    paintBar('LEAGUE', cy - w * 0.075, leagueStyle);
    final ofTp = TextPainter(
      text: TextSpan(text: 'OF', style: ofStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: ofTp.width + w * 0.03,
        height: ofTp.height + w * 0.016,
      ),
      Paint()..color = _navy,
    );
    ofTp.paint(canvas, Offset(cx - ofTp.width / 2, cy - ofTp.height / 2));
    paintBar('LEGENDS', cy + w * 0.075, leagueStyle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;
  final void Function(DragEndDetails) onHorizontalDragEnd;

  OwnedCard get owned => pulls[cardIndex];

  @override
  Widget build(BuildContext context) {
    final artUrl = def?.imageUrl ?? '';
    final ambient = _ambientFor(def?.rarity, foil: owned.foil);

    return GestureDetector(
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([flip, glowAnim]),
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(flip.value);
          final angle = t * math.pi;
          final showFront = angle >= math.pi / 2;
          final displayAngle = showFront ? angle - math.pi : angle;
          final pulse = glow
              ? (0.4 + 0.35 * math.sin(glowAnim.value * math.pi * 2))
              : 0.0;
          final keepHint = swipeDx > 24;
          final exchangeHint = swipeDx < -24;

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight * 0.86;
              final maxW = constraints.maxWidth - 24;
              var cardH = maxH;
              var cardW = cardH * (5 / 7);
              if (cardW > maxW) {
                cardW = maxW;
                cardH = cardW * (7 / 5);
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (artUrl.isNotEmpty && showFront)
                          Opacity(
                            opacity: 0.28,
                            child: ImageFiltered(
                              imageFilter:
                                  ImageFilter.blur(sigmaX: 42, sigmaY: 42),
                              child: Transform.scale(
                                scale: 1.35,
                                child: CachedNetworkImage(
                                  imageUrl: artUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.15),
                              radius: 1.05,
                              colors: [
                                ambient.withValues(
                                  alpha: showFront ? 0.38 + pulse * 0.2 : 0.18,
                                ),
                                CC.bg.withValues(alpha: 0.15),
                                CC.bg,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xCC0A0C12),
                                Color(0x000A0C12),
                                Color(0x000A0C12),
                                Color(0xE60A0C12),
                              ],
                              stops: [0.0, 0.18, 0.72, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
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
                          duration: const Duration(milliseconds: 220),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  def?.name ?? 'Card',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    height: 1.2,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 28,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (def != null) ...[
                                        RarityChip(def!.rarity),
                                        const SizedBox(width: 12),
                                      ],
                                      MoneyText(
                                        fair,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                          color: glow ? ambient : CC.ink,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Container(
                                          width: 3,
                                          height: 3,
                                          decoration: const BoxDecoration(
                                            color: CC.inkMuted,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.cookie,
                                        size: 15,
                                        color: CC.candy,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${(fair * 100).round()}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: CC.candy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (glow) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'NICE PULL',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: ambient,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                      fontSize: 11,
                                      height: 1,
                                    ),
                                  ),
                                ],
                                if (deciding) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    keepHint
                                        ? 'Release to Keep'
                                        : exchangeHint
                                            ? 'Release to Exchange'
                                            : 'Swipe left or right',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: keepHint
                                          ? CC.accent
                                          : exchangeHint
                                              ? CC.candy
                                              : CC.inkMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      height: 1,
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

/// Remaining backs fan behind the enlarged active card (flip + swipe).
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
    // Show up to ~8 peeks so a 14-card pull still reads as a stack.
    final peekCount = math.min(waiting, 8);
    final peekW = cardW * 0.88;
    final peekH = cardH * 0.88;

    return SizedBox(
      width: cardW + peekCount * 18,
      height: cardH + 24,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Waiting cards — cascading stack behind / to the sides.
          for (var i = peekCount; i >= 1; i--)
            Transform.translate(
              offset: Offset(
                (i.isEven ? 1 : -1) * (10.0 + i * 11.0),
                6.0 + i * 5.0,
              ),
              child: Transform.rotate(
                angle: (i.isEven ? 1 : -1) * (0.03 + i * 0.012),
                child: Opacity(
                  opacity: (0.92 - i * 0.06).clamp(0.35, 0.9),
                  child: _CardBack(width: peekW, height: peekH),
                ),
              ),
            ),
          // Active focused card.
          Transform.translate(
            offset: Offset(swipeDx * 0.45, 0),
            child: Transform.rotate(
              angle: swipeDx / 480,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ambient.withValues(
                        alpha: 0.35 + pulse * 0.25,
                      ),
                      blurRadius: 36 + pulse * 18,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(displayAngle),
                  child: showFront
                      ? FoilChromatic(
                          enabled: owned.foil,
                          intensity: 0.78,
                          child: CardArt(
                            url: artUrl,
                            width: cardW,
                            height: cardH,
                            foil: false,
                            radius: 18,
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


