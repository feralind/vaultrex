import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/featured_packs.dart';
import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/fake_google_pay_sheet.dart';
import '../widgets/game_widgets.dart';
import '../widgets/knockout_image.dart';
import '../widgets/pack_theater.dart';

Future<void> showFeaturedPackDetail(
  BuildContext context,
  WidgetRef ref,
  FeaturedPackDef pack,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FeaturedPackDetailPage(pack: pack),
    ),
  );
}

class FeaturedPackDetailPage extends ConsumerStatefulWidget {
  const FeaturedPackDetailPage({super.key, required this.pack});

  final FeaturedPackDef pack;

  @override
  ConsumerState<FeaturedPackDetailPage> createState() =>
      _FeaturedPackDetailPageState();
}

class _FeaturedPackDetailPageState extends ConsumerState<FeaturedPackDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  bool _busy = false;

  FeaturedPackDef get pack => widget.pack;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final active = route?.isCurrent ?? true;
    if (active) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  List<CardDef> _resolveHits(GameNotifier notifier) {
    final out = <CardDef>[];
    for (final hit in pack.topHitIds) {
      final c = notifier.cardById(hit.cardId);
      if (c != null) out.add(c);
    }
    if (out.isNotEmpty) return out;
    final pool = pack.poolSelector(notifier.catalog.cards);
    final ranked = [...pool]
      ..sort((a, b) => b.card.marketPrice.compareTo(a.card.marketPrice));
    return ranked.take(8).map((e) => e.card).toList();
  }

  List<CardDef> _allPoolCards(GameNotifier notifier) {
    final pool = pack.poolSelector(notifier.catalog.cards);
    final ranked = [...pool]
      ..sort((a, b) => b.card.marketPrice.compareTo(a.card.marketPrice));
    return ranked.map((e) => e.card).toList();
  }

  double _oddsFor(CardDef c) {
    for (final hit in pack.topHitIds) {
      if (hit.cardId == c.id) return hit.oddsPercent;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final hits = _resolveHits(notifier);
    final candy = pack.candyPrice;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Sticky Buy Now + Buy with Candy stack (~52+8+48) + bar padding.
    const stickyBarContent = 12.0 + 52.0 + 8.0 + 48.0 + 12.0;
    final scrollBottomPad = stickyBarContent + bottom + 24;

    return Scaffold(
      backgroundColor: CC.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: CC.bg.withValues(alpha: 0.92),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  pack.tier.label,
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CandyBalance(state.player.candy),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroStage(
                        pack: pack,
                        hits: hits,
                        spin: _spin,
                        franchiseId: ref.watch(
                          gameProvider.select((s) => s.franchiseId),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        pack.name,
                        textAlign: TextAlign.center,
                        style: AppText.jakarta(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buy for \$${pack.priceUsd.toStringAsFixed(2)}  ·  or buy for ${_fmtCandy(candy)} Candy',
                        textAlign: TextAlign.center,
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        pack.blurb,
                        textAlign: TextAlign.center,
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Top Hits',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chase cards weighted into this pack — odds shown per hit.',
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShowcaseCardRow(
                        itemCount: hits.length,
                        itemBuilder: (context, i) {
                          final c = hits[i];
                          final odds = _oddsFor(c);
                          const cardW = 168.0;
                          const cardH = cardW * (3.5 / 2.5);
                          return SizedBox(
                            width: cardW,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CardArt(
                                  url: c.displayArtUrl,
                                  autoPlay: false,
                                  width: cardW,
                                  height: cardH,
                                  radius: 12,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppText.jakarta(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (odds > 0)
                                  Text(
                                    '${odds.toStringAsFixed(odds >= 10 ? 0 : 1)}%',
                                    style: AppText.jakarta(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: CC.accentHot,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => _showAllCards(context, notifier),
                          child: Text(
                            'View all cards →',
                            style: AppText.jakarta(
                              fontWeight: FontWeight.w700,
                              color: CC.accentHot,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ExchangeBanner(),
                      const SizedBox(height: 22),
                      Text(
                        'Pull Rates by Pack Value',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Approximate odds for the highlight slot EV band.',
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...pack.pullRates.map((r) => _PullRateRow(row: r)),
                      SizedBox(height: scrollBottomPad),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: CC.bgElevated.withValues(alpha: 0.96),
                  border: const Border(top: BorderSide(color: CC.line)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ||
                                notifier.isShopBusy ||
                                state.lastRip?.isNotEmpty == true ||
                                state.player.cash < pack.priceUsd
                            ? null
                            : () => _buy(PaymentMethod.cash),
                        child: Text(
                          'BUY NOW  ·  \$${pack.priceUsd.toStringAsFixed(2)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _busy ||
                                notifier.isShopBusy ||
                                state.lastRip?.isNotEmpty == true ||
                                state.player.candy < candy
                            ? null
                            : () => _buy(PaymentMethod.candy),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CC.candy,
                          side: const BorderSide(color: CC.candy),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cookie, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'BUY WITH  ${_fmtCandy(candy)} CANDY',
                              style: AppText.jakarta(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(PaymentMethod method) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final notifier = ref.read(gameProvider.notifier);
      final navContext = Navigator.of(context, rootNavigator: true).context;
      if (method == PaymentMethod.cash) {
        final paid = await showFakeGooglePay(context, amount: pack.priceUsd);
        if (!paid || !mounted) return;
      }
      final ok = await notifier.buyFeaturedPack(pack.id, payWith: method);
      if (!mounted) return;
      if (!ok) {
        final msg = ref.read(gameProvider).message ?? 'Purchase failed.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      Navigator.pop(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!navContext.mounted) return;
        showPackTheater(
          navContext,
          ref,
          alreadyOpened: true,
          packImageUrl: pack.assetPath,
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAllCards(BuildContext context, GameNotifier notifier) {
    final cards = _allPoolCards(notifier);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CC.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CC.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'All cards in ${pack.name}',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${cards.length}',
                        style: AppText.jakarta(color: CC.inkMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = cards[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CardArt(
                          url: c.thumbArtUrl,
                          autoPlay: false,
                          width: 44,
                          height: 56,
                          radius: 6,
                        ),
                        title: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${c.setCode} · ${c.rarity.label}',
                          style: AppText.jakarta(
                            fontSize: 11,
                            color: CC.inkMuted,
                          ),
                        ),
                        trailing: Text(
                          '\$${c.marketPrice.toStringAsFixed(2)}',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _fmtCandy(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

class _HeroStage extends StatelessWidget {
  const _HeroStage({
    required this.pack,
    required this.hits,
    required this.spin,
    required this.franchiseId,
  });

  final FeaturedPackDef pack;
  final List<CardDef> hits;
  final AnimationController spin;
  final String franchiseId;

  @override
  Widget build(BuildContext context) {
    final bloom = pack.tier.bloomColors.first;
    return SizedBox(
      height: 248,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft dim glow (not a blinding sunburst).
          Container(
            width: 220,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  bloom.withValues(alpha: 0.16),
                  bloom.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (hits.isNotEmpty)
            AnimatedBuilder(
              animation: spin,
              builder: (context, _) {
                final t = spin.value * 2 * math.pi;
                final urls = hits.take(5).toList();
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < urls.length; i++)
                      Transform.translate(
                        offset: Offset(
                          math.cos(t + i * 1.15) * (78 + i * 4),
                          math.sin(t * 0.7 + i * 0.9) * 18 + 36,
                        ),
                        child: Transform.rotate(
                          angle: -0.35 + i * 0.18 + math.sin(t + i) * 0.05,
                          child: Opacity(
                            opacity: 0.88,
                            child: MiniSlab(
                              width: 34,
                              imageUrls: [urls[i].displayArtUrl],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          KnockoutProductImage(
            url: pack.assetPath,
            width: 168 * 0.825,
            height: 236 * 0.825,
            fit: BoxFit.contain,
            error: PackVisual(
              title: pack.tier.label,
              colors: pack.tier.bloomColors,
              width: 140 * 0.825,
              height: 200 * 0.825,
              franchiseId: franchiseId,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExchangeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            CC.candy.withValues(alpha: 0.18),
            CC.accent.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: CC.candy.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cookie, color: CC.candy, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Exchange leftover pulls for Candy at ~70% of fair value '
              '(keep chase cards for full collection value).',
              style: AppText.jakarta(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PullRateRow extends StatelessWidget {
  const _PullRateRow({required this.row});
  final FeaturedPullRateRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              row.tierLabel,
              style: AppText.jakarta(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.priceRangeLabel,
              style: AppText.jakarta(
                color: CC.inkMuted,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${row.percent.toStringAsFixed(0)}%',
            style: AppText.jakarta(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: CC.accentHot,
            ),
          ),
        ],
      ),
    );
  }
}

