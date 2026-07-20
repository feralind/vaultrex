import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding.dart';
import '../data/pricing.dart';
import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/card_detail_sheet.dart';
import '../widgets/cash_top_up_sheet.dart';
import '../widgets/fake_google_pay_sheet.dart';
import '../widgets/franchise_icon_row.dart';
import '../widgets/game_widgets.dart';
import '../widgets/live_ambient.dart';

enum _MarketFilter { all, raw, psa, foil }

enum _MarketSort {
  priceAsc,
  priceDesc,
  rarityDesc,
  dealDesc,
  sellersDesc,
}

extension on _MarketSort {
  String get label => switch (this) {
        _MarketSort.priceAsc => 'Price ↑',
        _MarketSort.priceDesc => 'Price ↓',
        _MarketSort.rarityDesc => 'Rarity',
        _MarketSort.dealDesc => 'Best deals',
        _MarketSort.sellersDesc => 'Most sellers',
      };
}

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen>
    with SingleTickerProviderStateMixin {
  String _query = '';
  /// null = all sets (type filter already has an "All" chip).
  String? _set;
  _MarketFilter _filter = _MarketFilter.all;
  _MarketSort _sort = _MarketSort.dealDesc;
  bool _buying = false;
  String? _pendingGame;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  List<MarketListing> _filtered(List<MarketListing> market, GameNotifier n) {
    // Defensive: never render SKUs missing from the active franchise catalog.
    return market.where((m) {
      if (!n.catalog.byId.containsKey(m.cardId)) return false;
      final def = n.cardById(m.cardId);
      if (def == null) return false;
      if (_set != null && def.setCode != _set) return false;
      if (_filter == _MarketFilter.raw && m.graded) return false;
      if (_filter == _MarketFilter.psa && !m.graded) return false;
      if (_filter == _MarketFilter.foil && !m.foil) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final hay =
            '${def.name} ${def.setCode} ${def.setName} ${def.number ?? ''} ${m.title}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  double _dealScore(
    MarketListing m,
    CardDef def,
    List<MarketEvent> events,
  ) {
    final fair = Pricing.fairForListing(def, m, events: events);
    return (fair - m.price) / fair;
  }

  int _rarityRank(Rarity r) => switch (r) {
        Rarity.ultimate => 100,
        Rarity.signature => 90,
        Rarity.overnumbered => 80,
        Rarity.showcase => 70,
        Rarity.epic => 60,
        Rarity.promo => 55,
        Rarity.rare => 50,
        Rarity.uncommon => 40,
        Rarity.common => 30,
        Rarity.token => 10,
        Rarity.none => 0,
      };

  /// One row per card variant (raw foil / raw non-foil / slab), lowest ask first.
  List<_MarketGroup> _groupBuyNow(
    List<MarketListing> listings,
    GameNotifier n,
    List<MarketEvent> events,
  ) {
    final map = <String, List<MarketListing>>{};
    for (final m in listings) {
      final key = '${m.cardId}|${m.graded}|${m.foil}';
      (map[key] ??= []).add(m);
    }
    final groups = <_MarketGroup>[];
    for (final entry in map.entries) {
      final offers = [...entry.value]..sort((a, b) => a.price.compareTo(b.price));
      final lowest = offers.first;
      final def = n.cardById(lowest.cardId)!;
      groups.add(
        _MarketGroup(
          lowest: lowest,
          offerCount: offers.length,
          dealPct: _dealScore(lowest, def, events),
          rarityRank: _rarityRank(def.rarity),
        ),
      );
    }
    switch (_sort) {
      case _MarketSort.priceAsc:
        groups.sort((a, b) => a.lowest.price.compareTo(b.lowest.price));
      case _MarketSort.priceDesc:
        groups.sort((a, b) => b.lowest.price.compareTo(a.lowest.price));
      case _MarketSort.rarityDesc:
        groups.sort((a, b) {
          final c = b.rarityRank.compareTo(a.rarityRank);
          return c != 0 ? c : a.lowest.price.compareTo(b.lowest.price);
        });
      case _MarketSort.dealDesc:
        groups.sort((a, b) {
          final c = b.dealPct.compareTo(a.dealPct);
          return c != 0 ? c : a.lowest.price.compareTo(b.lowest.price);
        });
      case _MarketSort.sellersDesc:
        groups.sort((a, b) {
          final c = b.offerCount.compareTo(a.offerCount);
          return c != 0 ? c : a.lowest.price.compareTo(b.lowest.price);
        });
    }
    return groups;
  }

  Future<void> _switchMarket(GameOption g) async {
    final notifier = ref.read(gameProvider.notifier);
    if (g.id == notifier.activeGameId) {
      setState(() => _pendingGame = g.id);
      return;
    }
    setState(() {
      _pendingGame = g.id;
      _set = null;
      _query = '';
    });
    await notifier.switchFranchise(g.id);
    if (mounted) setState(() => _pendingGame = null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (!state.ready) {
      return const Center(child: CircularProgressIndicator(color: CC.accent));
    }

    final active = _pendingGame ?? notifier.activeGameId;
    final listings = _filtered(state.market, notifier);
    final groups = _groupBuyNow(listings, notifier, state.events);
    final dealish = [...listings]
      ..sort((a, b) {
        final da = _dealScore(a, notifier.cardById(a.cardId)!, state.events);
        final db = _dealScore(b, notifier.cardById(b.cardId)!, state.events);
        return db.compareTo(da);
      });
    final carousel = dealish.take(12).toList();
    final setCodes = notifier.catalog.bySet.keys.toList()..sort();
    final franchiseLabel = switch (active) {
      'pokemon' => 'Pokémon',
      'mtg' => 'Magic',
      _ => 'Riftbound',
    };
    final openOffers = state.marketOffers.where((o) => o.isOpen).length;
    final dealCount = groups.where((g) => g.dealPct >= 0.08).length;

    return LiveAmbientBackdrop(
      intensity: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market',
                        style: AppText.jakarta(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      Text(
                        '$franchiseLabel · pick a TCG below',
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showOffersSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: CC.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: openOffers > 0
                              ? CC.accent.withValues(alpha: 0.55)
                              : CC.line,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 16,
                            color: openOffers > 0 ? CC.accent : CC.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            openOffers > 0 ? 'Offers ($openOffers)' : 'Offers',
                            style: AppText.jakarta(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: openOffers > 0 ? CC.accent : CC.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showCashTopUp(context, ref),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: CC.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CC.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${state.player.cash.toStringAsFixed(2)}',
                            style: AppText.jakarta(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF34D399),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.add_circle_outline,
                            size: 16,
                            color: CC.inkMuted.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FranchiseIconRow(
            activeId: active,
            onSelect: _switchMarket,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: CC.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CC.line),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            size: 16, color: CC.accent.withValues(alpha: 0.9)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dealCount > 0
                                ? '$dealCount hot deals live · ${state.market.length} listings'
                                : '${state.market.length} live listings · shop churns often',
                            style: AppText.jakarta(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CC.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    await notifier.refreshMarketListings();
                    if (!context.mounted) return;
                    final msg = ref.read(gameProvider).message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg ?? 'Market refreshed.')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    'Restock',
                    style: AppText.jakarta(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (q) => setState(() => _query = q),
              style: AppText.jakarta(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search cards, sets…',
                hintStyle: AppText.jakarta(color: CC.inkMuted),
                prefixIcon: const Icon(Icons.search, color: CC.inkMuted),
                filled: true,
                fillColor: CC.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ..._MarketFilter.values.map((f) {
                  final label = switch (f) {
                    _MarketFilter.all => 'All',
                    _MarketFilter.raw => 'Raw',
                    _MarketFilter.psa => 'PSA',
                    _MarketFilter.foil => 'Foil',
                  };
                  final on = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: on,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: CC.accent.withValues(alpha: 0.25),
                      backgroundColor: CC.card,
                      labelStyle: AppText.jakarta(
                        fontWeight: FontWeight.w600,
                        color: CC.ink,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: on ? CC.accent : CC.line),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: VerticalDivider(
                    width: 12,
                    thickness: 1,
                    color: CC.line.withValues(alpha: 0.8),
                  ),
                ),
                ..._MarketSort.values.map((s) {
                  final on = _sort == s;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: on,
                      onSelected: (_) => setState(() => _sort = s),
                      selectedColor: CC.scan.withValues(alpha: 0.22),
                      backgroundColor: CC.card,
                      labelStyle: AppText.jakarta(
                        fontWeight: FontWeight.w600,
                        color: CC.ink,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: on ? CC.scan.withValues(alpha: 0.75) : CC.line,
                      ),
                    ),
                  );
                }),
                ...setCodes.map((s) {
                  final on = _set == s;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: on,
                      onSelected: (_) => setState(() => _set = on ? null : s),
                      selectedColor: CC.scan.withValues(alpha: 0.18),
                      backgroundColor: CC.card,
                      labelStyle: AppText.jakarta(
                        fontWeight: FontWeight.w600,
                        color: CC.ink,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: on ? CC.scan.withValues(alpha: 0.7) : CC.line,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: listings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No listings match — Restock or try another franchise.',
                            style: AppText.jakarta(color: CC.inkMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => notifier.refreshMarketListings(),
                            child: const Text('Restock market'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                    children: [
                      if (carousel.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                          child: Text(
                            'Hot right now (${groups.length})',
                            style: AppText.jakarta(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 340,
                          child: AnimatedBuilder(
                            animation: _float,
                            builder: (context, _) {
                              final bob =
                                  (Curves.easeInOut.transform(_float.value) *
                                              2 -
                                          1) *
                                      4;
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: carousel.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final m = carousel[i];
                                  final def = notifier.cardById(m.cardId)!;
                                  final phase = (i % 3) * 0.22;
                                  final dy = bob *
                                      (i.isEven ? 1 : -1) *
                                      (0.7 + phase);
                                  return KeyedSubtree(
                                    key: ValueKey('carousel-${m.id}'),
                                    child: Transform.translate(
                                      offset: Offset(0, dy),
                                      child: _CarouselCard(
                                        listing: m,
                                        def: def,
                                        dealPct: _dealScore(
                                            m, def, state.events),
                                        onTap: () =>
                                            _openDetail(context, m, def),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Text(
                            'Buy Now · ${_sort.label}',
                            style: AppText.jakarta(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                      ...groups.map((g) {
                        final def = notifier.cardById(g.lowest.cardId)!;
                        return Padding(
                          key: ValueKey(
                            'buy-${g.lowest.cardId}-${g.lowest.graded}-${g.lowest.foil}',
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _BuyNowRow(
                            listing: g.lowest,
                            def: def,
                            offerCount: g.offerCount,
                            dealPct: g.dealPct,
                            busy: _buying,
                            onTap: () => _openDetail(context, g.lowest, def),
                            onBuy: () => _buy(context, g.lowest),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context, MarketListing listing) async {
    if (_buying || ref.read(gameProvider.notifier).isShopBusy) return;
    final cash = ref.read(gameProvider).player.cash;
    if (cash < listing.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough cash.')),
      );
      return;
    }
    setState(() => _buying = true);
    try {
      final paid = await showFakeGooglePay(context, amount: listing.price);
      if (!paid || !context.mounted) return;
      await ref.read(gameProvider.notifier).buyMarketListing(listing.id);
      if (!context.mounted) return;
      final msg = ref.read(gameProvider).message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Purchased.')),
      );
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  Future<void> _openDetail(
    BuildContext context,
    MarketListing listing,
    CardDef def,
  ) async {
    final market = ref.read(gameProvider).market;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CC.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return CardDetailSheet.buy(
          listing: listing,
          def: def,
          allMarket: market,
          onBuy: (id) async {
            Navigator.pop(ctx);
            MarketListing? match;
            for (final m in ref.read(gameProvider).market) {
              if (m.id == id) {
                match = m;
                break;
              }
            }
            if (match != null && context.mounted) await _buy(context, match);
          },
          onOffer: (listingId, amount) async {
            Navigator.pop(ctx);
            await ref
                .read(gameProvider.notifier)
                .submitMarketOffer(listingId, amount);
            if (!context.mounted) return;
            final msg = ref.read(gameProvider).message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg ?? 'Offer submitted.')),
            );
          },
        );
      },
    );
  }

  Future<void> _showOffersSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CC.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final state = ref.watch(gameProvider);
            final notifier = ref.read(gameProvider.notifier);
            final offers = [...state.marketOffers]
              ..sort((a, b) => b.createdDay.compareTo(a.createdDay));
            final actionable = offers
                .where((o) =>
                    o.status == MarketOfferStatus.pending ||
                    o.status == MarketOfferStatus.countered)
                .toList();
            final recent = offers
                .where((o) =>
                    o.status != MarketOfferStatus.pending &&
                    o.status != MarketOfferStatus.countered)
                .take(8)
                .toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              builder: (ctx, scroll) {
                return ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                    const SizedBox(height: 14),
                    Text(
                      'Your offers',
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pending resolves on Advance Day · counters need a reply',
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (actionable.isEmpty && recent.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No offers yet — Make Offer from a listing.',
                          style: AppText.jakarta(color: CC.inkMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ...actionable.map((o) {
                      MarketListing? listing;
                      for (final m in state.market) {
                        if (m.id == o.listingId) {
                          listing = m;
                          break;
                        }
                      }
                      final title = listing?.title ?? 'Listing gone';
                      final isCounter =
                          o.status == MarketOfferStatus.countered;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: CC.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCounter
                                  ? CC.accent.withValues(alpha: 0.5)
                                  : CC.line,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.jakarta(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isCounter
                                    ? 'Counter \$${o.counterAmount!.toStringAsFixed(2)}'
                                        ' (your \$${o.offerAmount.toStringAsFixed(2)} escrowed)'
                                    : 'Pending \$${o.offerAmount.toStringAsFixed(2)}'
                                        ' · expires day ${o.expiresOnDay}',
                                style: AppText.jakarta(
                                  fontSize: 12,
                                  color: CC.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (isCounter) ...[
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () async {
                                          await notifier
                                              .acceptMarketCounter(o.id);
                                          if (!ctx.mounted) return;
                                          final msg =
                                              ref.read(gameProvider).message;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(msg ?? 'Accepted.'),
                                            ),
                                          );
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: CC.accent,
                                        ),
                                        child: Text(
                                          'Accept',
                                          style: AppText.jakarta(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          await notifier
                                              .declineMarketCounter(o.id);
                                          if (!ctx.mounted) return;
                                          final msg =
                                              ref.read(gameProvider).message;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(msg ?? 'Declined.'),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Decline',
                                          style: AppText.jakarta(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          await notifier.cancelMarketOffer(o.id);
                                          if (!ctx.mounted) return;
                                          final msg =
                                              ref.read(gameProvider).message;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(msg ?? 'Cancelled.'),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Cancel & refund',
                                          style: AppText.jakarta(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Recent',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...recent.map((o) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${o.status.name} · \$${o.offerAmount.toStringAsFixed(2)}'
                            '${o.counterAmount != null ? ' (counter \$${o.counterAmount!.toStringAsFixed(2)})' : ''}',
                            style: AppText.jakarta(
                              fontSize: 12,
                              color: CC.inkMuted,
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MarketGroup {
  const _MarketGroup({
    required this.lowest,
    required this.offerCount,
    required this.dealPct,
    required this.rarityRank,
  });
  final MarketListing lowest;
  final int offerCount;
  final double dealPct;
  final int rarityRank;
}

Widget _buildSlab({
  required MarketListing listing,
  required CardDef def,
  required double width,
  bool? compact,
}) {
  return buildCardDetailSlab(
    foil: listing.foil,
    grade: listing.grade!,
    company: listing.gradingCompany,
    def: def,
    width: width,
    compact: compact,
    animateEnter: false,
  );
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.listing,
    required this.def,
    required this.onTap,
    this.dealPct = 0,
  });

  final MarketListing listing;
  final CardDef def;
  final VoidCallback onTap;
  final double dealPct;

  @override
  Widget build(BuildContext context) {
    // Footer sizes to its text (name/set/price/CTA); Expanded art fills the rest
    // so Google Font metrics never clip with a magic fixed height.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 148,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: listing.graded && listing.grade != null
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: _buildSlab(
                            listing: listing,
                            def: def,
                            width: 112,
                            compact: false,
                          ),
                        )
                      : PortraitSlotArt(
                          url: def.displayArtUrl,
                          foil: listing.foil,
                          width: 112,
                          height: 156,
                          landscape: def.isLandscapeCard,
                          radius: 10,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '${def.setCode}${def.number != null ? ' #${def.number}' : ''}'
                      '${listing.foil ? ' · Foil' : ''}'
                      '${listing.graded ? ' · PSA' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.jakarta(
                        fontSize: 11,
                        height: 1.2,
                        color: CC.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${listing.price.toStringAsFixed(2)}',
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                    if (dealPct >= 0.08)
                      Text(
                        '−${(dealPct * 100).round()}% vs fair',
                        style: AppText.jakarta(
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    Text(
                      'See Buying Options',
                      style: AppText.jakarta(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: CC.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyNowRow extends StatelessWidget {
  const _BuyNowRow({
    required this.listing,
    required this.def,
    required this.onTap,
    required this.onBuy,
    this.offerCount = 1,
    this.dealPct = 0,
    this.busy = false,
  });

  final MarketListing listing;
  final CardDef def;
  final VoidCallback onTap;
  final VoidCallback onBuy;
  final int offerCount;
  final double dealPct;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final gradeTxt = listing.graded && listing.grade != null
        ? 'PSA ${listing.grade! >= 10 ? '10' : listing.grade!.toStringAsFixed(listing.grade! % 1 == 0 ? 0 : 1)}'
            '${listing.foil ? ' · Foil' : ''}'
        : '${listing.condition.label}${listing.foil ? ' · Foil' : ' · Raw'}';
    final fromLabel = offerCount > 1
        ? '$offerCount offers from \$${listing.price.toStringAsFixed(2)}'
        : '\$${listing.price.toStringAsFixed(2)}';

    return Material(
      color: CC.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CC.line),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 112,
                child: ClipRect(
                  child: listing.graded && listing.grade != null
                      ? FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: _buildSlab(
                            listing: listing,
                            def: def,
                            width: 100,
                            compact: true,
                          ),
                        )
                      : PortraitSlotArt(
                          url: def.displayArtUrl,
                          foil: listing.foil,
                          width: 64,
                          height: 88,
                          landscape: def.isLandscapeCard,
                          radius: 8,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gradeTxt,
                      style: AppText.jakarta(
                        fontSize: 12,
                        color: CC.inkMuted,
                      ),
                    ),
                    Text(
                      offerCount > 1
                          ? '$offerCount sellers · tap for comps'
                          : (listing.sellerAlias ?? listing.sellerType.label),
                      style: AppText.jakarta(
                        fontSize: 11,
                        color: CC.inkMuted,
                      ),
                    ),
                    if (dealPct >= 0.08) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          'Deal −${(dealPct * 100).round()}% vs fair',
                          style: AppText.jakarta(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFBBF24),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      fromLabel,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: busy ? null : onBuy,
                style: FilledButton.styleFrom(
                  backgroundColor: CC.accent,
                  minimumSize: const Size(72, 40),
                ),
                child: Text(
                  'BUY',
                  style: AppText.jakarta(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
