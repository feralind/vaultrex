import 'dart:math';

import 'package:flutter/material.dart';

// ============================================================================
// PSA SLAB + FOIL — FIXED SPACING VERSION
// ============================================================================
// 
// CHANGE LOG (search for "[CHANGED]" to find every modification):
// 
// 1. SLAB PROPORTIONS — Label reduced from ~34% to ~24%, card increased
// 2. RED RAIL — Height reduced from 11-14*s to 7.5-9*s
// 3. BODY PADDING — All sides tightened (top 3*s → 1.2*s, etc.)
// 4. INTERNAL SPACERS — Set→name 1.6*s → 0.6*s, right col 1.4*s → 0.5*s
// 5. CERT/BARCODE ROW — Height reduced from 11/8*s to 8/5.5*s
// 6. TEXT LINE HEIGHTS — All reduced to 1.0 or 0.95 for density
// 7. NAME LINE — Removed Expanded wrapper, capped maxLines instead
// 8. FONT SIZES — Slightly reduced for better density at small scales
// 9. GAP BETWEEN LABEL & CARD — Reduced from 3.5*s to 1.8*s
//
// These changes make the slab look authentic at BOTH full-size (inspect)
// and compact (collection grid thumbnail) scales.
// ============================================================================

/// FeeBay-inspired foil: prism rainbow + diagonal sheen + radial glints + sparkles.
class FoilChromatic extends StatefulWidget {
  const FoilChromatic({
    super.key,
    required this.child,
    this.enabled = true,
    this.intensity = 0.65,
    this.autoPlay = true,
  });

  final Widget child;
  final bool enabled;
  final double intensity;
  /// When false (grids/lists), keep a static foil wash — no continuous ticker.
  final bool autoPlay;

  @override
  State<FoilChromatic> createState() => _FoilChromaticState();
}

class _FoilChromaticState extends State<FoilChromatic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // Ping-pong so prism/sweep never teleports at loop seams.
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );
    if (widget.autoPlay) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant FoilChromatic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoPlay != oldWidget.autoPlay) {
      if (widget.autoPlay) {
        _c.repeat(reverse: true);
      } else {
        _c.stop();
        _c.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.intensity <= 0.01) return widget.child;
    final i = widget.intensity.clamp(0.0, 1.2);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Ease motion so bands glide instead of stuttering on ticker ticks.
        final t = Curves.easeInOut.transform(_c.value);
        final twinkle = 0.55 + 0.45 * (0.5 + 0.5 * sin(t * pi * 2));
        final sweep = -1.2 + 2.6 * t;
        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.hardEdge,
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: i * 0.24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment(-1.2 + 2.4 * t, -0.6),
                        end: Alignment(0.4 + 2.0 * t, 1.2),
                        colors: const [
                          Color(0x55FF5AC8),
                          Color(0x443D9BFF),
                          Color(0x443DDE9C),
                          Color(0x55FFD166),
                          Color(0x44C084FC),
                          Color(0x55FF5AC8),
                        ],
                      ),
                      backgroundBlendMode: BlendMode.softLight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: i * 0.55 * twinkle,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: RadialGradient(
                        center: Alignment(
                          -0.55 + 1.1 * sin(t * pi * 2),
                          -0.35 + 0.5 * cos(t * pi * 2),
                        ),
                        radius: 0.55,
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          const Color(0x88FFE08A),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.18, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: i * 0.72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment(sweep - 0.55, -1.1),
                        end: Alignment(sweep + 0.55, 1.1),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.42),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.38, 0.5, 0.62, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FoilSparklePainter(
                    t: t,
                    intensity: i * twinkle,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _FoilSparklePainter extends CustomPainter {
  _FoilSparklePainter({required this.t, required this.intensity});

  final double t;
  final double intensity;

  static const _seeds = <Offset>[
    Offset(0.18, 0.22),
    Offset(0.72, 0.18),
    Offset(0.55, 0.42),
    Offset(0.28, 0.58),
    Offset(0.78, 0.62),
    Offset(0.42, 0.78),
    Offset(0.12, 0.70),
    Offset(0.88, 0.38),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.05 || size.isEmpty) return;
    for (var i = 0; i < _seeds.length; i++) {
      // Continuous phase (no % wrap) so reverse animation stays smooth.
      final phase = t * 2 + i * 0.17;
      final pulse = (sin(phase * pi * 2) * 0.5 + 0.5);
      if (pulse < 0.35) continue;
      final p = _seeds[i];
      final cx = size.width * p.dx;
      final cy = size.height * p.dy;
      final a = intensity * pulse * 0.85;
      final r = (1.2 + (i % 3) * 0.7) * (0.7 + pulse * 0.5);
      final paint = Paint()..color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(cx, cy), r, paint);
      paint.strokeWidth = 0.9;
      canvas.drawLine(Offset(cx - r * 2.2, cy), Offset(cx + r * 2.2, cy), paint);
      canvas.drawLine(Offset(cx, cy - r * 2.2), Offset(cx, cy + r * 2.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FoilSparklePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.intensity != intensity;
}

String psaGradeDescriptor(double grade) {
  if (grade >= 10) return 'GEM MT';
  if (grade >= 9.5) return 'MINT+';
  if (grade >= 9) return 'MINT';
  if (grade >= 8.5) return 'NM-MT+';
  if (grade >= 8) return 'NM-MT';
  if (grade >= 7) return 'NM';
  if (grade >= 6) return 'EX-MT';
  if (grade >= 5) return 'EX';
  return 'VG-EX';
}

String psaCertFromSeed(String seed) {
  var h = 0;
  for (final c in seed.codeUnits) {
    h = 0x1fffffff & (h + c);
    h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
    h ^= h >> 6;
  }
  h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
  h ^= h >> 11;
  h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
  final n = 10000000 + (h.abs() % 90000000);
  return '$n';
}

const double kPsaSlabAspect = 2.5 / 4.55;

/// Authentic PSA-style plastic slab: Flutter-drawn label, crisp at all sizes.
class SlabCase extends StatefulWidget {
  const SlabCase({
    super.key,
    required this.child,
    required this.company,
    required this.grade,
    this.cracking = false,
    this.width = 168,
    this.cardName,
    this.setLabel,
    this.cardNumber,
    this.certNumber,
    this.year,
    this.compact,
    this.animateEnter = true,
  });

  final Widget child;
  final String company;
  final double grade;
  final bool cracking;
  final double width;
  final String? cardName;
  final String? setLabel;
  final String? cardNumber;
  final String? certNumber;
  final String? year;
  final bool? compact;
  final bool animateEnter;

  @override
  State<SlabCase> createState() => _SlabCaseState();
}

class _SlabCaseState extends State<SlabCase> with TickerProviderStateMixin {
  late final AnimationController _emerge;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _emerge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      value: widget.animateEnter ? 0 : 1,
    );
    if (widget.animateEnter) _emerge.forward();
    // Ping-pong plastic sheen — no hard reset jump across the slab.
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emerge.dispose();
    _shine.dispose();
    super.dispose();
  }

  static const _psaRed = Color(0xFFC8102E);
  static const _labelWhite = Color(0xFFF8F8F6);
  static const _ink = Color(0xFF1A1A1A);

  bool get _compact => widget.compact ?? widget.width < 100;

  @override
  Widget build(BuildContext context) {
    final gradeLabel = widget.grade >= 10
        ? '10'
        : widget.grade.toStringAsFixed(widget.grade % 1 == 0 ? 0 : 1);
    final descriptor = psaGradeDescriptor(widget.grade);
    final setLine =
        (widget.setLabel ?? '${widget.year ?? '2024'} SINGLE').toUpperCase();
    final nameLine = (widget.cardName ?? 'CARD').toUpperCase();
    final numberLine =
        widget.cardNumber != null && widget.cardNumber!.isNotEmpty
            ? '#${widget.cardNumber}'
            : '';
    final cert = widget.certNumber ??
        psaCertFromSeed(
          '${widget.cardName}|${widget.grade}|${widget.cardNumber}|$setLine',
        );
    final compact = _compact;
    final showShine = !compact && widget.width >= 72;

    final slabCore = SizedBox(
      width: widget.width,
      child: AspectRatio(
        aspectRatio: kPsaSlabAspect,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final s = w / 168.0;
            final pad = (4.5 * s).clamp(2.5, 6.0);
            // [CHANGED] Gap reduced from (3.5 * s).clamp(2.0, 5.0)
            final gap = (1.8 * s).clamp(1.0, 3.0);
            final radius = (4.0 * s).clamp(2.5, 5.0);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: compact ? 6 : 14,
                    offset: Offset(0, compact ? 3 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: const Color(0xFF94A3B8).withValues(alpha: 0.9),
                          width: (1.2 * s).clamp(0.8, 1.5),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFE8EEF5).withValues(alpha: 0.55),
                            const Color(0xFFCBD5E1).withValues(alpha: 0.35),
                            const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(pad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // [CHANGED] Label flex: compact ? 30 : 34 → compact ? 22 : 24
                            // Label now takes ~24% instead of ~34% of slab height
                            Flexible(
                              flex: compact ? 22 : 24,
                              child: _PsaLabel(
                                width: w,
                                compact: compact,
                                setLine: setLine,
                                numberLine: numberLine,
                                nameLine: nameLine,
                                descriptor: descriptor,
                                gradeLabel: gradeLabel,
                                cert: cert,
                                psaRed: _psaRed,
                                labelWhite: _labelWhite,
                                ink: _ink,
                              ),
                            ),
                            SizedBox(height: gap),
                            // [CHANGED] Card flex: compact ? 62 : 66 → compact ? 74 : 76
                            // Card now takes ~76% instead of ~66% of slab height
                            Flexible(
                              flex: compact ? 74 : 76,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: const Color(0xFF94A3B8),
                                    width: 0.7,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    (2.2 * s).clamp(1.2, 3.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(1.5),
                                    clipBehavior: Clip.antiAlias,
                                    child: SizedBox.expand(
                                      child: widget.child,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showShine)
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _shine,
                              builder: (context, _) {
                                final shineT =
                                    Curves.easeInOut.transform(_shine.value);
                                // Secondary band phase-offset without hard wrap.
                                final shineT2 = Curves.easeInOut.transform(
                                  (1.0 - _shine.value).clamp(0.0, 1.0),
                                );
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(radius),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Transform.rotate(
                                        angle: -0.55,
                                        child: Align(
                                          alignment: Alignment(
                                            -1.6 + 3.4 * shineT,
                                            0,
                                          ),
                                          child: Container(
                                            width: w * 0.55,
                                            height: w * 2.4,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.white.withValues(
                                                    alpha: 0.06,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0.38,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0.06,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                                stops: const [
                                                  0.0,
                                                  0.32,
                                                  0.5,
                                                  0.68,
                                                  1.0,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Transform.rotate(
                                        angle: -0.55,
                                        child: Align(
                                          alignment: Alignment(
                                            -1.9 + 3.6 * shineT2,
                                            0.15,
                                          ),
                                          child: Container(
                                            width: w * 0.22,
                                            height: w * 2.2,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.white.withValues(
                                                    alpha: 0.22,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          height: w * 0.22,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white.withValues(
                                                  alpha: 0.14,
                                                ),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    if (widget.cracking)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
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
      ),
    );

    return AnimatedBuilder(
      animation: _emerge,
      builder: (context, child) {
        final curved =
            Curves.easeOutCubic.transform(_emerge.value.clamp(0.0, 1.0));
        final dy = (1 - curved) * (compact ? 8.0 : 24.0);
        final emergeScale = 0.94 + 0.06 * curved;
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: emergeScale,
              child: child,
            ),
          ),
        );
      },
      child: slabCore,
    );
  }
}

/// Flutter-drawn PSA label — two-column layout like real PSA slabs.
/// 
/// [CHANGED] All spacing values reduced for denser, more authentic PSA look.
/// The label is now ~24% of slab height vs previous ~34%.
class _PsaLabel extends StatelessWidget {
  const _PsaLabel({
    required this.width,
    required this.compact,
    required this.setLine,
    required this.numberLine,
    required this.nameLine,
    required this.descriptor,
    required this.gradeLabel,
    required this.cert,
    required this.psaRed,
    required this.labelWhite,
    required this.ink,
  });

  final double width;
  final bool compact;
  final String setLine;
  final String numberLine;
  final String nameLine;
  final String descriptor;
  final String gradeLabel;
  final String cert;
  final Color psaRed;
  final Color labelWhite;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final s = width / 168.0;
    final tiny = width < 90;
    final showMicro = !compact && !tiny && width >= 120;
    // Cert/footer needs vertical room — hide on thumbs / tiny stress sizes.
    final showCert = !tiny && width >= 100;
    final showBarcode = !compact && !tiny && width >= 110;

    // [CHANGED] Rail height: (compact ? 11.0 : 14.0) * s → (compact ? 7.5 : 9.0) * s
    // Tiny: even thinner so body text fits without overflow stripes.
    final railH = (tiny ? 6.0 : (compact ? 7.5 : 9.0)) * s;

    // [CHANGED] Font sizes slightly reduced for density
    final leftFont = (tiny ? 5.4 : 6.2) * s;
    final nameFont = (tiny ? 5.8 : 7.0) * s;
    final rightFont = (tiny ? 5.2 : 6.0) * s;
    final gradeBig = (tiny ? 16.0 : 20.0) * s;

    return ClipRect(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: labelWhite,
          borderRadius: BorderRadius.circular((1.8 * s).clamp(1.0, 2.5)),
          border: Border.all(
            color: psaRed.withValues(alpha: 0.9),
            width: (1.0 * s).clamp(0.7, 1.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Red PSA rail
            SizedBox(
              // [CHANGED] Height clamp: 9.0-18.0 → 6.0-14.0 (tiny min 4.5)
              height: railH.clamp(tiny ? 4.5 : 6.0, 14.0),
              child: ColoredBox(
                color: psaRed,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (4 * s).clamp(2.5, 6.0),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'PSA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          // [CHANGED] Slightly smaller: (10.5 * s) → (9.5 * s)
                          fontSize: ((tiny ? 8.0 : 9.5) * s).clamp(5.5, 12.0),
                          letterSpacing: 1.1,
                          height: 1,
                        ),
                      ),
                      if (showMicro) ...[
                        const Spacer(),
                        Flexible(
                          child: Text(
                            'PROFESSIONAL SPORTS AUTHENTICATOR',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                              // [CHANGED] Smaller microtext: (4.6 * s) → (4.2 * s)
                              fontSize: (4.2 * s).clamp(3.5, 5.8),
                              height: 1,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                // [CHANGED] All padding values reduced for density:
                // left/right: (4.5*s) → (3.5*s)
                // top: (3*s) → (1.2*s)
                // bottom: (2.5*s) → (1.2*s)
                padding: EdgeInsets.fromLTRB(
                  (3.5 * s).clamp(2.0, 5.5),
                  (tiny ? 0.6 : 1.2) * s,
                  (3.5 * s).clamp(2.0, 5.5),
                  (tiny ? 0.6 : 1.2) * s,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final body = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    setLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: leftFont.clamp(4.0, 8.5),
                                      letterSpacing: 0.15,
                                      height: 1.0,
                                    ),
                                  ),
                                  SizedBox(
                                    height: (tiny ? 0.2 : 0.6) * s,
                                  ),
                                  Text(
                                    nameLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: nameFont.clamp(4.2, 9.5),
                                      height: 1.0,
                                    ),
                                  ),
                                  if (!tiny) ...[
                                    SizedBox(height: (0.8 * s).clamp(0.4, 2.0)),
                                    Text(
                                      descriptor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: psaRed,
                                        fontWeight: FontWeight.w900,
                                        fontSize: leftFont.clamp(4.0, 8.5),
                                        letterSpacing: 0.4,
                                        height: 0.95,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(width: (3 * s).clamp(1.5, 5.0)),
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (numberLine.isNotEmpty)
                                    Text(
                                      numberLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: rightFont.clamp(4.0, 8.2),
                                        height: 1.0,
                                      ),
                                    ),
                                  if (!tiny) ...[
                                    SizedBox(height: (0.5 * s).clamp(0.3, 1.0)),
                                    Text(
                                      descriptor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: rightFont.clamp(4.0, 8.2),
                                        letterSpacing: 0.2,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: (tiny ? 0.4 : 1.0) * s),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      gradeLabel,
                                      style: TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w900,
                                        fontSize: gradeBig.clamp(8.0, 26.0),
                                        height: 0.92,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (showCert) ...[
                          SizedBox(height: (1.0 * s).clamp(0.5, 2.0)),
                          SizedBox(
                            height: (showBarcode ? 8.0 : 5.5) * s,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (showBarcode) ...[
                                  Expanded(
                                    flex: 5,
                                    child: CustomPaint(
                                      painter: _PsaBarcodePainter(
                                        ink: ink.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: (2.5 * s).clamp(1.5, 4.0)),
                                ],
                                Expanded(
                                  flex: showBarcode ? 6 : 8,
                                  child: Text(
                                    'Cert# $cert',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ink.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                      fontSize: (5.2 * s).clamp(4.0, 7.0),
                                      letterSpacing: 0.1,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Container(
                                  // Cap badge to cert row height — old 6.5 floor overflowed.
                                  width: (11 * s).clamp(7.0, 14.0),
                                  height: ((showBarcode ? 8.0 : 5.5) * s)
                                      .clamp(4.0, 12.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: psaRed,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                  child: Text(
                                    'PSA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: (4.8 * s).clamp(3.5, 6.5),
                                      height: 1,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );

                    // Scale the whole label body down if the flex slot is short
                    // (tiny 80px stress case) — no yellow/black overflow stripes.
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: body,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative barcode bars for the label footer (not scannable).
class _PsaBarcodePainter extends CustomPainter {
  _PsaBarcodePainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final paint = Paint()..color = ink;
    var x = 0.0;
    var i = 0;
    while (x < size.width - 1) {
      final barW = (i % 5 == 0) ? 1.6 : (i % 3 == 0 ? 1.1 : 0.7);
      final h = size.height * (0.55 + (i % 4) * 0.12);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - h, barW, h),
        paint,
      );
      x += barW + 0.85;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _PsaBarcodePainter oldDelegate) =>
      oldDelegate.ink != ink;
}

// ============================================================================
// TEST WIDGET — Drop this into any screen to preview both scales
// ============================================================================
// Usage in your app:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const SlabTestScreen()));
//
// Or add to your home temporarily:
//   home: const SlabTestScreen(),
// ============================================================================

class SlabTestScreen extends StatelessWidget {
  const SlabTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2240),
        title: const Text('PSA Slab Spacing Fix Test'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FULL SIZE
            const Text(
              'FULL SIZE (width: 280)',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SlabCase(
                company: 'PSA',
                grade: 9.5,
                width: 280,
                cardName: 'Teemo - Swift Scout',
                setLabel: '2025 Origins',
                cardNumber: '307*/298',
                child: Container(
                  color: const Color(0xFF4A2C6B),
                  child: const Center(
                    child: Text(
                      'CARD ART',
                      style: TextStyle(color: Colors.white54, fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // COMPACT (collection grid size)
            const Text(
              'COMPACT / THUMBNAIL (width: 120)',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SlabCase(
                company: 'PSA',
                grade: 9.5,
                width: 120,
                cardName: 'Teemo - Swift Scout',
                setLabel: '2025 Origins',
                cardNumber: '307*/298',
                child: Container(
                  color: const Color(0xFF4A2C6B),
                  child: const Center(
                    child: Text(
                      'ART',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // TINY (smallest meaningful size)
            const Text(
              'TINY (width: 80)',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SlabCase(
                company: 'PSA',
                grade: 9,
                width: 80,
                cardName: 'Teemo',
                setLabel: '2025 Origins',
                cardNumber: '307*',
                child: Container(
                  color: const Color(0xFF4A2C6B),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // SIDE BY SIDE COMPARISON ROW (like your collection grid)
            const Text(
              'GRID ROW (3x width: 110 each)',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlabCase(
                  company: 'PSA',
                  grade: 9.5,
                  width: 110,
                  cardName: 'Teemo - Swift Scout',
                  setLabel: '2025 Origins',
                  cardNumber: '307*/298',
                  child: Container(color: const Color(0xFF4A2C6B)),
                ),
                const SizedBox(width: 12),
                SlabCase(
                  company: 'PSA',
                  grade: 9,
                  width: 110,
                  cardName: 'Sett - The Boss',
                  setLabel: '2025 Origins',
                  cardNumber: '310*/298',
                  child: Container(color: const Color(0xFF6B2C2C)),
                ),
                const SizedBox(width: 12),
                SlabCase(
                  company: 'PSA',
                  grade: 9,
                  width: 110,
                  cardName: "Kai'Sa",
                  setLabel: '2025 Origins',
                  cardNumber: '299*/298',
                  child: Container(color: const Color(0xFF2C3B6B)),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2240),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What changed?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Label height: ~34% → ~24% of slab\n'
                    '• Card height: ~66% → ~76% of slab\n'
                    '• Gap label→card: 3.5*s → 1.8*s\n'
                    '• Red rail: 11-14*s → 7.5-9*s\n'
                    '• Internal padding: 3*s → 1.2*s\n'
                    '• Text spacers: 1.6*s → 0.6*s\n'
                    '• Font sizes: slightly smaller for density\n'
                    '• Name line: no Expanded, maxLines capped',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
