import 'package:flutter/material.dart';

import '../services/bindora_feel.dart';
import '../theme/app_text.dart';

/// Pre-rendered pack peel driven by finger progress (Rare Candy–style scrub).
///
/// Scrubs PNG frames in [assets/rip/frames/]. The exported tail (≈36–47) is
/// near-blank, so scrub progress maps onto [0 … lastGoodFrame] only.
class ScrubPeelStage extends StatefulWidget {
  const ScrubPeelStage({
    super.key,
    required this.progress,
    required this.showHint,
    required this.interactive,
    this.onTearUpdate,
    this.onTearEnd,
    this.onTap,
  });

  /// 0 = sealed, 1 = fully peeled (clamped to [lastGoodFrame] artwork).
  final double progress;
  final bool showHint;
  final bool interactive;
  final void Function(DragUpdateDetails)? onTearUpdate;
  final VoidCallback? onTearEnd;
  final VoidCallback? onTap;

  static const frameCount = 48;

  /// Last frame that still has real peel artwork (unique-color cliff after this).
  /// Re-export frames 36–47 when source art is fixed, then raise this.
  static const lastGoodFrame = 35;

  static const sealedAsset = 'assets/rip/peel_sealed.png';

  static String frameAsset(int index) {
    final i = index.clamp(0, frameCount - 1);
    return 'assets/rip/frames/peel_${i.toString().padLeft(2, '0')}.png';
  }

  @override
  State<ScrubPeelStage> createState() => _ScrubPeelStageState();
}

class _ScrubPeelStageState extends State<ScrubPeelStage> {
  int _frameIndex = 0;
  double _lastHapticAt = 0;

  @override
  void initState() {
    super.initState();
    _frameIndex = _indexForProgress(widget.progress);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyProgress(widget.progress);
      _precacheFrames();
    });
  }

  Future<void> _precacheFrames() async {
    if (!mounted) return;
    await Future.wait([
      for (var i = 0; i <= ScrubPeelStage.lastGoodFrame; i++)
        precacheImage(AssetImage(ScrubPeelStage.frameAsset(i)), context),
    ]);
  }

  @override
  void didUpdateWidget(covariant ScrubPeelStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _applyProgress(widget.progress);
    }
  }

  int _indexForProgress(double progress) {
    final p = progress.clamp(0.0, 1.0);
    return (p * ScrubPeelStage.lastGoodFrame).round();
  }

  void _applyProgress(double progress) {
    final p = progress.clamp(0.0, 1.0);
    final idx = _indexForProgress(p);
    if (idx != _frameIndex) {
      setState(() => _frameIndex = idx);
    }

    for (final mark in [0.18, 0.34, 0.5, 0.66, 0.82, 0.94]) {
      if (_lastHapticAt < mark && p >= mark) {
        BindoraHaptics.peelTick();
        BindoraSounds.peelTick();
        _lastHapticAt = mark;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth * 0.92;
        final maxH = constraints.maxHeight * 0.88;
        // Source peel is 720x1280 — fit contain.
        const aspect = 720 / 1280;
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    ScrubPeelStage.frameAsset(_frameIndex),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => Image.asset(
                      ScrubPeelStage.sealedAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.interactive)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTap,
                  onVerticalDragUpdate: widget.onTearUpdate,
                  onVerticalDragEnd: (_) => widget.onTearEnd?.call(),
                  child: widget.showHint
                      ? AnimatedOpacity(
                          opacity: p < 0.15 ? 1 : (1 - p * 1.2).clamp(0.0, 1.0),
                          duration: const Duration(milliseconds: 160),
                          child: Align(
                            alignment: const Alignment(0, -0.78),
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
                        )
                      : widget.onTap != null
                          ? Align(
                              alignment: const Alignment(0, -0.78),
                              child: Text(
                                'Tap to rip',
                                style: AppText.jakarta(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            )
                          : const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }
}
