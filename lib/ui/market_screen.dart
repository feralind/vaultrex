import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/card_detail_sheet.dart';
import '../widgets/game_widgets.dart';

enum _MarketFilter { all, raw, psa, foil }

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _query = '';
  /// null = all sets (type filter already has an "All" chip).
  String? _set;
  _MarketFilter _filter = _MarketFilter.all;

  static const _setCodes = ['OGS', 'OGN', 'SFD', 'UNL'];

  List<MarketListing> _filtered(List<MarketListing> market, GameNotifier n) {
    return market.where((m) {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (!state.ready) {
      return const Center(child: CircularProgressIndicator(color: CC.accent));
    }

    final listings = _filtered(state.market, notifier);
    final featured = [...listings]..sort((a, b) => b.price.compareTo(a.price));
    final carousel = featured.take(12).toList();

    return Column(
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
                      'Singles · raw & PSA slabs',
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CC.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CC.line),
                ),
                child: Text(
                  '\$${state.player.cash.toStringAsFixed(2)}',
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF34D399),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
              ..._setCodes.map((s) {
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
                  child: Text(
                    'No listings match — try Advance Day in Settings.',
                    style: AppText.jakarta(color: CC.inkMuted),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                  children: [
                    if (carousel.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: Text(
                          'Cards (${listings.length})',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 340,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: carousel.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final m = carousel[i];
                            final def = notifier.cardById(m.cardId)!;
                            return KeyedSubtree(
                              key: ValueKey('carousel-${m.id}'),
                              child: _CarouselCard(
                                listing: m,
                                def: def,
                                onTap: () => _openDetail(context, m, def),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Text(
                          'Buy Now',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                    ...listings.map((m) {
                      final def = notifier.cardById(m.cardId)!;
                      return Padding(
                        key: ValueKey('buy-${m.id}'),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _BuyNowRow(
                          listing: m,
                          def: def,
                          onTap: () => _openDetail(context, m, def),
                          onBuy: () => _buy(context, m),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _buy(BuildContext context, MarketListing listing) async {
    final cash = ref.read(gameProvider).player.cash;
    if (cash < listing.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough cash.')),
      );
      return;
    }
    await ref.read(gameProvider.notifier).buyMarketListing(listing.id);
    if (!context.mounted) return;
    final msg = ref.read(gameProvider).message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg ?? 'Purchased.')),
    );
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
        );
      },
    );
  }
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
  });

  final MarketListing listing;
  final CardDef def;
  final VoidCallback onTap;

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
                      : CardArt(
                          url: def.displayArtUrl,
                          foil: listing.foil,
                          autoPlay: false,
                          width: 112,
                          height: 156,
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
  });

  final MarketListing listing;
  final CardDef def;
  final VoidCallback onTap;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final gradeTxt = listing.graded && listing.grade != null
        ? 'PSA ${listing.grade! >= 10 ? '10' : listing.grade!.toStringAsFixed(listing.grade! % 1 == 0 ? 0 : 1)}'
            '${listing.foil ? ' · Foil' : ''}'
        : '${listing.condition.label}${listing.foil ? ' · Foil' : ' · Raw'}';

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
                      : CardArt(
                          url: def.displayArtUrl,
                          foil: listing.foil,
                          autoPlay: false,
                          width: 64,
                          height: 88,
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
                      listing.sellerAlias ?? listing.sellerType.label,
                      style: AppText.jakarta(
                        fontSize: 11,
                        color: CC.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${listing.price.toStringAsFixed(2)}',
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
                onPressed: onBuy,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: CC.accent,
                ),
                child: Text(
                  'BUY',
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
