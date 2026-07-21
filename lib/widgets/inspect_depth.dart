import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Premium inspect depth: fake extrusion + rim light so tilt reads as a
/// physical card / PSA slab — inspect-only (grids stay flat & cheap).
class InspectDepthShell extends StatelessWidget {
  const InspectDepthShell({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.child,
    this.slab = false,
    this.borderRadius = 14,
  });

  /// Radians — same space as [CardInspectPage] rotateX / rotateY.
  final double tiltX;
  final double tiltY;
  final Widget child;
  final bool slab;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final tx = tiltX.clamp(-0.55, 0.55);
    final ty = tiltY.clamp(-0.55, 0.55);
    final mag = math.sqrt(tx * tx + ty * ty).clamp(0.0, 0.55);

    // How much of the edge is revealed (0 flat → 1 hard tilt).
    final reveal = (mag / 0.42).clamp(0.0, 1.0);
    final layers = slab ? 14 : 7;
    final step = slab ? 1.15 : 0.72;

    // Parallax push of the stack (screen space).
    final pushX = ty * (slab ? 11.0 : 6.5);
    final pushY = -tx * (slab ? 11.0 : 6.5);

    final radius = BorderRadius.circular(
      slab ? math.max(4.0, borderRadius * 0.35) : borderRadius,
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Soft contact shadow — shifts opposite the tilt.
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(-pushX * 0.55, -pushY * 0.55 + 10 + reveal * 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45 + reveal * 0.25),
                    blurRadius: 28 + reveal * 18,
                    spreadRadius: 1,
                    offset: Offset(-ty * 14, tx * 10 + 12),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Extruded thickness stack (back → front), sized to the face.
        for (var i = layers; i >= 1; i--)
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(
                pushX * (i / layers) +
                    ty.sign * step * i * (0.35 + reveal * 0.65),
                pushY * (i / layers) -
                    tx.sign * step * i * (0.35 + reveal * 0.65),
              ),
              child: _ThicknessPlate(
                slab: slab,
                layer: i,
                layers: layers,
                radius: radius,
                reveal: reveal,
              ),
            ),
          ),

        // Living face (sizes the Stack).
        Transform.translate(
          offset: Offset(pushX * 0.08, pushY * 0.08),
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              child,
              Positioned.fill(
                child: IgnorePointer(
                  child: _TiltLighting(
                    tiltX: tx,
                    tiltY: ty,
                    slab: slab,
                    radius: radius,
                  ),
                ),
              ),
              if (reveal > 0.08)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _EdgeBevelPainter(
                        tiltX: tx,
                        tiltY: ty,
                        slab: slab,
                        radius: borderRadius,
                        strength: reveal,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThicknessPlate extends StatelessWidget {
  const _ThicknessPlate({
    required this.slab,
    required this.layer,
    required this.layers,
    required this.radius,
    required this.reveal,
  });

  final bool slab;
  final int layer;
  final int layers;
  final BorderRadius radius;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final t = layer / layers;
    // Cardboard core vs plastic case.
    final Color base;
    if (slab) {
      // Cool acrylic stack — lighter near the face, darker deep.
      base = Color.lerp(
        const Color(0xFF9AA8B8),
        const Color(0xFF3A4554),
        1.0 - t,
      )!;
    } else {
      // Paper stock: cream → kraft near the deep edge.
      base = Color.lerp(
        const Color(0xFFE8E0D4),
        const Color(0xFF6B5A45),
        1.0 - t,
      )!;
    }

    final alpha = (0.55 + t * 0.4) * (0.35 + reveal * 0.65);

    return Opacity(
      opacity: alpha.clamp(0.0, 1.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: base,
          border: Border.all(
            color: (slab ? const Color(0xFFCBD5E1) : const Color(0xFFC4B8A8))
                .withValues(alpha: 0.35 * t),
            width: slab ? 0.8 : 0.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: slab ? 0.22 * t : 0.12 * t),
              base,
              Colors.black.withValues(alpha: 0.18 * (1 - t)),
            ],
          ),
        ),
        // Match face footprint; parent Stack sizes to child.
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TiltLighting extends StatelessWidget {
  const _TiltLighting({
    required this.tiltX,
    required this.tiltY,
    required this.slab,
    required this.radius,
  });

  final double tiltX;
  final double tiltY;
  final bool slab;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final lx = (-tiltY * 1.6).clamp(-1.0, 1.0);
    final ly = (tiltX * 1.4).clamp(-1.0, 1.0);
    final mag = math.sqrt(tiltX * tiltX + tiltY * tiltY);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Specular wash follows the high corner.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(lx, ly),
                radius: slab ? 1.05 : 0.95,
                colors: [
                  Colors.white.withValues(
                    alpha: (slab ? 0.16 : 0.10) * (0.25 + mag * 1.4),
                  ),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.72],
              ),
            ),
          ),
          // Opposite shade for volume.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-lx * 0.9, -ly * 0.9),
                radius: 1.1,
                colors: [
                  Colors.black.withValues(
                    alpha: (slab ? 0.14 : 0.10) * (0.2 + mag * 1.2),
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (slab)
            // Plastic lid gloss streak.
            Opacity(
              opacity: (0.12 + mag * 0.35).clamp(0.0, 0.45),
              child: Transform.rotate(
                angle: -0.55 + tiltY * 0.35,
                child: Align(
                  alignment: Alignment(-0.2 + tiltY, -0.15 + tiltX),
                  child: Container(
                    width: 48,
                    height: 420,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Draws a thin physical edge on the revealed side(s) when tilted.
class _EdgeBevelPainter extends CustomPainter {
  _EdgeBevelPainter({
    required this.tiltX,
    required this.tiltY,
    required this.slab,
    required this.radius,
    required this.strength,
  });

  final double tiltX;
  final double tiltY;
  final bool slab;
  final double radius;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || strength < 0.05) return;
    final w = size.width;
    final h = size.height;
    final depth = (slab ? 10.0 : 5.0) * strength;
    final r = radius.clamp(2.0, 18.0);

    final edgePaint = Paint()..style = PaintingStyle.fill;
    final hi = Paint()..style = PaintingStyle.stroke;
    hi.strokeWidth = slab ? 1.2 : 0.9;

    // Right edge when tilting left (positive rotateY shows right thickness).
    if (tiltY > 0.04) {
      final a = (tiltY / 0.42).clamp(0.0, 1.0) * strength;
      edgePaint.shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: slab
            ? [
                const Color(0xFFD8E0EA).withValues(alpha: 0.55 * a),
                const Color(0xFF5B6775).withValues(alpha: 0.85 * a),
              ]
            : [
                const Color(0xFFF2EADF).withValues(alpha: 0.5 * a),
                const Color(0xFF5C4A38).withValues(alpha: 0.8 * a),
              ],
      ).createShader(Rect.fromLTWH(w - 1, 0, depth, h));
      final path = Path()
        ..moveTo(w - 0.5, r)
        ..lineTo(w - 0.5, h - r)
        ..lineTo(w + depth, h - r * 0.7)
        ..lineTo(w + depth, r * 0.7)
        ..close();
      canvas.drawPath(path, edgePaint);
      hi.color = Colors.white.withValues(alpha: 0.25 * a);
      canvas.drawLine(Offset(w, r), Offset(w, h - r), hi);
    }

    // Left edge.
    if (tiltY < -0.04) {
      final a = (-tiltY / 0.42).clamp(0.0, 1.0) * strength;
      edgePaint.shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: slab
            ? [
                const Color(0xFFD8E0EA).withValues(alpha: 0.55 * a),
                const Color(0xFF5B6775).withValues(alpha: 0.85 * a),
              ]
            : [
                const Color(0xFFF2EADF).withValues(alpha: 0.5 * a),
                const Color(0xFF5C4A38).withValues(alpha: 0.8 * a),
              ],
      ).createShader(Rect.fromLTWH(-depth, 0, depth, h));
      final path = Path()
        ..moveTo(0.5, r)
        ..lineTo(0.5, h - r)
        ..lineTo(-depth, h - r * 0.7)
        ..lineTo(-depth, r * 0.7)
        ..close();
      canvas.drawPath(path, edgePaint);
      hi.color = Colors.white.withValues(alpha: 0.22 * a);
      canvas.drawLine(Offset(0, r), Offset(0, h - r), hi);
    }

    // Bottom edge (tilt back / rotateX positive typically).
    if (tiltX > 0.04) {
      final a = (tiltX / 0.42).clamp(0.0, 1.0) * strength;
      final d = depth * 0.85;
      edgePaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: slab
            ? [
                const Color(0xFFB0BCC8).withValues(alpha: 0.4 * a),
                const Color(0xFF2F3844).withValues(alpha: 0.75 * a),
              ]
            : [
                const Color(0xFFE6DCCE).withValues(alpha: 0.4 * a),
                const Color(0xFF4A3B2C).withValues(alpha: 0.75 * a),
              ],
      ).createShader(Rect.fromLTWH(0, h - 1, w, d));
      final path = Path()
        ..moveTo(r, h - 0.5)
        ..lineTo(w - r, h - 0.5)
        ..lineTo(w - r * 0.7, h + d)
        ..lineTo(r * 0.7, h + d)
        ..close();
      canvas.drawPath(path, edgePaint);
    }

    // Top edge.
    if (tiltX < -0.04) {
      final a = (-tiltX / 0.42).clamp(0.0, 1.0) * strength;
      final d = depth * 0.85;
      edgePaint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: slab
            ? [
                const Color(0xFFB0BCC8).withValues(alpha: 0.4 * a),
                const Color(0xFF2F3844).withValues(alpha: 0.75 * a),
              ]
            : [
                const Color(0xFFE6DCCE).withValues(alpha: 0.4 * a),
                const Color(0xFF4A3B2C).withValues(alpha: 0.75 * a),
              ],
      ).createShader(Rect.fromLTWH(0, -d, w, d));
      final path = Path()
        ..moveTo(r, 0.5)
        ..lineTo(w - r, 0.5)
        ..lineTo(w - r * 0.7, -d)
        ..lineTo(r * 0.7, -d)
        ..close();
      canvas.drawPath(path, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeBevelPainter old) =>
      old.tiltX != tiltX ||
      old.tiltY != tiltY ||
      old.strength != strength ||
      old.slab != slab;
}

/// Stronger perspective matrix for inspect stage.
Matrix4 inspectPerspective({
  required double tiltX,
  required double tiltY,
  double perspective = 0.00165,
}) {
  return Matrix4.identity()
    ..setEntry(3, 2, perspective)
    ..rotateX(tiltX)
    ..rotateY(tiltY);
}

double inspectLightness(double tiltX, double tiltY) {
  final m = math.sqrt(tiltX * tiltX + tiltY * tiltY);
  return lerpDouble(0.0, 1.0, (m / 0.42).clamp(0.0, 1.0)) ?? 0;
}
