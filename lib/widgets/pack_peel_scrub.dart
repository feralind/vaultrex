import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_text.dart';

/// Pre-rendered pack peel driven by finger progress (Rare Candy–style scrub).
///
/// Prefers scrubbing PNG frames (smooth seeks). Falls back to [video_player]
/// seek on `assets/rip/peel_generic.mp4` when frames are unavailable.
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

  /// 0 = sealed, 1 = fully peeled.
  final double progress;
  final bool showHint;
  final bool interactive;
  final void Function(DragUpdateDetails)? onTearUpdate;
  final VoidCallback? onTearEnd;
  final VoidCallback? onTap;

  static const frameCount = 48;
  static const videoAsset = 'assets/rip/peel_generic.mp4';
  static const sealedAsset = 'assets/rip/peel_sealed.png';

  static String frameAsset(int index) {
    final i = index.clamp(0, frameCount - 1);
    return 'assets/rip/frames/peel_${i.toString().padLeft(2, '0')}.png';
  }

  @override
  State<ScrubPeelStage> createState() => _ScrubPeelStageState();
}

class _ScrubPeelStageState extends State<ScrubPeelStage> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _useFrames = true;
  int _frameIndex = 0;
  Duration? _lastSeek;
  double _lastHapticAt = 0;

  @override
  void initState() {
    super.initState();
    _frameIndex =
        (widget.progress.clamp(0.0, 1.0) * (ScrubPeelStage.frameCount - 1))
            .round();
    _initVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyProgress(widget.progress);
      _precacheFrames();
    });
  }

  Future<void> _precacheFrames() async {
    if (!mounted) return;
    // Warm first/mid/last; rest load on demand via Image.asset cache.
    for (final i in [0, 16, 32, ScrubPeelStage.frameCount - 1]) {
      await precacheImage(AssetImage(ScrubPeelStage.frameAsset(i)), context);
      if (!mounted) return;
    }
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset(ScrubPeelStage.videoAsset);
    try {
      await c.initialize();
      await c.setLooping(false);
      await c.setVolume(0);
      await c.pause();
      await c.seekTo(Duration.zero);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _video = c;
        _videoReady = true;
        // Frames stay primary for scrub smoothness; video warms for finish.
      });
    } catch (_) {
      await c.dispose();
      if (mounted) {
        setState(() {
          _videoReady = false;
          _useFrames = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant ScrubPeelStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _applyProgress(widget.progress);
    }
  }

  void _applyProgress(double progress) {
    final p = progress.clamp(0.0, 1.0);
    final idx = (p * (ScrubPeelStage.frameCount - 1)).round();
    if (idx != _frameIndex) {
      setState(() => _frameIndex = idx);
    }

    // Milestone haptics.
    for (final mark in [0.25, 0.5, 0.72, 0.92]) {
      if (_lastHapticAt < mark && p >= mark) {
        HapticFeedback.lightImpact();
        _lastHapticAt = mark;
      }
    }

    final v = _video;
    if (v == null || !_videoReady || !v.value.isInitialized) return;
    final dur = v.value.duration;
    if (dur == Duration.zero) return;
    final target = Duration(
      milliseconds: (dur.inMilliseconds * p).round(),
    );
    // Throttle seeks ~1/30s to avoid decoder stutter.
    if (_lastSeek != null &&
        (target - _lastSeek!).abs() < const Duration(milliseconds: 33)) {
      return;
    }
    _lastSeek = target;
    unawaited(v.seekTo(target));
  }

  @override
  void dispose() {
    final v = _video;
    _video = null;
    v?.dispose();
    super.dispose();
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
                  child: _buildPeelVisual(),
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

  Widget _buildPeelVisual() {
    if (_useFrames) {
      return Image.asset(
        ScrubPeelStage.frameAsset(_frameIndex),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Image.asset(
          ScrubPeelStage.sealedAsset,
          fit: BoxFit.cover,
        ),
      );
    }
    final v = _video;
    if (v != null && _videoReady && v.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: v.value.size.width,
          height: v.value.size.height,
          child: VideoPlayer(v),
        ),
      );
    }
    return Image.asset(ScrubPeelStage.sealedAsset, fit: BoxFit.cover);
  }
}
