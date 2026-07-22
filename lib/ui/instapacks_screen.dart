import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/featured_packs.dart';
import '../data/onboarding.dart';
import '../data/riftbound_catalog.dart';
import '../game/game_controller.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/cash_top_up_sheet.dart';
import '../widgets/game_widgets.dart';
import '../widgets/live_ambient.dart';
import '../widgets/ui_kit.dart';
import 'engagement/engagement_hub.dart';
import 'featured_pack_detail.dart';
import 'pack_detail.dart';
import 'sealed_inventory.dart';
import 'social/auction_pit_screen.dart';

class InstapacksScreen extends ConsumerStatefulWidget {
  const InstapacksScreen({super.key});

  @override
  ConsumerState<InstapacksScreen> createState() => _InstapacksScreenState();
}

class _InstapacksScreenState extends ConsumerState<InstapacksScreen>
    with SingleTickerProviderStateMixin {
  String? _pendingGame;
  late final AnimationController _sharedFloat;
  bool _dailyRitualShown = false;

  @override
  void initState() {
    super.initState();
    _sharedFloat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeDailyRitual());
  }

  Future<void> _maybeDailyRitual() async {
    if (!mounted || _dailyRitualShown) return;
    final state = ref.read(gameProvider);
    if (!state.ready) return;
    final eng = state.engagement;
    if (eng.dailyClaimDate == engagementDayKey()) return;
    _dailyRitualShown = true;
    final streak = eng.dailyStreak;
    final preview = dailyClaimCandyForStreak(
      eng.dailyClaimDate ==
              engagementDayKey(DateTime.now().subtract(const Duration(days: 1)))
          ? streak + 1
          : 1,
    );
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: CC.bgElevated,
        title: Text(
          'Daily candy',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Claim ~$preview candy and keep your streak cooking before you rip.',
          style: AppText.jakarta(color: CC.inkMuted, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Later',
              style: AppText.jakarta(color: CC.inkMuted),
            ),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(gameProvider.notifier).claimDailyLogin();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Daily claimed — streak locked in'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: CC.candy,
              foregroundColor: Colors.black,
            ),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sharedFloat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (!state.ready) {
      return const Center(child: CircularProgressIndicator(color: CC.accent));
    }

    final active = _pendingGame ?? notifier.activeGameId;
    final listings = state.sealedListings.where((l) {
      final p = notifier.sealedById(l.sealedProductId);
      return p != null;
    }).toList();

    final candy = state.player.candy;
    final cash = state.player.cash;
    final featuredPacks = featuredPacksFor(
      active,
      rotationSeed: state.engagement.featuredRotationSeed,
    );
    final hasMarket = featuredPacks.isNotEmpty || listings.isNotEmpty;
    final sealedTitle = switch (active) {
      'pokemon' => 'Pokémon Sealed',
      'mtg' => 'Magic Sealed',
      'onepiece' => 'One Piece Sealed',
      'yugioh' => 'Yu-Gi-Oh! Sealed',
      'gundam' => 'Gundam Sealed',
      _ => 'Riftbound Sealed',
    };

    return LiveAmbientBackdrop(
      child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _InstapacksHero(
            candy: candy,
            cash: cash,
            onTopUp: () => showCashTopUp(context, ref),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _InstapacksHeatStrip(),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _AuctionPressureChip(),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SealedInventoryBanner(),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: FeaturedDropTimer(),
              ),
              SizedBox(
                // logoScale 1.22 (Riftbound) needs >64 or Column overflows ~1.8px.
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: kGames.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final g = kGames[i];
                    return _GameIcon(
                      selected: active == g.id,
                      logoAsset: g.logoAsset,
                      color: g.color,
                      logoScale: g.logoScale,
                      locked: !g.enabled,
                      onTap: g.enabled
                          ? () async {
                              if (g.id == notifier.activeGameId) {
                                setState(() => _pendingGame = g.id);
                                return;
                              }
                              setState(() => _pendingGame = g.id);
                              await notifier.switchFranchise(g.id);
                              if (mounted) setState(() => _pendingGame = null);
                            }
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (!hasMarket)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Coming soon', style: TextStyle(color: CC.inkMuted)),
            ),
          )
        else ...[
          if (featuredPacks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('Featured Packs', style: AppText.titleSm()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final pack = featuredPacks[i];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _FeaturedTile(
                          pack: pack,
                          chaseArtUrls: _featuredChaseUrls(notifier, pack),
                          float: _sharedFloat,
                          franchiseId: active,
                          onTap: () => showFeaturedPackDetail(context, ref, pack),
                        ),
                        Positioned(
                          left: 6,
                          top: 6,
                          child: FeaturedPityChip(packId: pack.id),
                        ),
                      ],
                    );
                  },
                  childCount: featuredPacks.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(sealedTitle, style: AppText.titleSm()),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final listing = listings[i];
                  final product = notifier.sealedById(listing.sealedProductId)!;
                  final soldOut = listing.stock <= 0;
                  return _InstaTile(
                    product: product,
                    listing: listing,
                    soldOut: soldOut,
                    chaseArtUrls: chaseArtUrlsForSet(
                      notifier.catalog,
                      product.setCode,
                      count: 6,
                    ),
                    float: _sharedFloat,
                    franchiseId: active,
                    onBuy: soldOut
                        ? null
                        : () => showPackDetail(
                              context,
                              ref,
                              product: product,
                              listing: listing,
                            ),
                  );
                },
                childCount: listings.length,
              ),
            ),
          ),
        ],
      ],
    ),
    );
  }
}

/// Compact daily / pity / 1-away / season strip under the Instapacks hero.
class _InstapacksHeatStrip extends ConsumerWidget {
  const _InstapacksHeatStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eng = ref.watch(gameProvider.select((s) => s.engagement));
    final season = ref.watch(gameProvider.select((s) => s.activeSeason));
    final notifier = ref.read(gameProvider.notifier);
    final claimed = eng.dailyClaimDate == engagementDayKey();
    final away = notifier.oneAwaySets();
    var maxHeat = 0;
    for (final dry in eng.featuredPity.values) {
      final h = pityHeatPercent(dry);
      if (h > maxHeat) maxHeat = h;
    }
    final seasonDone = season?.quests.where((q) => q.complete).length ?? 0;
    final seasonTotal = season?.quests.length ?? 0;

    final chips = <Widget>[
      if (!claimed)
        _HeatChip(
          label: 'Daily ready',
          color: CC.candy,
          onTap: () async {
            await notifier.claimDailyLogin();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Daily claimed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        )
      else
        _HeatChip(
          label: 'Streak ${eng.dailyStreak}',
          color: CC.scan,
          onTap: () => openEngagementHub(context),
        ),
      if (maxHeat > 0)
        _HeatChip(
          label: 'Chase heat $maxHeat%',
          color: CC.candy,
          onTap: () {
            final pack = hottestFeaturedPack(
              gameId: ref.read(gameProvider).franchiseId,
              featuredPity: eng.featuredPity,
              rotationSeed: eng.featuredRotationSeed,
            );
            if (pack == null) return;
            showFeaturedPackDetail(context, ref, pack);
          },
        ),
      if (away.isNotEmpty)
        _HeatChip(
          label: '1-away · ${away.first.setName}',
          color: CC.accent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SetCompletionGridScreen(
                  setCode: away.first.setCode,
                ),
              ),
            );
          },
        ),
      if (seasonTotal > 0)
        _HeatChip(
          label: 'Season $seasonDone/$seasonTotal',
          color: const Color(0xFFFB923C),
          onTap: () => openEngagementHub(context),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _HeatChip extends StatelessWidget {
  const _HeatChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: AppText.jakarta(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ending-soon auction / rival pressure on Instapacks cold open.
class _AuctionPressureChip extends ConsumerWidget {
  const _AuctionPressureChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctions = ref.watch(gameProvider.select((s) => s.auctions));
    if (auctions.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now().millisecondsSinceEpoch;
    AuctionLot? soonest;
    var soonestLeft = 1 << 30;
    for (final a in auctions) {
      final end = a.endsAtMs;
      if (end == null) continue;
      final left = end - now;
      if (left <= 0) continue;
      if (left < soonestLeft) {
        soonestLeft = left;
        soonest = a;
      }
    }
    soonest ??= auctions.first;
    final secs = soonest.endsAtMs == null
        ? null
        : ((soonest.endsAtMs! - now) / 1000).ceil().clamp(0, 99999);
    final rival = soonest.rivalName;
    final label = secs == null
        ? (rival != null
            ? '$rival is bidding in the Pit'
            : '${auctions.length} live lots in the Pit')
        : (rival != null
            ? '$rival sniping · ${secs}s left'
            : 'Lot ending · ${secs}s · ${auctions.length} live');

    return Material(
      color: const Color(0xFFF472B6).withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AuctionPitScreen(),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF472B6).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.gavel_rounded, size: 18, color: Color(0xFFF472B6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: const Color(0xFFF472B6),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: CC.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bindora Instapacks header: title, blurb, half-fade pack fan.
class _InstapacksHero extends StatefulWidget {
  const _InstapacksHero({
    required this.candy,
    required this.cash,
    required this.onTopUp,
  });

  final int candy;
  final double cash;
  final VoidCallback onTopUp;

  @override
  State<_InstapacksHero> createState() => _InstapacksHeroState();
}

class _InstapacksHeroState extends State<_InstapacksHero>
    with SingleTickerProviderStateMixin {
  // Dedicated Instapacks top-border entities (not shop tier assets).
  static const _left = 'assets/instapacks/border_left.png';
  static const _center = 'assets/instapacks/border_middle.png';
  static const _right = 'assets/instapacks/border_right.png';
  static const _packScale = 0.825 * 1.20; // +20% vs prior Instapacks border size

  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Instapacks',
                      textAlign: TextAlign.center,
                      style: AppText.display(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real cards. Real pulls.',
                      textAlign: TextAlign.center,
                      style: AppText.bodySm(),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BalanceBar(
                    candy: widget.candy,
                    cash: widget.cash,
                    onTopUp: widget.onTopUp,
                    axis: Axis.vertical,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                final bob = Curves.easeInOut.transform(_float.value);
                return Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Soft dark radial glow (not a product spotlight plate).
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 280,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.06),
                                const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Half-fade fan — packs emerge from bottom into black.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 200,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.42, 1.0],
                          ).createShader(bounds);
                        },
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Left — behind, tilted CCW.
                            Positioned(
                              left: 18,
                              bottom: -70 + bob * 5,
                              child: Transform.rotate(
                                angle: -0.28,
                                child: _HeroFanPack(
                                  asset: _left,
                                  width: 148 * _packScale,
                                ),
                              ),
                            ),
                            // Right — behind, tilted CW.
                            Positioned(
                              right: 18,
                              bottom: -70 + bob * 5,
                              child: Transform.rotate(
                                angle: 0.28,
                                child: _HeroFanPack(
                                  asset: _right,
                                  width: 148 * _packScale,
                                ),
                              ),
                            ),
                            // Center — front, slight float.
                            Positioned(
                              bottom: -78 + bob * 7,
                              child: Transform.rotate(
                                angle: -0.02,
                                child: _HeroFanPack(
                                  asset: _center,
                                  width: 168 * _packScale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFanPack extends StatelessWidget {
  const _HeroFanPack({required this.asset, required this.width});

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width / 0.68;
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _GameIcon extends StatelessWidget {
  const _GameIcon({
    required this.selected,
    required this.logoAsset,
    required this.color,
    this.logoScale = 1,
    this.onTap,
    this.locked = false,
  });

  final bool selected;
  final String logoAsset;
  final Color color;
  final double logoScale;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final markH = 40 * logoScale;
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: color.withValues(alpha: 0.12),
      highlightColor: color.withValues(alpha: 0.06),
      child: Opacity(
        opacity: locked ? 0.35 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowingGameLogo(
              asset: logoAsset,
              glowColor: color,
              height: markH,
              width: logoScale > 1 ? markH : 72,
              glowing: selected,
              glowStrength: 1.15,
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedTile extends StatefulWidget {
  const _FeaturedTile({
    required this.pack,
    required this.chaseArtUrls,
    required this.float,
    required this.franchiseId,
    this.onTap,
  });

  final FeaturedPackDef pack;
  final List<String> chaseArtUrls;
  final Animation<double> float;
  final String franchiseId;
  final VoidCallback? onTap;

  @override
  State<_FeaturedTile> createState() => _FeaturedTileState();
}

class _FeaturedTileState extends State<_FeaturedTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateHits;
  int _hitIndex = 0;

  FeaturedPackDef get pack => widget.pack;
  List<String> get chaseArtUrls => widget.chaseArtUrls;

  @override
  void initState() {
    super.initState();
    _rotateHits = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (chaseArtUrls.length > 1 && mounted) {
            setState(() => _hitIndex = (_hitIndex + 1) % chaseArtUrls.length);
          }
          _rotateHits.forward(from: 0);
        }
      });
    if (chaseArtUrls.length > 1) {
      _rotateHits.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _FeaturedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chaseArtUrls.length != chaseArtUrls.length) {
      _hitIndex = 0;
      if (chaseArtUrls.length > 1 && !_rotateHits.isAnimating) {
        _rotateHits.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _rotateHits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candy = pack.candyPrice;
    final hitUrl = chaseArtUrls.isEmpty
        ? null
        : chaseArtUrls[_hitIndex % chaseArtUrls.length];

    return Material(
      color: CC.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CC.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Center(child: _TileBloom(colors: pack.tier.bloomColors)),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            hitUrl != null ? 10 : 18,
                            14,
                            hitUrl != null ? 36 : 18,
                            8,
                          ),
                          child: Transform.scale(
                            scale: 0.825,
                            child: Image.asset(
                              pack.assetPath,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, _, _) => PackVisual(
                                title: pack.tier.label,
                                colors: pack.tier.bloomColors,
                                width: 110,
                                height: 160,
                                franchiseId: widget.franchiseId,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (hitUrl != null)
                        Align(
                          alignment: const Alignment(0.92, 0.35),
                          child: AnimatedBuilder(
                            animation: widget.float,
                            builder: (context, child) {
                              final dy = Curves.easeInOut
                                  .transform(widget.float.value);
                              return Transform.translate(
                                offset: Offset(0, -6 * dy),
                                child: child,
                              );
                            },
                            child: Transform.rotate(
                              angle: 0.12,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 480),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: _ChasePreviewCard(
                                  key: ValueKey(hitUrl),
                                  url: hitUrl,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                        color: CC.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\$${pack.priceUsd.toStringAsFixed(2)}',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.cookie, size: 13, color: CC.candy),
                        const SizedBox(width: 3),
                        Text(
                          candy >= 1000
                              ? '${(candy / 1000).toStringAsFixed(candy % 1000 == 0 ? 0 : 1)}K'
                              : '$candy',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: CC.candy,
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
    );
  }
}

/// Top EV chase art URLs for a Featured Pack tile preview.
List<String> _featuredChaseUrls(GameNotifier notifier, FeaturedPackDef pack) {
  final urls = <String>[];
  final rankedHits = [...pack.topHitIds]
    ..sort((a, b) {
      final ca = notifier.cardById(a.cardId);
      final cb = notifier.cardById(b.cardId);
      return (cb?.marketPrice ?? 0).compareTo(ca?.marketPrice ?? 0);
    });
  for (final hit in rankedHits) {
    final c = notifier.cardById(hit.cardId);
    final url = c?.displayArtUrl ?? '';
    if (url.isNotEmpty) urls.add(url);
  }
  if (urls.isNotEmpty) return urls.take(6).toList();

  final pool = pack.poolSelector(notifier.catalog.cards);
  final ranked = [...pool]
    ..sort((a, b) => b.card.marketPrice.compareTo(a.card.marketPrice));
  for (final e in ranked.take(6)) {
    final url = e.card.displayArtUrl;
    if (url.isNotEmpty) urls.add(url);
  }
  return urls;
}

class _ChasePreviewCard extends StatelessWidget {
  const _ChasePreviewCard({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final tileW = MediaQuery.sizeOf(context).width;
    final cellW = (tileW - 14 * 2 - 12) / 2;
    final cardW = (cellW * 0.38).clamp(56.0, 88.0);
    final cardH = cardW / (2.5 / 3.5);
    // Half-shown peek: lower portion fades out (Featured / Sealed shared look).
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.45, 1.0],
        ).createShader(bounds);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: CardArt(
          url: url,
          autoPlay: false,
          width: cardW,
          height: cardH,
          radius: 7,
        ),
      ),
    );
  }
}

class _InstaTile extends StatefulWidget {
  const _InstaTile({
    required this.product,
    required this.listing,
    required this.soldOut,
    required this.chaseArtUrls,
    required this.float,
    required this.franchiseId,
    this.onBuy,
  });

  final SealedProduct product;
  final SealedListing listing;
  final bool soldOut;
  final List<String> chaseArtUrls;
  final Animation<double> float;
  final String franchiseId;
  final VoidCallback? onBuy;

  @override
  State<_InstaTile> createState() => _InstaTileState();
}

class _InstaTileState extends State<_InstaTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateHits;
  int _hitIndex = 0;

  SealedProduct get product => widget.product;
  SealedListing get listing => widget.listing;
  List<String> get chaseArtUrls => widget.chaseArtUrls;

  List<Color> get _packColors {
    switch (product.setCode) {
      case 'OGN':
        return const [Color(0xFFFDE68A), Color(0xFFB45309), Color(0xFFF59E0B)];
      case 'SFD':
        return const [Color(0xFF86EFAC), Color(0xFF166534), Color(0xFF22C55E)];
      case 'UNL':
        return const [Color(0xFF93C5FD), Color(0xFF1E3A8A), Color(0xFF3B82F6)];
      default:
        return const [Color(0xFFE2E8F0), Color(0xFF475569), Color(0xFF94A3B8)];
    }
  }

  @override
  void initState() {
    super.initState();
    _rotateHits = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (chaseArtUrls.length > 1 && mounted) {
            setState(() => _hitIndex = (_hitIndex + 1) % chaseArtUrls.length);
          }
          _rotateHits.forward(from: 0);
        }
      });
    if (chaseArtUrls.length > 1) _rotateHits.forward();
  }

  @override
  void dispose() {
    _rotateHits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candy = (listing.price * 100).round();
    final shortName = product.name
        .replaceFirst(RegExp(r'^.*? - '), '')
        .replaceAll('Booster ', '');
    final art = product.displayArtUrl.isNotEmpty ? product.displayArtUrl : null;
    final hitUrl = chaseArtUrls.isEmpty
        ? null
        : chaseArtUrls[_hitIndex % chaseArtUrls.length];

    return Material(
      color: CC.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: widget.onBuy,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CC.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Center(child: _TileBloom(colors: _packColors)),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            hitUrl != null ? 10 : 18,
                            14,
                            hitUrl != null ? 36 : 18,
                            8,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Height-only pack fit — review Flip ratios if art clips.
                              final maxH = constraints.maxHeight;
                              final maxW = constraints.maxWidth;
                              var h = maxH * 0.94;
                              var w = h * 0.68;
                              if (w > maxW) {
                                w = maxW;
                                h = w / 0.68;
                              }
                              return Center(
                                child: PackVisual(
                                  title: product.setCode,
                                  imageUrl: art,
                                  colors: _packColors,
                                  width: w,
                                  height: h,
                                  franchiseId: widget.franchiseId,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (hitUrl != null && !widget.soldOut)
                        Align(
                          alignment: const Alignment(0.92, 0.35),
                          child: AnimatedBuilder(
                            animation: widget.float,
                            builder: (context, child) {
                              final dy = Curves.easeInOut
                                  .transform(widget.float.value);
                              return Transform.translate(
                                offset: Offset(0, -6 * dy),
                                child: child,
                              );
                            },
                            child: Transform.rotate(
                              angle: 0.12,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 480),
                                child: _ChasePreviewCard(
                                  key: ValueKey(hitUrl),
                                  url: hitUrl,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.soldOut)
                        Positioned.fill(
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.black.withValues(alpha: 0.4),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              color: Colors.black.withValues(alpha: 0.58),
                              child: Text(
                                'Sold out',
                                textAlign: TextAlign.center,
                                style: AppText.jakarta(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                        color: widget.soldOut ? CC.inkMuted : CC.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\$${listing.price.toStringAsFixed(2)}',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.cookie, size: 13, color: CC.candy),
                        const SizedBox(width: 3),
                        Text(
                          candy >= 1000
                              ? '${(candy / 1000).toStringAsFixed(candy % 1000 == 0 ? 0 : 1)}K'
                              : '$candy',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: CC.candy,
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
    );
  }
}

class _TileBloom extends StatefulWidget {
  const _TileBloom({required this.colors});
  final List<Color> colors;

  @override
  State<_TileBloom> createState() => _TileBloomState();
}

class _TileBloomState extends State<_TileBloom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.colors.first;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 90 + 10 * t,
          height: 108 + 12 * t,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: base.withValues(alpha: 0.12 + 0.08 * t),
                blurRadius: 24 + 10 * t,
                spreadRadius: 0,
              ),
            ],
          ),
        );
      },
    );
  }
}
