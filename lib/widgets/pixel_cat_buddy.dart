import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/bindora_feel.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Animation banks under assets/mascot/pixel_cat/
enum CatAnim { idle, walk, scratch, happy }

extension on CatAnim {
  String get folder => name;
  int get frameCount => switch (this) {
        CatAnim.idle => 4,
        CatAnim.walk => 8,
        CatAnim.scratch => 6,
        CatAnim.happy => 4,
      };
  Duration get frameDuration => switch (this) {
        CatAnim.idle => const Duration(milliseconds: 180),
        CatAnim.walk => const Duration(milliseconds: 70),
        CatAnim.scratch => const Duration(milliseconds: 90),
        CatAnim.happy => const Duration(milliseconds: 110),
      };
  String asset(int i) =>
      'assets/mascot/pixel_cat/$folder/${i.toString().padLeft(2, '0')}.png';
}

/// Compact static buddy (optional corners). Prefer [WanderingPixelCat].
class PixelCatBuddy extends StatelessWidget {
  const PixelCatBuddy({
    super.key,
    this.size = 48,
    this.showHint = false,
    this.compact = false,
  });

  final double size;
  final bool showHint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _SpriteCat(
      size: size,
      showHint: showHint,
      compact: compact,
      lockedAnim: CatAnim.idle,
    );
  }
}

/// Freely wandering tuxedo pixel cat with walk / idle / scratch / happy banks.
class WanderingPixelCat extends StatefulWidget {
  const WanderingPixelCat({super.key, this.size = 64});

  final double size;

  @override
  State<WanderingPixelCat> createState() => _WanderingPixelCatState();
}

class _WanderingPixelCatState extends State<WanderingPixelCat>
    with SingleTickerProviderStateMixin {
  final _rng = math.Random();
  late final AnimationController _move;

  Offset _from = const Offset(0.78, 0.06);
  Offset _to = const Offset(0.78, 0.06);
  bool _facingRight = false;

  CatAnim _anim = CatAnim.idle;
  int _frame = 0;
  Timer? _frameTimer;
  Timer? _planTimer;
  String? _bubble;
  double _petAccum = 0;
  bool _busy = false;
  bool _dead = false;

  @override
  void initState() {
    super.initState();
    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted && !_busy) {
          setState(() {
            _from = _to;
            _anim = CatAnim.idle;
            _frame = 0;
          });
          _restartFrameClock();
        }
      });
    _restartFrameClock();
    _schedulePlan();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precache();
    });
  }

  Future<void> _precache() async {
    if (!mounted) return;
    for (final a in CatAnim.values) {
      for (var i = 0; i < a.frameCount; i++) {
        await precacheImage(AssetImage(a.asset(i)), context);
        if (!mounted) return;
      }
    }
  }

  @override
  void dispose() {
    _dead = true;
    _frameTimer?.cancel();
    _planTimer?.cancel();
    _move.dispose();
    super.dispose();
  }

  void _restartFrameClock() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(_anim.frameDuration, (_) {
      if (!mounted || _dead) return;
      setState(() => _frame = (_frame + 1) % _anim.frameCount);
    });
  }

  void _setAnim(CatAnim a, {bool resetFrame = true}) {
    if (_anim == a && !resetFrame) return;
    _anim = a;
    if (resetFrame) _frame = 0;
    _restartFrameClock();
  }

  void _schedulePlan() {
    _planTimer?.cancel();
    _planTimer = Timer(Duration(milliseconds: 1400 + _rng.nextInt(2200)), () {
      if (!mounted || _dead || _busy) {
        _schedulePlan();
        return;
      }
      // Occasional scratch while idle
      if (_anim == CatAnim.idle && _rng.nextDouble() < 0.28) {
        _playScratchThenIdle();
        _schedulePlan();
        return;
      }
      final next = Offset(
        0.06 + _rng.nextDouble() * 0.82,
        0.02 + _rng.nextDouble() * 0.52,
      );
      final dist = (next - _pos).distance;
      setState(() {
        _from = _pos;
        _to = next;
        _facingRight = next.dx >= _from.dx;
        _setAnim(CatAnim.walk);
      });
      _move
        ..duration = Duration(
          milliseconds: (1800 + dist * 2200).round().clamp(1600, 4200),
        )
        ..forward(from: 0);
      _schedulePlan();
    });
  }

  Future<void> _playScratchThenIdle() async {
    _busy = true;
    _move.stop();
    setState(() {
      _from = _pos;
      _to = _from;
      _setAnim(CatAnim.scratch);
      _bubble = 'scratch';
    });
    await Future<void>.delayed(
      _anim.frameDuration * (_anim.frameCount * 2),
    );
    if (!mounted || _dead) return;
    setState(() {
      _bubble = null;
      _setAnim(CatAnim.idle);
      _busy = false;
    });
  }

  Offset get _pos {
    final t = Curves.easeInOut.transform(_move.value.clamp(0.0, 1.0));
    return Offset.lerp(_from, _to, t)!;
  }

  Future<void> _reactHappy(String line) async {
    _busy = true;
    _move.stop();
    setState(() {
      _from = _pos;
      _to = _from;
      _setAnim(CatAnim.happy);
      _bubble = line;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _dead) return;
    setState(() {
      _bubble = null;
      _setAnim(CatAnim.idle);
      _busy = false;
    });
  }

  void _tap() {
    HapticFeedback.selectionClick();
    BindoraSounds.uiClick();
    const lines = ['mrrp', 'nya~', ':3', 'hewwo'];
    _reactHappy(lines[_rng.nextInt(lines.length)]);
  }

  void _pet(DragUpdateDetails d) {
    _petAccum += d.delta.distance;
    if (_petAccum < 14) return;
    _petAccum = 0;
    HapticFeedback.lightImpact();
    BindoraSounds.uiClick();
    const lines = ['purrrr', '♡', 'soft', 'yes…'];
    _reactHappy(lines[_rng.nextInt(lines.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _move,
      builder: (context, _) {
        final p = _pos;
        return Align(
          alignment: Alignment(p.dx * 2 - 1, p.dy * 2 - 1),
          child: GestureDetector(
            onTap: _tap,
            onPanUpdate: _pet,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_bubble != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _Bubble(text: _bubble!),
                  ),
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                    _facingRight ? -1.0 : 1.0,
                    1.0,
                    1.0,
                  ),
                  child: Image.asset(
                    _anim.asset(_frame % _anim.frameCount),
                    width: s,
                    height: s,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => SizedBox(width: s, height: s),
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

class _SpriteCat extends StatefulWidget {
  const _SpriteCat({
    required this.size,
    required this.showHint,
    required this.compact,
    required this.lockedAnim,
  });

  final double size;
  final bool showHint;
  final bool compact;
  final CatAnim lockedAnim;

  @override
  State<_SpriteCat> createState() => _SpriteCatState();
}

class _SpriteCatState extends State<_SpriteCat> {
  int _frame = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.lockedAnim.frameDuration, (_) {
      if (!mounted) return;
      setState(
        () => _frame = (_frame + 1) % widget.lockedAnim.frameCount,
      );
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.compact && widget.showHint)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: _Bubble(text: 'pet me'),
          ),
        Image.asset(
          widget.lockedAnim.asset(_frame),
          width: widget.size,
          height: widget.size,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CC.cardSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CC.line),
      ),
      child: Text(
        text,
        style: AppText.jakarta(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: CC.inkMuted,
        ),
      ),
    );
  }
}
