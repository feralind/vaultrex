import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/price_history.dart';
import '../data/scrydex_art.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'foil_slab.dart';
import 'game_widgets.dart';
import 'card_inspect_page.dart';
import 'psa_grading_progress.dart';

enum CardDetailMode { buy, owned }

String cardDetailSetYear(String setCode) {
  // Prefer CardDef.setYear when a def is available; this remains for set-code-only callers.
  return switch (setCode) {
    'OGS' || 'OGN' || 'SFD' || 'UNL' => '2025',
    'MEW' || 'OBF' || 'PAL' => '2023',
    'TWM' || 'SSP' || 'PRE' => '2024',
    _ => '2024',
  };
}

String cardDetailSlabSetLabel(CardDef def) => def.slabSetLabel;

String cardDetailFranchiseTag(CardDef def) => def.franchiseTag;

/// PSA slab used in Market carousels and detail sheets.
Widget buildCardDetailSlab({
  required bool foil,
  required double grade,
  required GradingCompany? company,
  required CardDef def,
  required double width,
  double? artW,
  double? artH,
  bool? compact,
  bool animateEnter = true,
}) {
  final tiny = compact ?? width < 100;
  return SlabCase(
    company: company?.label ?? 'PSA',
    grade: grade,
    width: width,
    compact: tiny,
    animateEnter: animateEnter,
    cardName: def.name,
    setLabel: cardDetailSlabSetLabel(def),
    cardNumber: def.number,
    child: CardArt(
      url: def.displayArtUrl,
      // Soften foil on thumbs — chromatic bands read as streaks when tiny.
      foil: foil && !tiny,
      autoPlay: !tiny,
      width: artW ?? double.infinity,
      height: artH ?? double.infinity,
      radius: tiny ? 2 : 4,
    ),
  );
}

/// Rare Candy–style card detail: art, tags, chart, conditions, then buy or own actions.
class CardDetailSheet extends StatefulWidget {
  const CardDetailSheet.buy({
    super.key,
    required this.listing,
    required this.def,
    required this.allMarket,
    required this.onBuy,
    this.onOffer,
  })  : mode = CardDetailMode.buy,
        owned = null,
        fairPrice = null,
        suggestedAsk = null,
        onListForSale = null,
        onCancelListing = null,
        onSendToPsa = null,
        onQuickFlip = null;

  const CardDetailSheet.owned({
    super.key,
    required this.owned,
    required this.def,
    required this.allMarket,
    required this.fairPrice,
    required this.onListForSale,
    required this.onCancelListing,
    this.onSendToPsa,
    this.onQuickFlip,
    this.suggestedAsk,
  })  : mode = CardDetailMode.owned,
        listing = null,
        onBuy = null,
        onOffer = null;

  final CardDetailMode mode;
  final MarketListing? listing;
  final OwnedCard? owned;
  final CardDef def;
  final List<MarketListing> allMarket;
  final double? fairPrice;
  final double? suggestedAsk;
  final Future<void> Function(String id)? onBuy;
  final Future<void> Function(String listingId, double amount)? onOffer;
  final Future<void> Function(double ask)? onListForSale;
  final Future<void> Function()? onCancelListing;
  final Future<void> Function()? onSendToPsa;
  final Future<void> Function()? onQuickFlip;

  @override
  State<CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<CardDetailSheet> {
  late bool _foil;
  late Condition _condition;
  bool _showFullChart = false;
  PriceHistoryStore? _prices;
  TextEditingController? _ask;

  CardDef get def => widget.def;
  bool get _graded =>
      widget.mode == CardDetailMode.buy
          ? (widget.listing?.graded ?? false)
          : (widget.owned?.graded ?? false);
  double? get _grade =>
      widget.mode == CardDetailMode.buy
          ? widget.listing?.grade
          : widget.owned?.grade;
  GradingCompany? get _company =>
      widget.mode == CardDetailMode.buy
          ? widget.listing?.gradingCompany
          : widget.owned?.gradingCompany;

  @override
  void initState() {
    super.initState();
    if (widget.mode == CardDetailMode.buy) {
      final listing = widget.listing!;
      _foil = listing.foil;
      _condition = listing.condition;
    } else {
      final owned = widget.owned!;
      _foil = owned.foil;
      _condition = owned.condition;
      _ask = TextEditingController(
        text: (widget.suggestedAsk ?? widget.fairPrice ?? 0).toStringAsFixed(2),
      );
    }
    PriceHistoryStore.load().then((store) {
      if (mounted) setState(() => _prices = store);
    });
  }

  @override
  void dispose() {
    _ask?.dispose();
    super.dispose();
  }

  double get _guideBase {
    final raw = _foil
        ? (def.foilMarketPrice ?? def.marketPrice * 2)
        : def.marketPrice;
    return raw * _condition.valueMult;
  }

  double get _displayPrice {
    if (_graded) {
      if (widget.mode == CardDetailMode.buy) {
        return widget.listing!.price;
      }
      return widget.fairPrice ?? widget.listing?.price ?? _guideBase;
    }
    if (widget.mode == CardDetailMode.owned) {
      // Fair value for the owned copy; condition chips still adjust guide view.
      if (_condition == widget.owned!.condition && _foil == widget.owned!.foil) {
        return widget.fairPrice ?? _guideBase;
      }
    }
    return _guideBase;
  }

  List<PricePoint> _historySeries(double current) {
    final store = _prices;
    if (store != null) {
      return store.seriesFor(def, spot: current, days: _showFullChart ? 90 : 28);
    }
    return PriceHistoryStore.synthesize(
      def.id,
      current,
      days: _showFullChart ? 90 : 28,
    );
  }

  Map<Condition, double?> _conditionPrices() {
    const keys = [
      Condition.nearMint,
      Condition.lightlyPlayed,
      Condition.moderatelyPlayed,
      Condition.heavilyPlayed,
    ];
    final siblings = widget.allMarket.where(
      (m) => m.cardId == def.id && !m.graded && m.foil == _foil,
    );
    final map = <Condition, double?>{};
    for (final c in keys) {
      final matches = siblings.where((m) => m.condition == c);
      if (matches.isEmpty) {
        map[c] = null; // no real ask — chip still tappable for guide
      } else {
        map[c] = matches.map((m) => m.price).reduce((a, b) => a < b ? a : b);
      }
    }
    return map;
  }

  double _guideForCondition(Condition c) {
    final raw = _foil
        ? (def.foilMarketPrice ?? def.marketPrice * 2)
        : def.marketPrice;
    return double.parse((raw * c.valueMult).toStringAsFixed(2));
  }

  List<MarketListing> _buyNowListings() {
    final listing = widget.listing!;
    final same = widget.allMarket.where((m) {
      if (m.cardId != def.id) return false;
      if (listing.graded) return m.graded;
      return !m.graded && m.foil == _foil;
    }).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    if (same.isEmpty) return [listing];
    return same;
  }

  MarketListing? _bestMatchForBuy() {
    final listing = widget.listing!;
    if (listing.graded) return listing;
    final matches = widget.allMarket.where(
      (m) =>
          m.cardId == def.id &&
          !m.graded &&
          m.foil == _foil &&
          m.condition == _condition,
    );
    if (matches.isEmpty) {
      final siblings = widget.allMarket
          .where((m) => m.cardId == def.id && !m.graded && m.foil == _foil)
          .toList()
        ..sort((a, b) => a.price.compareTo(b.price));
      return siblings.isNotEmpty ? siblings.first : listing;
    }
    return matches.reduce((a, b) => a.price <= b.price ? a : b);
  }

  bool get _hasFoilOption =>
      def.foilMarketPrice != null ||
      widget.allMarket.any((m) => m.cardId == def.id && m.foil) ||
      (widget.owned?.foil ?? false);

  @override
  Widget build(BuildContext context) {
    final guide = _displayPrice;
    final history = _historySeries(guide);
    final condPrices = _graded ? null : _conditionPrices();
    final buyList =
        widget.mode == CardDetailMode.buy ? _buyNowListings() : const <MarketListing>[];
    final primary =
        widget.mode == CardDetailMode.buy ? (_bestMatchForBuy() ?? widget.listing!) : null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CC.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildHero(),
            const SizedBox(height: 18),
            Text(
              _graded
                  ? (widget.mode == CardDetailMode.owned
                      ? 'Fair value'
                      : 'Slab ask')
                  : 'Market price',
              style: AppText.jakarta(
                color: CC.inkMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${guide.toStringAsFixed(2)}',
              style: AppText.jakarta(
                fontWeight: FontWeight.w800,
                fontSize: 28,
                color: const Color(0xFF34D399),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            _PriceSparkline(
              points: history,
              expanded: _showFullChart,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setState(() => _showFullChart = !_showFullChart),
                child: Text(
                  _showFullChart ? 'Collapse chart' : 'Full chart · 90d',
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w700,
                    color: CC.accent,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (condPrices != null) ...[
              const SizedBox(height: 4),
              Text(
                _foil ? 'Foil · Condition' : 'Raw · Condition',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final e in condPrices.entries)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _CondChip(
                          label: e.key.label,
                          price: e.value ?? _guideForCondition(e.key),
                          hasListing: e.value != null,
                          selected: e.key == _condition,
                          onTap: () => setState(() => _condition = e.key),
                        ),
                      ),
                    ),
                ],
              ),
            ] else if (_graded && _grade != null) ...[
              const SizedBox(height: 8),
              Text(
                'PSA ${_grade! >= 10 ? '10' : _grade!.toStringAsFixed(_grade! % 1 == 0 ? 0 : 1)}'
                ' · ${psaGradeDescriptor(_grade!)}'
                '${_foil ? ' · Foil' : ''}',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (widget.mode == CardDetailMode.buy && primary != null)
              ..._buildBuyActions(primary, buyList)
            else if (widget.mode == CardDetailMode.owned)
              ..._buildOwnedActions(),
          ],
        );
      },
    );
  }

  Widget _buildHero() {
    final heroTag = widget.owned != null
        ? 'card-art-${widget.owned!.instanceId}'
        : 'card-art-buy-${def.id}';
    final aspect = def.artAspectRatio;
    // Face-on hero: landscape Battlefields use a wide frame so full art shows.
    final artW = def.isLandscapeCard ? 168.0 : 126.0;
    final artH = artW / aspect;
    final art = _graded && _grade != null
        ? buildCardDetailSlab(
            foil: _foil,
            grade: _grade!,
            company: _company,
            def: def,
            width: def.isLandscapeCard ? 148 : 132,
            compact: false,
          )
        : CardArt(
            url: def.displayArtUrl,
            foil: _foil,
            autoPlay: true,
            width: artW,
            height: artH,
            radius: 12,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => openCardInspect(
              context,
              def: def,
              foil: _foil,
              grade: _graded ? _grade : null,
              company: _company,
              heroTag: heroTag,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Hero(
                  tag: heroTag,
                  child: art,
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.open_in_full_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (ScrydexArt.expansionLogoUrl(def) != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: ScrydexExpansionLogo(
                        setCode: def.setCode,
                        height: 16,
                      ),
                    ),
                  _TagChip(label: def.franchiseTag),
                  _TagChip(label: def.setCode),
                  const _TagChip(label: 'EN'),
                  if (def.cardType != null && def.cardType!.isNotEmpty)
                    _TagChip(
                      label: def.cardType!.split(';').first.trim().toUpperCase(),
                    ),
                  if (def.domain != null && def.domain!.isNotEmpty)
                    _TagChip(label: def.domain!.toUpperCase()),
                  if (_graded) const _TagChip(label: 'PSA'),
                  if (def.isUnlisted)
                    const _TagChip(label: 'NOT ON MARKET'),
                ],
              ),
              if (def.isUnlisted) ...[
                const SizedBox(height: 8),
                Text(
                  'Speculative value — no TCGCSV/TCGplayer spot yet. '
                  'Pulled from packs; price may settle higher once listed.',
                  style: AppText.jakarta(
                    color: CC.accentHot,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                def.name,
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              if (ScrydexArt.printedNumberLabel(def) != null) ...[
                const SizedBox(height: 4),
                Text(
                  ScrydexArt.printedNumberLabel(def)!,
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ] else if (def.number != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${def.setCode} ${def.number}',
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                () {
                  final exp = ScrydexArt.riftboundExpansion(def.setCode);
                  if (exp != null) return exp.subtitle;
                  return ScrydexArt.displaySetName(def);
                }(),
                style: AppText.jakarta(
                  color: CC.inkMuted,
                  fontSize: 12,
                ),
              ),
              if (def.artist != null && def.artist!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Illus. ${def.artist}',
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Tap art to inspect',
                style: AppText.jakarta(
                  color: CC.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              RarityChip(def.rarity),
              if (!_graded && _hasFoilOption) ...[
                const SizedBox(height: 12),
                if (widget.mode == CardDetailMode.buy)
                  _FoilRawToggle(
                    foil: _foil,
                    onChanged: (v) => setState(() => _foil = v),
                  )
                else
                  _OwnershipFoilBadge(foil: _foil),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBuyActions(
    MarketListing primary,
    List<MarketListing> buyList,
  ) {
    final fair = _guideBase;
    final deal = primary.price <= fair * 0.92;
    final warn = primary.sellerType == SellerType.scammy || primary.isFake;

    return [
      if (deal || warn) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: warn
                ? const Color(0x33F59E0B)
                : const Color(0x2234D399),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: warn ? const Color(0xFFF59E0B) : const Color(0xFF34D399),
            ),
          ),
          child: Text(
            warn
                ? 'Caution · seller reputation looks weak'
                    '${primary.isFake ? ' · possible counterfeit risk' : ''}'
                : 'Best deal · \$${primary.price.toStringAsFixed(2)} vs fair \$${fair.toStringAsFixed(2)}',
            style: AppText.jakarta(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: warn ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => widget.onBuy!(primary.id),
          style: FilledButton.styleFrom(
            backgroundColor: CC.accent,
            minimumSize: const Size.fromHeight(54),
          ),
          child: Text(
            'BUY NOW  ·  \$${primary.price.toStringAsFixed(2)}',
            style: AppText.jakarta(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 15,
            ),
          ),
        ),
      ),
      if (widget.onOffer != null) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showMakeOfferSheet(context, primary),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: CC.line),
            ),
            child: Text(
              'MAKE OFFER',
              style: AppText.jakarta(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: 22),
      Text(
        'All listings · ${buyList.length}',
        style: AppText.jakarta(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Sorted by price · seller · condition',
        style: AppText.jakarta(
          color: CC.inkMuted,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 12),
      ...buyList.map((m) {
        final platform = _platformFor(m);
        final rating = m.displayRating.toStringAsFixed(1);
        final ships = m.displayShipsInDays;
        final shady = m.sellerType == SellerType.scammy || m.isFake;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: m.id == primary.id
                    ? CC.accent.withValues(alpha: 0.55)
                    : CC.line,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CC.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CC.line),
                  ),
                  child: Text(
                    platform.$1,
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: platform.$2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.graded && m.grade != null
                            ? 'PSA ${m.grade! >= 10 ? '10' : m.grade!.toStringAsFixed(m.grade! % 1 == 0 ? 0 : 1)}'
                            : m.condition.label,
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${m.sellerAlias ?? m.sellerType.label}'
                        ' · $rating% · ${m.displaySales} sold · ${ships}d',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.jakarta(
                          fontSize: 11,
                          color: shady ? const Color(0xFFFBBF24) : CC.inkMuted,
                        ),
                      ),
                      Text(
                        m.sellerType.personality,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.jakarta(
                          fontSize: 10,
                          color: CC.inkMuted.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${m.price.toStringAsFixed(2)}',
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF34D399),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.onOffer != null)
                  OutlinedButton(
                    onPressed: () => _showMakeOfferSheet(context, m),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(56, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: const BorderSide(color: CC.line),
                    ),
                    child: Text(
                      'Offer',
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () => widget.onBuy!(m.id),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(56, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: CC.accent,
                  ),
                  child: Text(
                    'BUY',
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  Future<void> _showMakeOfferSheet(
    BuildContext context,
    MarketListing listing,
  ) async {
    if (widget.onOffer == null) return;
    final ask = listing.price;
    final fair = _guideBase;
    var amount = double.parse((ask * 0.90).clamp(0.99, ask - 0.01).toStringAsFixed(2));
    final minOffer = 0.99;
    final maxOffer = double.parse((ask - 0.01).toStringAsFixed(2));
    if (maxOffer < minOffer) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ask too low to offer — use Buy Now.')),
        );
      }
      return;
    }
    amount = amount.clamp(minOffer, maxOffer);

    final submitted = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CC.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final pct = (amount / ask * 100).toStringAsFixed(0);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CC.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Make offer',
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ask \$${ask.toStringAsFixed(2)} · fair ~\$${fair.toStringAsFixed(2)}',
                    style: AppText.jakarta(color: CC.inkMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cash is escrowed until the seller responds on Advance Day.',
                    style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '\$${amount.toStringAsFixed(2)}  ($pct% of ask)',
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: const Color(0xFF34D399),
                    ),
                  ),
                  Slider(
                    value: amount,
                    min: minOffer,
                    max: maxOffer,
                    divisions: math.max(1, ((maxOffer - minOffer) * 100).round()),
                    activeColor: CC.accent,
                    onChanged: (v) => setModal(() {
                      amount = double.parse(v.toStringAsFixed(2));
                    }),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, amount),
                      style: FilledButton.styleFrom(
                        backgroundColor: CC.accent,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        'SUBMIT OFFER · ESCROW',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (submitted == null || !context.mounted) return;
    await widget.onOffer!(listing.id, submitted);
  }

  List<Widget> _buildOwnedActions() {
    final owned = widget.owned!;
    final listed = owned.listedAsk != null;
    final fair = widget.fairPrice ?? 0;

    return [
      Text(
        'Your card',
        style: AppText.jakarta(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        listed
            ? 'Listed on the market · manage below'
            : 'Ownership actions · list or grade',
        style: AppText.jakarta(
          color: CC.inkMuted,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 14),
      if (listed) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CC.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CC.accent.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LISTED FOR SALE',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: CC.accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${owned.listedAsk!.toStringAsFixed(2)}',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Active online listing',
                style: AppText.jakarta(
                  color: CC.inkMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              await widget.onCancelListing!();
              if (mounted) Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: CC.line),
            ),
            child: Text(
              'CANCEL LISTING',
              style: AppText.jakarta(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ] else ...[
        TextField(
          controller: _ask,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'List online',
            prefixText: '\$',
            border: const OutlineInputBorder(),
            helperText: widget.suggestedAsk != null
                ? 'Comps ≈ \$${widget.suggestedAsk!.toStringAsFixed(2)} · Fair ≈ \$${fair.toStringAsFixed(2)}'
                : 'Fair ≈ \$${fair.toStringAsFixed(2)}',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.suggestedAsk != null)
              _AskChip(
                label: 'Comps',
                value: widget.suggestedAsk!,
                onTap: () => setState(() {
                  _ask?.text = widget.suggestedAsk!.toStringAsFixed(2);
                }),
              ),
            _AskChip(
              label: 'Fair',
              value: fair,
              onTap: () => setState(() {
                _ask?.text = fair.toStringAsFixed(2);
              }),
            ),
            if (fair > 0.05)
              _AskChip(
                label: '−5%',
                value: fair * 0.95,
                onTap: () => setState(() {
                  _ask?.text = (fair * 0.95).toStringAsFixed(2);
                }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              final ask = double.tryParse(_ask?.text ?? '') ?? fair;
              await widget.onListForSale!(ask);
              if (mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: CC.accent,
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(
              'LIST FOR SALE',
              style: AppText.jakarta(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 15,
              ),
            ),
          ),
        ),
        if (widget.onQuickFlip != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await widget.onQuickFlip!();
                if (mounted) Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: CC.line),
              ),
              child: Text(
                'QUICK FLIP · ~${(fair * 0.70).clamp(0.01, fair).toStringAsFixed(2)}',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Instant cash at 70% fair · skip market wait & fees',
            style: AppText.jakarta(color: CC.inkMuted, fontSize: 11),
          ),
        ],
      ],
      const SizedBox(height: 10),
      PsaSendButton(instanceId: owned.instanceId),
    ];
  }

  (String, Color, String) _platformFor(MarketListing m) {
    final platforms = [
      ('TC', const Color(0xFF5B8CFF), 'TCGPlayer'),
      ('EB', const Color(0xFFE8722A), 'eBay'),
      ('BD', const Color(0xFFA78BFA), 'Bindora'),
      ('MK', const Color(0xFF34D399), 'Marketplace'),
    ];
    final i = m.id.hashCode.abs() % platforms.length;
    return platforms[i];
  }
}

class _OwnershipFoilBadge extends StatelessWidget {
  const _OwnershipFoilBadge({required this.foil});
  final bool foil;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CC.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CC.accent),
      ),
      child: Text(
        foil ? 'Your copy · Foil' : 'Your copy · Raw',
        style: AppText.jakarta(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AskChip extends StatelessWidget {
  const _AskChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final double value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CC.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CC.line),
          ),
          child: Text(
            '$label \$${value.toStringAsFixed(2)}',
            style: AppText.jakarta(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CC.line),
      ),
      child: Text(
        label,
        style: AppText.jakarta(
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.6,
          color: CC.inkMuted,
        ),
      ),
    );
  }
}

class _FoilRawToggle extends StatelessWidget {
  const _FoilRawToggle({required this.foil, required this.onChanged});
  final bool foil;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? CC.accent.withValues(alpha: 0.22) : CC.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? CC.accent : CC.line),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.jakarta(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Raw', !foil, () => onChanged(false)),
        const SizedBox(width: 8),
        chip('Foil', foil, () => onChanged(true)),
      ],
    );
  }
}

class _PriceSparkline extends StatelessWidget {
  const _PriceSparkline({required this.points, required this.expanded});
  final List<PricePoint> points;
  final bool expanded;

  String _money(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    if (v >= 100) return '\$${v.toStringAsFixed(0)}';
    return '\$${v.toStringAsFixed(2)}';
  }

  String _dateLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }
    final h = expanded ? 168.0 : 110.0;
    final minV = points.map((p) => p.price).reduce(math.min);
    final maxV = points.map((p) => p.price).reduce(math.max);
    final up = points.last.price >= points.first.price;
    final color = up ? const Color(0xFF34D399) : const Color(0xFFF87171);
    final midV = (minV + maxV) / 2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: h,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 10, 10, 6),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Price history (\$)',
            style: AppText.jakarta(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: CC.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(maxV),
                        style: AppText.jakarta(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: CC.inkMuted,
                        ),
                      ),
                      Text(
                        _money(midV),
                        style: AppText.jakarta(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: CC.inkMuted,
                        ),
                      ),
                      Text(
                        _money(minV),
                        style: AppText.jakarta(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: CC.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: CustomPaint(
                    painter: _SparkPainter(
                      points: points.map((p) => p.price).toList(),
                      minV: minV,
                      maxV: maxV,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateLabel(points.first.date),
                  style: AppText.jakarta(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: CC.inkMuted,
                  ),
                ),
                Text(
                  _dateLabel(points[points.length ~/ 2].date),
                  style: AppText.jakarta(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: CC.inkMuted,
                  ),
                ),
                Text(
                  _dateLabel(points.last.date),
                  style: AppText.jakarta(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: CC.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.points,
    required this.minV,
    required this.maxV,
    required this.color,
  });

  final List<double> points;
  final double minV;
  final double maxV;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    var lo = minV;
    var hi = maxV;
    if ((hi - lo).abs() < 0.01) {
      final pad = math.max(0.5, lo * 0.04);
      lo -= pad;
      hi += pad;
    }
    final range = hi - lo;
    final path = Path();
    final fill = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - (points[i] - lo) / range);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.minV != minV ||
      oldDelegate.maxV != maxV;
}

class _CondChip extends StatelessWidget {
  const _CondChip({
    required this.label,
    required this.price,
    required this.selected,
    this.hasListing = true,
    this.onTap,
  });

  final String label;
  final double price;
  final bool selected;
  final bool hasListing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? CC.accent.withValues(alpha: 0.18) : CC.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? CC.accent
                  : hasListing
                      ? CC.line
                      : CC.line.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: hasListing ? CC.ink : CC.inkMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasListing ? '\$${price.toStringAsFixed(0)}' : '—',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: hasListing
                      ? const Color(0xFF34D399)
                      : CC.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
