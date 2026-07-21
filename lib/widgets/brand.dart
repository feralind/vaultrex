import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'knockout_image.dart';

/// Official product name.
abstract final class AppBrand {
  static const name = 'Bindora';
  static const logoAsset = 'assets/logos/bindora.png';
}

class BindoraLogo extends StatelessWidget {
  const BindoraLogo({super.key, this.size = 22, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.asset(
            AppBrand.logoAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => RiftMark(size: size),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 8),
          Text(
            AppBrand.name,
            style: AppText.jakarta(
              fontWeight: FontWeight.w700,
              fontSize: size * 0.72,
              color: CC.ink,
            ),
          ),
        ],
      ],
    );
  }
}

/// Legacy alias for [BindoraLogo].
typedef CandyLogo = BindoraLogo;

/// App mark fallback (bolt badge).
class RiftMark extends StatelessWidget {
  const RiftMark({super.key, this.size = 28, this.framed = true});
  final double size;
  /// When false, renders a free-floating bolt (no circular badge).
  final bool framed;

  @override
  Widget build(BuildContext context) {
    if (!framed) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.bolt_rounded,
          color: const Color(0xFF7EB6FF),
          size: size * 0.92,
          shadows: [
            Shadow(
              color: CC.accent.withValues(alpha: 0.55),
              blurRadius: size * 0.35,
            ),
          ],
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B8CFF), Color(0xFFA78BFA)],
        ),
        boxShadow: [
          BoxShadow(
            color: CC.accent.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.62),
    );
  }
}

/// Free-floating brand logo mark for game pickers (no card / circle frame).
class GameBrandLogo extends StatelessWidget {
  const GameBrandLogo({
    super.key,
    required this.asset,
    this.height = 44,
    this.width,
  });

  final String asset;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isSvg = asset.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        asset,
        height: height,
        width: width,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => SizedBox(height: height, width: width),
      );
    }
    return Image.asset(
      asset,
      height: height,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.image_not_supported_outlined,
        size: height * 0.7,
        color: CC.inkMuted,
      ),
    );
  }
}

/// Transparent game tile: logo + name on ambient bg, subtle selected underline.
class GamePickTile extends StatelessWidget {
  const GamePickTile({
    super.key,
    required this.name,
    required this.logoAsset,
    required this.accent,
    required this.selected,
    required this.enabled,
    this.logoScale = 1,
    this.onTap,
  });

  final String name;
  final String logoAsset;
  final Color accent;
  final bool selected;
  final bool enabled;
  final double logoScale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Opacity(
          opacity: enabled ? 1 : 0.42,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Soft glow behind logo when selected — not a filled card frame.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.45),
                              blurRadius: 22,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: GameBrandLogo(
                    asset: logoAsset,
                    height: 72 * logoScale,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: CC.ink,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: selected ? 36 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.7),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!enabled) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Soon',
                    style: AppText.jakarta(
                      fontSize: 11,
                      color: CC.inkMuted,
                    ),
                  ),
                ] else
                  const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlowBackdrop extends StatelessWidget {
  const GlowBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: CC.bg),
        Positioned(top: -80, right: -60, child: _blob(CC.glowPink, 220)),
        Positioned(bottom: 80, left: -80, child: _blob(CC.glowTeal, 240)),
        Positioned(top: 180, left: -40, child: _blob(CC.glowBlue, 180)),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// Sealed pack visual — centered foil pack or real product art.
class PackVisual extends StatelessWidget {
  const PackVisual({
    super.key,
    required this.title,
    required this.colors,
    this.imageUrl,
    this.tilt = 0,
    this.width = 120,
    this.height = 170,
    this.showSlab = false,
    this.slabChild,
    this.halfCrop = false,
    this.franchiseId,
  });

  final String title;
  final List<Color> colors;
  final String? imageUrl;
  final double tilt;
  final double width;
  final double height;
  final bool showSlab;
  final Widget? slabChild;
  final bool halfCrop;
  /// `pokemon` | `riftbound` — drives foil fallback branding.
  final String? franchiseId;

  @override
  Widget build(BuildContext context) {
    final hasArt = imageUrl != null && imageUrl!.isNotEmpty;
    final pack = Transform.rotate(
      angle: tilt * math.pi / 180,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Soft color bloom behind the pack (subtle — avoid neon halo)
            Positioned(
              left: width * 0.14,
              right: width * 0.14,
              top: height * 0.18,
              bottom: height * 0.12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (colors.isNotEmpty ? colors.first : const Color(0xFF64748B))
                          .withValues(alpha: 0.22),
                      blurRadius: 22,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
            if (hasArt)
              _RealPackArt(
                url: imageUrl!,
                width: width,
                height: height,
                fallback: _FoilPack(
                  title: title,
                  colors: colors,
                  width: width,
                  height: height,
                  franchiseId: franchiseId,
                ),
              )
            else
              _FoilPack(
                title: title,
                colors: colors,
                width: width,
                height: height,
                franchiseId: franchiseId,
              ),
            if (showSlab && slabChild != null)
              Positioned(
                right: -width * 0.12,
                bottom: height * 0.14,
                child: Transform.rotate(
                  angle: 0.06,
                  child: slabChild!,
                ),
              ),
          ],
        ),
      ),
    );

    if (!halfCrop) return pack;
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 0.58,
        child: pack,
      ),
    );
  }
}

class _RealPackArt extends StatelessWidget {
  const _RealPackArt({
    required this.url,
    required this.width,
    required this.height,
    required this.fallback,
  });

  final String url;
  final double width;
  final double height;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    // No white card frame — just the cut-out product with a soft drop shadow.
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: width * 0.18,
            right: width * 0.18,
            top: height * 0.22,
            bottom: height * 0.12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          // Padding so full pack/box silhouette stays visible (not crop-tight).
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.07,
              vertical: height * 0.05,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return KnockoutProductImage(
                  url: url,
                  width: constraints.maxWidth,
                  // Fills slot height — review Flip ratios if pack peeks crop.
                  height: constraints.maxHeight,
                  fit: BoxFit.contain,
                  placeholder: fallback,
                  error: fallback,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FoilPack extends StatelessWidget {
  const _FoilPack({
    required this.title,
    required this.colors,
    required this.width,
    required this.height,
    this.franchiseId,
  });

  final String title;
  final List<Color> colors;
  final double width;
  final double height;
  final String? franchiseId;

  @override
  Widget build(BuildContext context) {
    // LinearGradient / ui.Gradient need ≥2 colors; empty lists crash on paint.
    final stops = colors.isEmpty
        ? const [Color(0xFF64748B), Color(0xFF334155)]
        : colors.length == 1
            ? [colors.first, colors.first]
            : colors;
    final isPokemon = franchiseId == 'pokemon';
    final isMtg = franchiseId == 'mtg';
    final isOnePiece = franchiseId == 'onepiece';
    final brandLabel = isPokemon
        ? 'POKÉMON'
        : isMtg
            ? 'MAGIC'
            : isOnePiece
                ? 'ONE PIECE'
                : 'RIFTBOUND';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: stops,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Metallic sheen
            CustomPaint(painter: _SheenPainter()),
            // Top foil band
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: height * 0.14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
            // Center emblem — franchise mark
            Align(
              alignment: const Alignment(0, -0.18),
              child: isPokemon
                  ? Icon(
                      Icons.catching_pokemon,
                      size: width * 0.42,
                      color: Colors.white.withValues(alpha: 0.92),
                    )
                  : Image.asset(
                      isMtg
                          ? 'assets/logos/mtg.png'
                          : isOnePiece
                              ? 'assets/logos/onepiece.png'
                              : 'assets/logos/riftbound.png',
                      width: width * 0.55,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          RiftMark(size: width * 0.42, framed: false),
                    ),
            ),
            // Brand footer integrated into foil face
            Positioned(
              left: 8,
              right: 8,
              bottom: 12,
              child: Column(
                children: [
                  Text(
                    brandLabel,
                    textAlign: TextAlign.center,
                    style: AppText.jakarta(
                      fontSize: math.max(7, width * 0.075),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.jakarta(
                      fontSize: math.max(9, width * 0.095),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
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

class _SheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.15, 0),
        Offset(size.width * 0.85, size.height),
        [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.0),
        ],
        const [0.35, 0.5, 0.65],
      );
    canvas.drawRect(Offset.zero & size, paint);

    final stripe = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.55, -10),
        Offset(size.width * 0.75, size.height + 10),
        [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
        // dart:ui requires colorStops whenever colors.length != 2.
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, stripe);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// PSA-style mini slab (graded card in case).
///
/// Pass [imageUrls] (HD chase art for a set) to fill the window and rotate
/// every [rotateInterval]. Empty URLs keep the lightning placeholder.
class MiniSlab extends StatefulWidget {
  const MiniSlab({
    super.key,
    this.label = '10',
    this.width = 40,
    this.imageUrls = const [],
    this.rotateInterval = const Duration(milliseconds: 3000),
  });

  final String label;
  final double width;
  final List<String> imageUrls;
  final Duration rotateInterval;

  @override
  State<MiniSlab> createState() => _MiniSlabState();
}

class _MiniSlabState extends State<MiniSlab> {
  static const _cardAspect = 2.5 / 3.5;

  int _index = 0;
  Timer? _timer;
  bool? _tickerOn;

  List<String> get _urls =>
      widget.imageUrls.where((u) => u.isNotEmpty).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _armTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = TickerMode.valuesOf(context).enabled;
    if (_tickerOn == on) return;
    _tickerOn = on;
    if (on) {
      _armTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void didUpdateWidget(covariant MiniSlab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urlsChanged = !_sameUrls(oldWidget.imageUrls, widget.imageUrls);
    if (urlsChanged) {
      _index = 0;
    }
    if (urlsChanged || oldWidget.rotateInterval != widget.rotateInterval) {
      if (_tickerOn != false) _armTimer();
    }
  }

  static bool _sameUrls(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    final urls = _urls;
    if (urls.length < 2) return;
    if (_tickerOn == false) return;
    _timer = Timer.periodic(widget.rotateInterval, (_) {
      if (!mounted) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      setState(() => _index = (_index + 1) % urls.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.width * 1.55;
    final urls = _urls;
    final hasArt = urls.isNotEmpty;
    final url = hasArt ? urls[_index % urls.length] : null;

    return Container(
      width: widget.width,
      height: h,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white70),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            color: const Color(0xFFC8102E),
            child: Text(
              'PSA  ${widget.label}',
              textAlign: TextAlign.center,
              style: AppText.jakarta(
                fontSize: math.max(5.5, widget.width * 0.145),
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: hasArt
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.center,
                        fit: StackFit.expand,
                        children: [
                          ...previous,
                          ?current,
                        ],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(url),
                        child: _SlabCardArt(
                          url: url!,
                          width: widget.width,
                          aspect: _cardAspect,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.bolt_rounded,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: widget.width * 0.35,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlabCardArt extends StatelessWidget {
  const _SlabCardArt({
    required this.url,
    required this.width,
    required this.aspect,
  });

  final String url;
  final double width;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var w = constraints.maxWidth;
          var h = w / aspect;
          if (h > constraints.maxHeight) {
            h = constraints.maxHeight;
            w = h * aspect;
          }
          final cacheW = (w * dpr * 2).round().clamp(1, 800);
          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                memCacheWidth: cacheW,
                fadeInDuration: Duration.zero,
                placeholder: (context, _) => ColoredBox(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
                errorWidget: (context, _, _) => Icon(
                  Icons.bolt_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                  size: width * 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CandyBalance extends StatelessWidget {
  const CandyBalance(this.amount, {super.key});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CC.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cookie, size: 14, color: CC.candy),
          const SizedBox(width: 5),
          Text(
            '$amount',
            style: AppText.jakarta(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: CC.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable cash pill — opens top-up when [onTap] is set.
class CashBalance extends StatelessWidget {
  const CashBalance(this.amount, {super.key, this.onTap});

  final double amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CC.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined, size: 14, color: CC.cash),
          const SizedBox(width: 5),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: AppText.jakarta(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: CC.cash,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.add_circle_outline,
              size: 14,
              color: CC.inkMuted.withValues(alpha: 0.9),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}
