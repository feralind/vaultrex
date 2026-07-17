import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Slow-moving ambient glow + spark particles so dark screens feel alive.
class LiveAmbientBackdrop extends StatefulWidget {
  const LiveAmbientBackdrop({
    super.key,
    this.child,
    this.intensity = 1,
  });

  final Widget? child;
  final double intensity;

  @override
  State<LiveAmbientBackdrop> createState() => _LiveAmbientBackdropState();
}

class _LiveAmbientBackdropState extends State<LiveAmbientBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Spark> _sparks;
  final _rng = math.Random(7);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _sparks = List.generate(28, (_) {
      return _Spark(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        r: 0.6 + _rng.nextDouble() * 1.8,
        speed: 0.15 + _rng.nextDouble() * 0.55,
        phase: _rng.nextDouble() * math.pi * 2,
        hue: _rng.nextBool() ? CC.accent : CC.candy,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * math.pi * 2;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: CC.bg),
            // Drifting color orbs
            Positioned(
              left: -80 + 40 * math.sin(t * 0.7),
              top: -60 + 30 * math.cos(t * 0.5),
              child: _orb(
                const Color(0xFF5B8CFF),
                260,
                0.22 * widget.intensity,
              ),
            ),
            Positioned(
              right: -100 + 50 * math.cos(t * 0.6),
              top: 120 + 40 * math.sin(t * 0.45),
              child: _orb(
                const Color(0xFFA78BFA),
                300,
                0.2 * widget.intensity,
              ),
            ),
            Positioned(
              left: 40 + 60 * math.sin(t * 0.35 + 1),
              bottom: -40 + 25 * math.cos(t * 0.4),
              child: _orb(
                const Color(0xFF22D3EE),
                240,
                0.14 * widget.intensity,
              ),
            ),
            Positioned(
              right: 30 + 35 * math.sin(t * 0.55 + 2),
              bottom: 180 + 40 * math.cos(t * 0.65),
              child: _orb(
                const Color(0xFFF59E0B),
                180,
                0.12 * widget.intensity,
              ),
            ),
            // Soft vertical wash that breathes
            Opacity(
              opacity: (0.35 + 0.12 * math.sin(t)).clamp(0.2, 0.5) *
                  widget.intensity,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x332B5BFF),
                      Color(0x000A0C12),
                      Color(0x221A0B2E),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            // Floating sparks
            CustomPaint(
              painter: _SparkPainter(
                sparks: _sparks,
                t: _c.value,
                intensity: widget.intensity,
              ),
              size: Size.infinite,
            ),
            ?child,
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _orb(Color color, double size, double alpha) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _Spark {
  const _Spark({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
    required this.hue,
  });

  final double x;
  final double y;
  final double r;
  final double speed;
  final double phase;
  final Color hue;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.sparks,
    required this.t,
    required this.intensity,
  });

  final List<_Spark> sparks;
  final double t;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final drift = (t * s.speed + s.phase / (math.pi * 2)) % 1.0;
      final x = (s.x + 0.04 * math.sin(t * math.pi * 2 * s.speed + s.phase)) *
          size.width;
      final y = ((s.y - drift) % 1.0) * size.height;
      final twinkle =
          0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * math.pi * 4 + s.phase));
      final paint = Paint()
        ..color = s.hue.withValues(alpha: 0.35 * twinkle * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(x, y), s.r, paint);
      canvas.drawCircle(
        Offset(x, y),
        s.r * 0.45,
        Paint()..color = Colors.white.withValues(alpha: 0.45 * twinkle * intensity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.intensity != intensity;
}
