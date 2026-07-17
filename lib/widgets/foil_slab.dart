import 'dart:math';

import 'package:flutter/material.dart';

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
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (widget.autoPlay) {
      _c.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FoilChromatic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoPlay != oldWidget.autoPlay) {
      if (widget.autoPlay) {
        _c.repeat();
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
        final t = _c.value;
        final twinkle = 0.55 + 0.45 * (0.5 + 0.5 * sin(t * pi * 2));
        // Slow diagonal sweep across the card face (−1.2 → 1.4).
        final sweep = -1.2 + 2.6 * t;
        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.hardEdge,
          children: [
            child!,
            // Prism rainbow wash (softLight — keeps art readable).
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
            // Radial burst glint (single layer — quieter than dual glints).
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
            // Broad diagonal white sheen sweep.
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
            // Lightweight sparkle points (no blur filters).
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

/// Tiny specular sparkles — cheap drawRects/circles, no ImageFilter.
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
      final phase = (t * 2 + i * 0.17) % 1.0;
      // Pulse in/out so only a few are bright at once.
      final pulse = (sin(phase * pi * 2) * 0.5 + 0.5);
      if (pulse < 0.35) continue;
      final p = _seeds[i];
      final cx = size.width * p.dx;
      final cy = size.height * p.dy;
      final a = intensity * pulse * 0.85;
      final r = (1.2 + (i % 3) * 0.7) * (0.7 + pulse * 0.5);
      final paint = Paint()..color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(cx, cy), r, paint);
      // Tiny cross glint
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

/// Overall PSA slab proportions (case + label + card window ≈ 2.5 : 4.55).
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

  /// Card title on the PSA label (e.g. "Annie").
  final String? cardName;

  /// Year + set line (e.g. "2025 ORIGINS").
  final String? setLabel;

  /// Collector number (e.g. "001/298").
  final String? cardNumber;

  /// 8-digit cert; generated from seed fields when null.
  final String? certNumber;

  /// Printed year on label when [setLabel] is not provided.
  final String? year;

  /// Force compact label (omit microtext / soft effects). Auto when width < 100.
  final bool? compact;

  /// Entrance slide/fade. Disable in grids so tiles don't shift/crop.
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
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
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
    // Sweep on mid+ thumbs; skip only tiny peeks.
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
            final gap = (3.5 * s).clamp(2.0, 5.0);
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
                            Flexible(
                              flex: compact ? 30 : 34,
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
                            Flexible(
                              flex: compact ? 62 : 66,
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
                    // Continuous shine isolated so PSA label doesn't repaint.
                    if (showShine)
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _shine,
                              builder: (context, _) {
                                final shineT = _shine.value;
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
                                            -1.9 +
                                                3.6 *
                                                    ((shineT + 0.38) % 1.0),
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
    final showMicro = !compact && width >= 120;
    final showCert = width >= 64;
    final showBarcode = !compact && width >= 90;
    final railH = (compact ? 11.0 : 14.0) * s;
    final leftFont = (6.8 * s).clamp(5.0, 9.0);
    final nameFont = (7.6 * s).clamp(5.8, 10.0);
    final rightFont = (6.6 * s).clamp(5.0, 8.8);
    final gradeBig = (22 * s).clamp(12.0, 28.0);

    return Container(
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
            height: railH.clamp(9.0, 18.0),
            child: ColoredBox(
              color: psaRed,
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: (5 * s).clamp(3.0, 7.0)),
                child: Row(
                  children: [
                    Text(
                      'PSA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: (10.5 * s).clamp(7.0, 13.0),
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
                            fontSize: (4.6 * s).clamp(3.8, 6.2),
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
              padding: EdgeInsets.fromLTRB(
                (4.5 * s).clamp(2.5, 6.5),
                (3 * s).clamp(1.8, 4.5),
                (4.5 * s).clamp(2.5, 6.5),
                (2.5 * s).clamp(1.5, 4.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main two-column body (set/name left · # / GEM MT / grade right)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 11,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                setLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: leftFont,
                                  letterSpacing: 0.15,
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: (1.6 * s).clamp(0.8, 2.5)),
                              Expanded(
                                child: Text(
                                  nameLine,
                                  maxLines: compact ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: nameFont,
                                    height: 1.08,
                                  ),
                                ),
                              ),
                              Text(
                                descriptor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: psaRed,
                                  fontWeight: FontWeight.w900,
                                  fontSize: leftFont,
                                  letterSpacing: 0.4,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: (4 * s).clamp(2.0, 6.0)),
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                    fontSize: rightFont,
                                    height: 1.05,
                                  ),
                                )
                              else
                                SizedBox(height: rightFont * 1.05),
                              SizedBox(height: (1.4 * s).clamp(0.6, 2.2)),
                              Text(
                                descriptor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: rightFont,
                                  letterSpacing: 0.2,
                                  height: 1,
                                ),
                              ),
                              const Spacer(),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  gradeLabel,
                                  style: TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: gradeBig,
                                    height: 0.92,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showCert) ...[
                    SizedBox(height: (2.2 * s).clamp(1.0, 3.5)),
                    // Bottom: faux barcode · cert · PSA mark
                    SizedBox(
                      height: (showBarcode ? 11.0 : 8.0) * s.clamp(0.85, 1.2),
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
                            SizedBox(width: (3 * s).clamp(2.0, 5.0)),
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
                                fontSize: (5.8 * s).clamp(4.5, 7.5),
                                letterSpacing: 0.1,
                                height: 1,
                              ),
                            ),
                          ),
                          Container(
                            width: (12 * s).clamp(9.0, 15.0),
                            height: (10 * s).clamp(7.5, 13.0),
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
                                fontSize: (5.2 * s).clamp(4.0, 7.0),
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
              ),
            ),
          ),
        ],
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
