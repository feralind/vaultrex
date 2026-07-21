import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/bindora_feel.dart';
import '../theme/app_text.dart';
import 'knockout_image.dart';

/// Live pack peel of the sealed product art in [packImageUrl].
///
/// Interaction: swipe down with a light finger trail — pack stays sealed until
/// the swipe commits, then the parent drives [progress] 0→1 as an autoplay rip.
/// No mid-scrub stop, no tap-to-open, no rip-line overlay.
class ScrubPeelStage extends StatefulWidget {
  const ScrubPeelStage({
    super.key,
    required this.progress,
    required this.showHint,
    required this.interactive,
    this.packImageUrl,
    this.cardBackAsset = sealedFallbackCardBack,
    this.onSwipeCommit,
    this.enablePeelTicks = false,
    @Deprecated('Use onSwipeCommit — finger no longer scrubs peel progress')
    this.onTearUpdate,
    @Deprecated('Use onSwipeCommit')
    this.onTearEnd,
  });

  /// 0 = sealed, 1 = fully peeled. Driven by parent autoplay after swipe commit.
  final double progress;
  final bool showHint;
  final bool interactive;

  /// Asset path (`assets/...`) or http(s) URL of the sealed pack being opened.
  /// When null/empty, falls back to [sealedFallbackPack].
  final String? packImageUrl;

  /// Card back shown through the tear.
  final String cardBackAsset;

  /// Fired once when the player finishes a qualifying downward swipe.
  final VoidCallback? onSwipeCommit;

  /// Optional tick SFX/haptics while [progress] crosses peel marks (autoplay).
  final bool enablePeelTicks;

  @Deprecated('Use onSwipeCommit')
  final void Function(DragUpdateDetails)? onTearUpdate;
  @Deprecated('Use onSwipeCommit')
  final void Function(DragEndDetails)? onTearEnd;

  /// Demo / fallback when callers omit pack art.
  static const sealedFallbackPack =
      'assets/featured_packs/pokemon/pack_legendary.png';
  static const sealedFallbackCardBack = 'assets/card_backs/riftbound_back.png';

  /// Legacy bake constants retained for tests / tooling references.
  static const frameCount = 96;
  static const lastGoodFrame = 95;
  static const sealedAsset = 'assets/rip/peel_sealed.png';

  static String frameAsset(int index) {
    final i = index.clamp(0, frameCount - 1);
    return 'assets/rip/frames/peel_${i.toString().padLeft(2, '0')}.png';
  }

  /// Continuous frame coordinate in [0, lastGoodFrame] for [progress].
  /// Kept for scrub continuity tests; live peel uses [progress] directly.
  static double frameExact(double progress) {
    final p = progress.clamp(0.0, 1.0);
    return p * lastGoodFrame;
  }

  static String resolvePackUrl(String? packImageUrl) {
    final u = packImageUrl?.trim() ?? '';
    if (u.isEmpty) return sealedFallbackPack;
    return u;
  }

  @override
  State<ScrubPeelStage> createState() => _ScrubPeelStageState();
}

class _ScrubPeelStageState extends State<ScrubPeelStage> {
  double _lastHapticAt = 0;
  Offset? _finger;
  double _swipeDy = 0;
  bool _dragging = false;

  static const _commitTravel = 72.0;
  static const _commitVelocity = 700.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tickHaptics(widget.progress));
  }

  @override
  void didUpdateWidget(covariant ScrubPeelStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _tickHaptics(widget.progress);
    }
  }

  void _tickHaptics(double progress) {
    if (!widget.enablePeelTicks) return;
    final p = progress.clamp(0.0, 1.0);
    for (final mark in [0.18, 0.34, 0.5, 0.66, 0.82, 0.94]) {
      if (_lastHapticAt < mark && p >= mark) {
        BindoraHaptics.peelTick();
        BindoraSounds.peelTick();
        _lastHapticAt = mark;
      }
    }
  }

  void _onDragStart(DragStartDetails d) {
    if (!widget.interactive) return;
    setState(() {
      _dragging = true;
      _finger = d.localPosition;
      _swipeDy = 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!widget.interactive || !_dragging) return;
    final dy = d.delta.dy;
    setState(() {
      _finger = d.localPosition;
      if (dy > 0) _swipeDy += dy;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (!widget.interactive || !_dragging) return;
    final v = d.primaryVelocity ?? 0;
    final committed = _swipeDy >= _commitTravel || v >= _commitVelocity;
    setState(() {
      _dragging = false;
      _finger = null;
      _swipeDy = 0;
    });
    if (committed) {
      HapticFeedback.selectionClick();
      widget.onSwipeCommit?.call();
    }
  }

  void _onDragCancel() {
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _finger = null;
      _swipeDy = 0;
    });
  }

  Widget _packFace({BoxFit fit = BoxFit.contain}) {
    final url = ScrubPeelStage.resolvePackUrl(widget.packImageUrl);
    // Featured / local pack PNGs already have alpha — skip knockout (faster +
    // no pending decode timers in widget tests).
    if (isAssetImageUrl(url)) {
      return Image.asset(
        normalizeAssetPath(url),
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Image.asset(
          ScrubPeelStage.sealedFallbackPack,
          fit: fit,
          filterQuality: FilterQuality.high,
        ),
      );
    }
    // Network product photos often sit on studio white — knock it out.
    return KnockoutProductImage(
      url: url,
      fit: fit,
      placeholder: const ColoredBox(color: Color(0xFF121826)),
      error: Image.asset(
        ScrubPeelStage.sealedFallbackPack,
        fit: fit,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _cardBack() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        widget.cardBackAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFF0D1B4C),
          child: Center(
            child: Icon(Icons.style_rounded, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress.clamp(0.0, 1.0);
    final peel = PeelGeometry.fromProgress(p);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth * 0.92;
        final maxH = constraints.maxHeight * 0.88;
        // Pack product art is roughly booster-shaped (~0.62).
        const aspect = 0.62;
        var w = maxW;
        var h = w / aspect;
        if (h > maxH) {
          h = maxH;
          w = h * aspect;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.08),
                  radius: 0.9,
                  colors: [
                    Color(0xFF1A2240),
                    Color(0xFF0B0F1A),
                    Color(0xFF070A12),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: w,
                height: h,
                child: _LivePeelStack(
                  progress: p,
                  peel: peel,
                  packFaceBuilder: _packFace,
                  cardBack: _cardBack(),
                ),
              ),
            ),
            if (widget.interactive)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  onVerticalDragCancel: _onDragCancel,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.showHint && p < 0.08 && !_dragging)
                        Align(
                          alignment: const Alignment(0, -0.72),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 28,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                              Text(
                                'Swipe down to rip',
                                style: AppText.jakarta(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_finger != null)
                        CustomPaint(
                          painter: _FingerTrailPainter(point: _finger!),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Soft light that follows the finger during the commit swipe.
class _FingerTrailPainter extends CustomPainter {
  _FingerTrailPainter({required this.point});

  final Offset point;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = const Color(0xFF5EEAD4).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final core = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final ring = Paint()
      ..color = const Color(0xFF5EEAD4).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(point, 22, glow);
    canvas.drawCircle(point, 7, core);
    canvas.drawCircle(point, 11, ring);
  }

  @override
  bool shouldRepaint(covariant _FingerTrailPainter oldDelegate) =>
      oldDelegate.point != point;
}

/// Shared peel timing / V-tear math (mirrors tools/gen_peel_video.py).
class PeelGeometry {
  const PeelGeometry({
    required this.peelT,
    required this.openT,
    required this.exitT,
  });

  final double peelT;
  final double openT;
  final double exitT;

  static double easeInOut(double t) {
    t = t.clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  static double easeOutCubic(double t) {
    t = t.clamp(0.0, 1.0);
    return 1.0 - math.pow(1.0 - t, 3).toDouble();
  }

  static double easeScrub(double t) {
    t = t.clamp(0.0, 1.0);
    return t * 0.85 + easeInOut(t) * 0.15;
  }

  factory PeelGeometry.fromProgress(double progress) {
    final t = progress.clamp(0.0, 1.0);
    final peelT = easeScrub(((t - 0.015) / 0.605).clamp(0.0, 1.0));
    final openT = easeInOut(((t - 0.34) / 0.32).clamp(0.0, 1.0));
    final exitT = easeOutCubic(((t - 0.56) / 0.44).clamp(0.0, 1.0));
    return PeelGeometry(peelT: peelT, openT: openT, exitT: exitT);
  }

  static double vEdgeY(double x, double width, double tipY, double topY) {
    final cx = width * 0.5;
    final half = math.max(1.0, width * 0.48);
    final tn = ((x - cx).abs() / half).clamp(0.0, 1.0);
    final base = topY + (tipY - topY) * (1.0 - tn * tn);
    final jag = 3.2 + math.min(7.5, (tipY - topY) * 0.018);
    final zig = math.sin(x * 0.085 + tipY * 0.04) * jag * (0.35 + 0.65 * (1.0 - tn));
    final zig2 = math.sin(x * 0.21) * jag * 0.35;
    return base + zig + zig2;
  }

  double tipYFor(Size size) {
    final topY = size.height * 0.02;
    return topY + peelT * size.height * 1.08;
  }

  double topYFor(Size size) => size.height * 0.02;
}

class _LivePeelStack extends StatelessWidget {
  const _LivePeelStack({
    required this.progress,
    required this.peel,
    required this.packFaceBuilder,
    required this.cardBack,
  });

  final double progress;
  final PeelGeometry peel;
  final Widget Function({BoxFit fit}) packFaceBuilder;
  final Widget cardBack;

  @override
  Widget build(BuildContext context) {
    final cardVis = math.min(1.0, peel.peelT * 1.4 + peel.openT * 0.3 + peel.exitT);
    final sealed = peel.peelT < 0.012 && peel.openT < 0.01;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // Soft shadow under pack.
        Positioned(
          left: 10,
          right: -6,
          top: 18,
          bottom: -10,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.50 * (1.0 - peel.exitT * 0.85),
                    ),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Card back through the opening.
        if (cardVis > 0.02)
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.88,
              heightFactor: 0.86,
              child: Transform.scale(
                scale: 0.96 + peel.exitT * 0.04,
                child: Opacity(
                  opacity: cardVis,
                  child: cardBack,
                ),
              ),
            ),
          ),
        if (sealed)
          packFaceBuilder()
        else ...[
          // Remaining sealed lower pack (one piece — V tear).
          ClipPath(
            clipper: _RemainingPackClipper(peel),
            child: packFaceBuilder(),
          ),
          // Curling foil flaps along the tear band.
          if (peel.peelT > 0.015 && peel.exitT < 0.85) ...[
            _FlapLayer(peel: peel, left: true, packFaceBuilder: packFaceBuilder),
            _FlapLayer(peel: peel, left: false, packFaceBuilder: packFaceBuilder),
          ],
          // Specular lip along the V.
          CustomPaint(
            painter: _TearLipPainter(peel),
            child: const SizedBox.expand(),
          ),
        ],
      ],
    );
  }
}

class _RemainingPackClipper extends CustomClipper<Path> {
  _RemainingPackClipper(this.peel);
  final PeelGeometry peel;

  @override
  Path getClip(Size size) {
    final topY = peel.topYFor(size);
    final tipY = peel.tipYFor(size);
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, PeelGeometry.vEdgeY(0, size.width, tipY, topY));
    const steps = 64;
    for (var i = 1; i <= steps; i++) {
      final x = size.width * i / steps;
      path.lineTo(x, PeelGeometry.vEdgeY(x, size.width, tipY, topY));
    }
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _RemainingPackClipper oldClipper) =>
      oldClipper.peel.peelT != peel.peelT;
}

class _FlapBandClipper extends CustomClipper<Path> {
  _FlapBandClipper(this.peel, {required this.left});
  final PeelGeometry peel;
  final bool left;

  @override
  Path getClip(Size size) {
    final topY = peel.topYFor(size);
    final tipY = peel.tipYFor(size);
    final bandH = math.max(28.0, size.height * 0.22);
    final cx = size.width * 0.5;
    final path = Path();

    final x0 = left ? 0.0 : cx;
    final x1 = left ? cx : size.width;
    const steps = 36;
    // Walk along V edge then up into the band.
    path.moveTo(x0, PeelGeometry.vEdgeY(x0, size.width, tipY, topY));
    for (var i = 1; i <= steps; i++) {
      final x = x0 + (x1 - x0) * i / steps;
      path.lineTo(x, PeelGeometry.vEdgeY(x, size.width, tipY, topY));
    }
    final topBand = math.max(0.0, tipY - bandH);
    path.lineTo(x1, topBand);
    path.lineTo(x0, topBand);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _FlapBandClipper oldClipper) =>
      oldClipper.peel.peelT != peel.peelT || oldClipper.left != left;
}

class _FlapLayer extends StatelessWidget {
  const _FlapLayer({
    required this.peel,
    required this.left,
    required this.packFaceBuilder,
  });

  final PeelGeometry peel;
  final bool left;
  final Widget Function({BoxFit fit}) packFaceBuilder;

  @override
  Widget build(BuildContext context) {
    final openT = peel.openT;
    final exitT = peel.exitT;
    final ang = (left ? 1 : -1) * (0.07 + openT * 0.32 + exitT * 0.75);
    final sep = openT * 0.08 + exitT * 0.92;
    final dx = (left ? -1 : 1) * sep * 55;
    final dy = -sep * 70 - openT * 8;
    final fade = math.max(0.0, 1.0 - exitT * 1.2);

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: ang,
              alignment: left ? const Alignment(0.35, -0.2) : const Alignment(-0.35, -0.2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Silver underside peek.
                  ClipPath(
                    clipper: _FlapBandClipper(peel, left: left),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: left ? Alignment.centerLeft : Alignment.centerRight,
                          end: left ? Alignment.centerRight : Alignment.centerLeft,
                          colors: const [
                            Color(0xFFE8EEF8),
                            Color(0xFFB8C4D8),
                            Color(0xFF9AA8C0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Outer pack art flap.
                  ClipPath(
                    clipper: _FlapBandClipper(peel, left: left),
                    child: packFaceBuilder(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TearLipPainter extends CustomPainter {
  _TearLipPainter(this.peel);
  final PeelGeometry peel;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = math.min(1.0, peel.peelT * 1.2) * (1.0 - peel.exitT);
    if (strength < 0.02) return;

    final topY = peel.topYFor(size);
    final tipY = peel.tipYFor(size);
    final path = Path();
    var started = false;
    for (var xi = 0; xi <= size.width.round(); xi++) {
      final y = PeelGeometry.vEdgeY(xi.toDouble(), size.width, tipY, topY);
      if (y < topY - 2 || y > tipY + 4) continue;
      if (!started) {
        path.moveTo(xi.toDouble(), y);
        started = true;
      } else {
        path.lineTo(xi.toDouble(), y);
      }
    }
    if (!started) return;

    for (final entry in [
      (5.0, 42.0),
      (2.0, 130.0),
      (1.0, 200.0),
    ]) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = entry.$1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Color.fromARGB(
          (entry.$2 * strength).round().clamp(0, 255),
          255,
          248,
          230,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.65);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TearLipPainter oldDelegate) =>
      oldDelegate.peel.peelT != peel.peelT ||
      oldDelegate.peel.exitT != peel.exitT;
}

/// Shared peel drag→progress mapping used by live theater + preview.
///
/// Longer travel + mild ease keeps scrub continuous; velocity on release
/// adds a short settle so the peel doesn't stop on a hard edge.
class PeelDragMapper {
  PeelDragMapper({
    this.fullTravelPx = 240,
    this.maxAccumPx = 320,
  });

  /// Finger travel (px down) that maps to progress 1.0.
  final double fullTravelPx;

  /// Clamp for accumulated drag (allows slight overshoot before clamp).
  final double maxAccumPx;

  double accum = 0;
  double _lastDy = 0;

  void reset() {
    accum = 0;
    _lastDy = 0;
  }

  /// Apply a downward drag delta. Returns progress in [0, 1].
  double applyDelta(double dy) {
    if (dy <= 0) return progress;
    accum = (accum + dy).clamp(0.0, maxAccumPx);
    _lastDy = dy;
    return progress;
  }

  double get progress {
    final raw = (accum / fullTravelPx).clamp(0.0, 1.0);
    // Very mild ease — mostly 1:1 with finger, softens start/end only.
    return raw * 0.88 + Curves.easeInOut.transform(raw) * 0.12;
  }

  /// Estimated downward velocity in px/s.
  double estimateVelocity(DragEndDetails details) {
    final fromGesture = details.primaryVelocity;
    if (fromGesture != null && fromGesture > 0) {
      return fromGesture;
    }
    // Fallback: last delta as rough px/frame → px/s at ~60fps.
    return (_lastDy * 60.0).clamp(0.0, 2400.0);
  }

  /// Extra progress from release inertia (Rare Candy settle).
  double inertiaBoost(DragEndDetails details) {
    final vPs = estimateVelocity(details); // px/s
    // ~800 px/s → 0.08, ~2200 px/s → 0.22 cap.
    return (vPs / 10000.0).clamp(0.0, 0.22);
  }
}
