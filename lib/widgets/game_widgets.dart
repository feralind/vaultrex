import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/enums.dart';
import '../models/models.dart';
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
          GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: CC.ink),
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
  });

  final String url;
  final double width;
  final double height;
  final bool foil;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Decode at ~2× display CSS px (one axis only to preserve aspect).
    // Omit when size is unbounded so grids get full HD decode.
    final int? cacheW = (width.isFinite && width > 0)
        ? (width * dpr * 2).round().clamp(1, 2000)
        : null;
    final int? cacheH = (cacheW == null && height.isFinite && height > 0)
        ? (height * dpr * 2).round().clamp(1, 2000)
        : null;
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? _ph()
          : CachedNetworkImage(
              imageUrl: url,
              width: width.isFinite ? width : null,
              height: height.isFinite ? height : null,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              memCacheWidth: cacheW,
              memCacheHeight: cacheH,
              fadeInDuration: const Duration(milliseconds: 180),
              placeholder: (context, _) => _ph(),
              errorWidget: (context, _, _) => _ph(),
            ),
    );
    if (width.isFinite && height.isFinite) {
      image = SizedBox(width: width, height: height, child: image);
    } else {
      image = SizedBox.expand(child: image);
    }
    return FoilChromatic(enabled: foil, intensity: 0.72, child: image);
  }

  Widget _ph() => Container(
        width: width.isFinite ? width : null,
        height: height.isFinite ? height : null,
        color: CC.cardSoft,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: CC.inkMuted.withValues(alpha: 0.4)),
      );
}

class RarityChip extends StatelessWidget {
  const RarityChip(this.rarity, {super.key});
  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = switch (rarity) {
      Rarity.common => const Color(0xFF9CA3AF),
      Rarity.uncommon => const Color(0xFF34D399),
      Rarity.rare => const Color(0xFF60A5FA),
      Rarity.epic => const Color(0xFFC084FC),
      Rarity.showcase => const Color(0xFFFBBF24),
      Rarity.overnumbered => const Color(0xFFFB923C),
      Rarity.signature => const Color(0xFFF472B6),
      Rarity.ultimate => const Color(0xFFF87171),
      Rarity.promo => const Color(0xFF2DD4BF),
      Rarity.token => const Color(0xFF6B7280),
      Rarity.none => const Color(0xFF6B7280),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rarity.label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OwnedCardTile extends StatelessWidget {
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

  static const _cardAspect = 2.5 / 3.5;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final maxH = constraints.maxHeight;
                  if (maxW <= 0 || maxH <= 0) {
                    return const SizedBox.shrink();
                  }

                  if (owned.graded && owned.grade != null) {
                    // Fit slab inside the art slot — no FittedBox (avoids
                    // weird scale/crop on short grid cells).
                    final byW = maxW;
                    final byH = maxH * kPsaSlabAspect;
                    final slabW = byW < byH ? byW : byH;
                    return Center(
                      child: SlabCase(
                        company: owned.gradingCompany?.label ?? 'PSA',
                        grade: owned.grade!,
                        width: slabW,
                        compact: true,
                        animateEnter: false,
                        cardName: def.name,
                        setLabel:
                            '${def.setCode} ${def.setName}'.toUpperCase(),
                        cardNumber: def.number,
                        child: CardArt(
                          url: def.displayArtUrl,
                          foil: owned.foil,
                          width: slabW,
                          height: slabW / _cardAspect,
                          radius: 4,
                        ),
                      ),
                    );
                  }

                  final byW = maxW;
                  final byH = maxH * _cardAspect;
                  final cardW = byW < byH ? byW : byH;
                  final cardH = cardW / _cardAspect;
                  return Center(
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
                      child: CardArt(
                        url: def.displayArtUrl,
                        foil: owned.foil,
                        width: cardW,
                        height: cardH,
                        radius: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              def.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.15,
                color: CC.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${def.setCode}${owned.foil ? ' · Foil' : ''}'
              '${owned.graded ? ' · PSA' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                height: 1.15,
                color: CC.inkMuted,
              ),
            ),
            const SizedBox(height: 2),
            MoneyText(
              fair,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1.15,
                color: CC.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
