import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dev/dev_studio.dart';
import '../dev/dev_studio_panel.dart';
import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'foil_slab.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {super.key, this.style});
  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      '\$${value.toStringAsFixed(2)}',
      style: style ??
          AppText.jakarta(fontWeight: FontWeight.w800, color: CC.ink),
    );
  }
}

class CardArt extends StatelessWidget {
  const CardArt({
    super.key,
    required this.url,
    this.width = 110,
    this.height = 154,
    this.foil = false,
    this.radius = 12,
    this.autoPlay = true,
    /// Face-on full card — avoid [BoxFit.cover] cropping edges / landmarks.
    this.fit = BoxFit.contain,
  });

  final String url;
  final double width;
  final double height;
  final bool foil;
  final double radius;
  /// Continuous foil animation — off in grids/lists for performance.
  final bool autoPlay;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return _buildArt(context, url);

    return ListenableBuilder(
      listenable: DevStudio.instance,
      builder: (context, _) {
        final resolved = DevStudio.instance.resolveImage(url);
        return GestureDetector(
          onLongPress: () =>
              devSelectImageSource(context, url, label: 'Card art'),
          child: _buildArt(context, resolved),
        );
      },
    );
  }

  Widget _buildArt(BuildContext context, String resolved) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final int? cacheW = (width.isFinite && width > 0)
        ? (width * dpr * 2).round().clamp(1, 2000)
        : null;
    final int? cacheH = (cacheW == null && height.isFinite && height > 0)
        ? (height * dpr * 2).round().clamp(1, 2000)
        : null;

    Widget image;
    if (resolved.isEmpty) {
      image = _ph();
    } else if (resolved.startsWith('assets/')) {
      image = Image.asset(
        resolved,
        width: width.isFinite ? width : null,
        height: height.isFinite ? height : null,
        fit: fit,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _ph(),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: resolved,
        width: width.isFinite ? width : null,
        height: height.isFinite ? height : null,
        fit: fit,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (context, _) => _ph(),
        errorWidget: (context, _, _) => _ph(),
      );
    }

    image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image,
    );
    if (width.isFinite && height.isFinite) {
      image = SizedBox(width: width, height: height, child: image);
    } else {
      image = SizedBox.expand(child: image);
    }
    return FoilChromatic(
      enabled: foil,
      intensity: 0.72,
      autoPlay: autoPlay,
      child: image,
    );
  }

  Widget _ph() => Container(
        width: width.isFinite ? width : null,
        height: height.isFinite ? height : null,
        color: CC.cardSoft,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: CC.inkMuted.withValues(alpha: 0.4)),
      );
}

/// Shared horizontal chase / Top Hits scroller (swipe + mouse drag).
class ShowcaseCardRow extends StatelessWidget {
  const ShowcaseCardRow({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.cardW = 168,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double cardW;

  @override
  Widget build(BuildContext context) {
    final cardH = cardW * (3.5 / 2.5);
    final rowH = cardH + 8 + 18 + 18 + 16;
    return SizedBox(
      height: rowH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class RarityChip extends StatelessWidget {
  const RarityChip(this.rarity, {super.key});
  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = switch (rarity) {
      Rarity.common => CC.rarityColor(Rarity.common),
      Rarity.uncommon => CC.rarityColor(Rarity.uncommon),
      Rarity.rare => CC.rarityColor(Rarity.rare),
      Rarity.epic => CC.rarityColor(Rarity.epic),
      Rarity.showcase => CC.rarityColor(Rarity.showcase),
      Rarity.overnumbered => CC.rarityColor(Rarity.overnumbered),
      Rarity.signature => CC.rarityColor(Rarity.signature),
      Rarity.ultimate => CC.rarityColor(Rarity.ultimate),
      Rarity.promo => CC.rarityColor(Rarity.promo),
      Rarity.token => CC.rarityColor(Rarity.token),
      Rarity.none => CC.rarityColor(Rarity.none),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rarity.label,
        style: AppText.jakarta(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OwnedCardTile extends ConsumerStatefulWidget {
  const OwnedCardTile({
    super.key,
    required this.def,
    required this.owned,
    required this.fair,
    this.onTap,
  });

  final CardDef def;
  final OwnedCard owned;
  final double fair;
  final VoidCallback? onTap;

  @override
  ConsumerState<OwnedCardTile> createState() => _OwnedCardTileState();
}

class _OwnedCardTileState extends ConsumerState<OwnedCardTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlayEnter());
  }

  @override
  void didUpdateWidget(covariant OwnedCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owned.instanceId != widget.owned.instanceId) {
      _maybePlayEnter();
    }
  }

  void _maybePlayEnter() {
    final ids = ref.read(gameProvider).recentlyKeptIds;
    if (!ids.contains(widget.owned.instanceId)) return;
    _enter.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      ref
          .read(gameProvider.notifier)
          .acknowledgeRecentlyKept(widget.owned.instanceId);
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final owned = widget.owned;
    final fair = widget.fair;
    final heroTag = 'card-art-${owned.instanceId}';

    // Also react when this id newly appears in recentlyKeptIds.
    ref.listen(gameProvider.select((s) => s.recentlyKeptIds), (prev, next) {
      if (next.contains(owned.instanceId) &&
          !(prev?.contains(owned.instanceId) ?? false)) {
        _maybePlayEnter();
      }
    });

    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_enter.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.92 + 0.08 * t,
            child: child,
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          // Clip splash/art only via InkWell radius; keep footer text unclipped.
          clipBehavior: Clip.none,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Height-only art slot — review Flip ratios if tiles crop.
                      final maxW = constraints.maxWidth;
                      final maxH = constraints.maxHeight;
                      if (maxW <= 0 || maxH <= 0) {
                        return const SizedBox.shrink();
                      }

                      if (owned.graded && owned.grade != null) {
                        final byW = maxW;
                        final byH = maxH * kPsaSlabAspect;
                        final slabW = byW < byH ? byW : byH;
                        return Center(
                          child: Hero(
                            tag: heroTag,
                            child: SlabCase(
                              company: owned.gradingCompany?.label ?? 'PSA',
                              grade: owned.grade!,
                              width: slabW,
                              compact: true,
                              animateEnter: false,
                              cardName: def.name,
                              setLabel: def.slabSetLabel,
                              cardNumber: def.number,
                              child: PortraitSlotArt(
                                url: def.displayArtUrl,
                                foil: owned.foil,
                                width: slabW,
                                height: slabW / (2.5 / 3.5),
                                landscape: def.isLandscapeCard,
                                radius: 4,
                                autoPlay: false,
                              ),
                            ),
                          ),
                        );
                      }

                      // Always use a portrait footprint so every tile matches.
                      // Landscape Battlefields are rotated + scaled to fill.
                      const portraitAspect = 2.5 / 3.5;
                      final byW = maxW;
                      final byH = maxH * portraitAspect;
                      final cardW = byW < byH ? byW : byH;
                      final cardH = cardW / portraitAspect;
                      return Center(
                        child: Hero(
                          tag: heroTag,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: PortraitSlotArt(
                              url: def.displayArtUrl,
                              foil: owned.foil,
                              width: cardW,
                              height: cardH,
                              landscape: def.isLandscapeCard,
                              radius: 10,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 5, 6, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        def.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.15,
                          color: CC.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                def.franchiseTag,
                                def.setCode,
                                if (def.number != null) '#${def.number}',
                                if (owned.foil) 'Foil',
                                if (owned.graded) 'PSA',
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                              style: AppText.jakarta(
                                fontSize: 10,
                                height: 1.15,
                                fontWeight: FontWeight.w500,
                                color: CC.inkMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '\$${fair.toStringAsFixed(2)}',
                            softWrap: false,
                            style: AppText.jakarta(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              height: 1.15,
                              color: CC.scan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid/market portrait slot. Landscape (Battlefield) art is rotated 90° and
/// scaled to fill the same footprint as portrait cards (Rare Candy–style).
class PortraitSlotArt extends StatelessWidget {
  const PortraitSlotArt({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.landscape,
    this.foil = false,
    this.radius = 10,
    this.autoPlay = false,
  });

  final String url;
  final double width;
  final double height;
  final bool landscape;
  final bool foil;
  final double radius;
  final bool autoPlay;

  @override
  Widget build(BuildContext context) {
    if (!landscape) {
      return CardArt(
        url: url,
        foil: foil,
        autoPlay: autoPlay,
        width: width,
        height: height,
        radius: radius,
        fit: BoxFit.contain,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: RotatedBox(
            quarterTurns: 1,
            child: CardArt(
              url: url,
              foil: foil,
              autoPlay: autoPlay,
              width: height * (3.5 / 2.5),
              height: height,
              radius: 0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
