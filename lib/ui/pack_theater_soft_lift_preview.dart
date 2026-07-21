import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/bindora_feel.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/pack_peel_scrub.dart';

/// Standalone pack-rip preview — no game load required.
/// Swipe down (finger trail) → autoplay peel + pack_open → flip + flip_card.
Future<void> openPackTheaterSoftLiftPreview(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const PackTheaterSoftLiftPreview(),
    ),
  );
}

enum _PreviewPhase { sealed, peeling, reveal, done }

/// Full-screen demo matching live theater: swipe-commit → autoplay peel.
class PackTheaterSoftLiftPreview extends StatefulWidget {
  const PackTheaterSoftLiftPreview({super.key});

  @override
  State<PackTheaterSoftLiftPreview> createState() =>
      _PackTheaterSoftLiftPreviewState();
}

class _PackTheaterSoftLiftPreviewState extends State<PackTheaterSoftLiftPreview>
    with TickerProviderStateMixin {
  static const _back = 'assets/card_backs/pokemon_back.png';
  static const _demoPack = 'assets/featured_packs/pokemon/pack_legendary.png';

  _PreviewPhase _phase = _PreviewPhase.sealed;
  double _tear = 0;
  bool _auto = false;
  bool _loop = true;
  bool _busy = false;

  late final AnimationController _peelOut;
  late final AnimationController _flip;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _peelOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _loop = false;
    _peelOut.dispose();
    _flip.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _finishPeel() async {
    if (_phase != _PreviewPhase.sealed || _busy) return;
    unawaited(BindoraHaptics.packOpen());
    unawaited(BindoraSounds.packOpen());
    setState(() {
      _busy = true;
      _phase = _PreviewPhase.peeling;
      _tear = 0;
    });

    void tick() {
      if (!mounted || _phase != _PreviewPhase.peeling) return;
      setState(() => _tear = Curves.easeInOutCubic.transform(_peelOut.value));
    }

    _peelOut
      ..removeListener(tick)
      ..addListener(tick);
    await _peelOut.forward(from: 0);
    _peelOut.removeListener(tick);
    if (!mounted) return;
    setState(() => _tear = 1.0);

    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    unawaited(BindoraHaptics.peelRip());
    setState(() {
      _phase = _PreviewPhase.reveal;
      _busy = false;
    });
    _flip.value = 0;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted || _phase != _PreviewPhase.reveal) return;
    unawaited(BindoraHaptics.flipStart());
    unawaited(BindoraSounds.flip());
    await _flip.forward(from: 0);
    if (!mounted) return;
    unawaited(BindoraSounds.revealForTier(HapticTier.chase));
    _glow.forward(from: 0);
    setState(() => _phase = _PreviewPhase.done);
  }

  Future<void> _runAutoDemo() async {
    while (mounted && _loop && _auto) {
      setState(() {
        _phase = _PreviewPhase.sealed;
        _tear = 0;
        _busy = false;
      });
      _peelOut.value = 0;
      _flip.value = 0;
      _glow.value = 0;

      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted || !_loop || !_auto) return;
      await _finishPeel();
      if (!mounted || !_loop || !_auto) return;
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
  }

  Future<void> _toggleAuto(bool v) async {
    setState(() => _auto = v);
    if (v) {
      _loop = true;
      unawaited(_runAutoDemo());
    } else {
      _loop = false;
    }
  }

  Future<void> _reset() async {
    _loop = false;
    setState(() {
      _auto = false;
      _phase = _PreviewPhase.sealed;
      _tear = 0;
      _busy = false;
    });
    _peelOut.value = 0;
    _flip.value = 0;
    _glow.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final inReveal =
        _phase == _PreviewPhase.reveal || _phase == _PreviewPhase.done;

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Pack rip preview',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(onPressed: _reset, child: const Text('Reset')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Swipe down (light trail) → rip autoplays with pack_open.mp3\n'
                'Card flip plays flip_card.mp3',
                textAlign: TextAlign.center,
                style: AppText.jakarta(
                  color: CC.inkMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(
                'Auto-demo',
                style:
                    AppText.jakarta(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Auto swipe-commit → peel → flip loop',
                style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
              ),
              value: _auto,
              onChanged: (v) => unawaited(_toggleAuto(v)),
            ),
            Expanded(
              child: inReveal
                  ? AnimatedBuilder(
                      animation: Listenable.merge([_flip, _glow]),
                      builder: (context, _) => _FakeReveal(
                        flip: _flip.value,
                        glow: _glow.value,
                        deciding: _phase == _PreviewPhase.done,
                        backAsset: _back,
                      ),
                    )
                  : ScrubPeelStage(
                      progress: _tear.clamp(0.0, 1.0),
                      showHint: _phase == _PreviewPhase.sealed && !_auto,
                      interactive:
                          _phase == _PreviewPhase.sealed && !_auto && !_busy,
                      packImageUrl: _demoPack,
                      cardBackAsset: _back,
                      onSwipeCommit: () => unawaited(_finishPeel()),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text(
                _phaseLabel,
                style: AppText.jakarta(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: CC.accent,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _phaseLabel => switch (_phase) {
        _PreviewPhase.sealed =>
          _auto ? 'Auto-demo…' : '1 · Swipe down — light follows finger',
        _PreviewPhase.peeling => '2 · Rip autoplay · pack_open.mp3',
        _PreviewPhase.reveal => '3 · Flip · flip_card.mp3',
        _PreviewPhase.done => _auto ? 'Loop…' : 'Done · Reset to try again',
      };
}

class _FakeReveal extends StatelessWidget {
  const _FakeReveal({
    required this.flip,
    required this.glow,
    required this.deciding,
    required this.backAsset,
  });

  final double flip;
  final double glow;
  final bool deciding;
  final String backAsset;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(flip);
    final angle = t * math.pi;
    final showFront = angle >= math.pi / 2;
    final displayAngle = showFront ? angle - math.pi : angle;
    final glowPulse =
        deciding ? 0.35 + 0.3 * math.sin(glow * math.pi * 2) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        const aspect = 2.5 / 3.5;
        final maxH = math.min(
          constraints.maxHeight * 0.58,
          constraints.maxWidth * 1.05,
        );
        final maxW = constraints.maxWidth * 0.58;
        var cardW = maxW;
        var cardH = cardW / aspect;
        if (cardH > maxH) {
          cardH = maxH;
          cardW = cardH * aspect;
        }
        const peeks = 4;

        return Center(
          child: SizedBox(
            width: cardW + 20,
            height: cardH + peeks * 7.0 + 48,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                for (var i = peeks; i >= 1; i--)
                  Transform.translate(
                    offset: Offset(0, -i * 6.0),
                    child: Opacity(
                      opacity: (0.9 - i * 0.08).clamp(0.45, 0.92),
                      child: _cardFace(
                        width: cardW,
                        height: cardH,
                        front: false,
                        backAsset: backAsset,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24)
                            .withValues(alpha: 0.28 + glowPulse * 0.4),
                        blurRadius: 32 + glowPulse * 18,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(displayAngle),
                    child: _cardFace(
                      width: cardW,
                      height: cardH,
                      front: showFront,
                      backAsset: backAsset,
                    ),
                  ),
                ),
                if (deciding)
                  Positioned(
                    bottom: -4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _fakeBtn('← Exchange', outlined: true),
                        const SizedBox(width: 12),
                        _fakeBtn('Keep →', outlined: false),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fakeBtn(String label, {required bool outlined}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: outlined ? CC.bgElevated : CC.accent,
        borderRadius: BorderRadius.circular(24),
        border: outlined ? Border.all(color: CC.line) : null,
      ),
      child: Text(
        label,
        style: AppText.jakarta(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: outlined ? CC.ink : Colors.white,
        ),
      ),
    );
  }

  Widget _cardFace({
    required double width,
    required double height,
    required bool front,
    required String backAsset,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: front
            ? Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF12203A)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.9),
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'FOIL CHASE',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Image.asset(
                backAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFF0C1428),
                ),
              ),
      ),
    );
  }
}
