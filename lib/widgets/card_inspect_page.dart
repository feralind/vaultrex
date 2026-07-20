import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/scrydex_art.dart';
import '../dev/dev_studio.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import 'foil_slab.dart';
import 'game_widgets.dart';

/// Fullscreen card inspect — centered, finger-tilt, pinch zoom, dark stage.
Future<void> openCardInspect(
  BuildContext context, {
  required CardDef def,
  bool foil = false,
  double? grade,
  GradingCompany? company,
  String? heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim, _) {
        return FadeTransition(
          opacity: anim,
          child: CardInspectPage(
            def: def,
            foil: foil,
            grade: grade,
            company: company,
            heroTag: heroTag,
          ),
        );
      },
    ),
  );
}

class CardInspectPage extends StatefulWidget {
  const CardInspectPage({
    super.key,
    required this.def,
    this.foil = false,
    this.grade,
    this.company,
    this.heroTag,
  });

  final CardDef def;
  final bool foil;
  final double? grade;
  final GradingCompany? company;
  final String? heroTag;

  @override
  State<CardInspectPage> createState() => _CardInspectPageState();
}

class _CardInspectPageState extends State<CardInspectPage>
    with SingleTickerProviderStateMixin {
  bool _metaVisible = true;

  // Tilt in radians (rotateX / rotateY).
  double _tiltX = 0;
  double _tiltY = 0;
  double _scale = 1;

  late final AnimationController _spring;
  Animation<double>? _sx;
  Animation<double>? _sy;

  static const _maxTilt = 0.42; // ~24°
  static const _maxScale = 2.8;
  static const _minScale = 0.92;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
        if (_sx == null || _sy == null) return;
        setState(() {
          _tiltX = _sx!.value;
          _tiltY = _sy!.value;
        });
      });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _springFlat() {
    _sx = Tween<double>(begin: _tiltX, end: 0).animate(
      CurvedAnimation(parent: _spring, curve: Curves.easeOutCubic),
    );
    _sy = Tween<double>(begin: _tiltY, end: 0).animate(
      CurvedAnimation(parent: _spring, curve: Curves.easeOutCubic),
    );
    _spring.forward(from: 0);
  }

  double _baseScale = 1;

  void _onScaleStart(ScaleStartDetails d) {
    _baseScale = _scale;
    if (_spring.isAnimating) _spring.stop();
  }

  void _onScaleUpdate2(ScaleUpdateDetails d) {
    setState(() {
      if (d.pointerCount >= 2) {
        _scale = (_baseScale * d.scale).clamp(_minScale, _maxScale);
      } else {
        final dx = d.focalPointDelta.dx / 140;
        final dy = d.focalPointDelta.dy / 140;
        _tiltY = (_tiltY + dx * 0.85).clamp(-_maxTilt, _maxTilt);
        _tiltX = (_tiltX - dy * 0.85).clamp(-_maxTilt, _maxTilt);
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_scale < 1.05) _springFlat();
  }

  void _reset() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
      _scale = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final graded = widget.grade != null && widget.grade! > 0;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final aspect = def.artAspectRatio;

    final maxW = size.width - 32;
    final maxH = size.height - pad.top - pad.bottom - 140;
    var cardW = maxW;
    var cardH = cardW / aspect;
    if (cardH > maxH) {
      cardH = maxH;
      cardW = cardH * aspect;
    }

    final art = graded
        ? SlabCase(
            company: widget.company?.label ?? 'PSA',
            grade: widget.grade!,
            width: cardW.clamp(120, 420),
            compact: false,
            animateEnter: false,
            cardName: def.name,
            setLabel: def.slabSetLabel,
            cardNumber: def.number,
            child: CardArt(
              url: def.inspectArtUrl,
              foil: widget.foil,
              autoPlay: true,
              width: double.infinity,
              height: double.infinity,
              radius: 4,
              fit: BoxFit.contain,
            ),
          )
        : CardArt(
            url: def.inspectArtUrl,
            foil: widget.foil,
            autoPlay: true,
            width: cardW,
            height: cardH,
            radius: 14,
            fit: BoxFit.contain,
          );

    Widget card = widget.heroTag != null
        ? Hero(tag: widget.heroTag!, child: art)
        : art;

    card = DevNudge(
      id: 'inspect-card',
      label: 'Inspect card',
      child: card,
    );

    // Perspective tilt + scale, kept centered.
    final tilted = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.00135)
        ..rotateX(_tiltX)
        ..rotateY(_tiltY),
      child: Transform.scale(
        scale: _scale,
        child: card,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.05),
                  radius: 0.85,
                  colors: [
                    Color(0xFF1A2240),
                    Color(0xFF0B0F1A),
                    Color(0xFF05070E),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _metaVisible = !_metaVisible),
              onDoubleTap: _reset,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate2,
              onScaleEnd: _onScaleEnd,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: pad.top + 48,
                    bottom: pad.bottom + 72,
                  ),
                  child: tilted,
                ),
              ),
            ),
            Positioned(
              top: pad.top + 8,
              left: 8,
              right: 8,
              child: AnimatedOpacity(
                opacity: _metaVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Reset tilt / zoom',
                      onPressed: _reset,
                      icon: const Icon(
                        Icons.center_focus_strong_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: pad.bottom + 16,
              child: AnimatedOpacity(
                opacity: _metaVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_metaVisible,
                  child: _InspectMeta(
                    def: def,
                    foil: widget.foil,
                    grade: widget.grade,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectMeta extends StatelessWidget {
  const _InspectMeta({
    required this.def,
    required this.foil,
    this.grade,
  });

  final CardDef def;
  final bool foil;
  final double? grade;

  @override
  Widget build(BuildContext context) {
    final bits = <String>[
      def.franchiseDisplayName,
      if (ScrydexArt.printedNumberLabel(def) != null)
        ScrydexArt.printedNumberLabel(def)!
      else ...[
        def.setCode,
        if (def.number != null) '#${def.number}',
      ],
      if (def.cardType != null && def.cardType!.isNotEmpty)
        def.cardType!.split(';').first.trim(),
      if (def.domain != null && def.domain!.isNotEmpty) def.domain!,
      def.rarity.label,
      if (foil) 'Foil',
      if (grade != null)
        'PSA ${grade! >= 10 ? '10' : grade!.toStringAsFixed(grade! % 1 == 0 ? 0 : 1)}',
      if (def.artist != null && def.artist!.isNotEmpty) 'Illus. ${def.artist}',
    ];

    final setLine = ScrydexArt.displaySetLine(def);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (ScrydexArt.expansionLogoUrl(def) != null) ...[
                  ScrydexExpansionLogo(setCode: def.setCode, height: 20),
                  const SizedBox(width: 8),
                ],
                if (ScrydexArt.expansionSymbolUrl(def) != null) ...[
                  ScrydexExpansionSymbol(setCode: def.setCode, height: 18),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    def.name,
                    style: AppText.jakarta(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              setLine,
              style: AppText.jakarta(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bits.join(' · '),
              style: AppText.jakarta(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Drag to tilt · pinch zoom · double-tap reset',
              style: AppText.jakarta(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
