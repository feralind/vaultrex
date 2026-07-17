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
import '../ui/featured_pack_detail.dart';
import '../ui/pack_detail.dart';
import '../ui/sealed_inventory.dart';

class InstapacksScreen extends ConsumerStatefulWidget {
  const InstapacksScreen({super.key});

  @override
  ConsumerState<InstapacksScreen> createState() => _InstapacksScreenState();
}

class _InstapacksScreenState extends ConsumerState<InstapacksScreen>
    with SingleTickerProviderStateMixin {
  String? _pendingGame;
  late final AnimationController _sharedFloat;

  @override
  void initState() {
    super.initState();
    _sharedFloat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
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
    final isPokemon = active == 'pokemon';
    final isRiftbound = active == 'riftbound';
    final featuredPacks =
        (isRiftbound || isPokemon) ? featuredPacksFor(active) : const <FeaturedPackDef>[];

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
        SliverToBoxAdapter(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: SealedInventoryBanner(),
              ),
              SizedBox(
                height: 64,
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
        if (!isRiftbound && !isPokemon)
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
                child: Text(
                  'Featured Packs',
                  style: AppText.jakarta(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
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
                    return _FeaturedTile(
                      pack: pack,
                      chaseArtUrls: _featuredChaseUrls(notifier, pack),
                      float: _sharedFloat,
                      franchiseId: active,
                      onTap: () => showFeaturedPackDetail(context, ref, pack),
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
              child: Text(
                isPokemon ? 'Pokémon Sealed' : 'Riftbound Sealed',
                style: AppText.jakarta(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
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

/// Vaultrex Instapacks header: title, blurb, half-fade pack fan.
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
  static const _left = 'assets/featured_packs/pack_legendary.png';
  static const _center = 'assets/featured_packs/pack_rare.png';
  static const _right = 'assets/featured_packs/pack_mythic.png';

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
                      style: AppText.jakarta(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rip packs whenever you want. A digital pack ripping experience where you pull REAL cards.',
                      textAlign: TextAlign.center,
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Learn more →',
                      style: AppText.jakarta(
                        color: CC.accentHot,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CandyBalance(widget.candy),
                  const SizedBox(height: 6),
                  CashBalance(widget.cash, onTap: widget.onTopUp),
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
                                child: _HeroFanPack(asset: _left, width: 148),
                              ),
                            ),
                            // Right — behind, tilted CW.
                            Positioned(
                              right: 18,
                              bottom: -70 + bob * 5,
                              child: Transform.rotate(
                                angle: 0.28,
                                child: _HeroFanPack(asset: _right, width: 148),
                              ),
                            ),
                            // Center — front, slight float.
                            Positioned(
                              bottom: -78 + bob * 7,
                              child: Transform.rotate(
                                angle: -0.02,
                                child: _HeroFanPack(asset: _center, width: 168),
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
    this.onTap,
    this.locked = false,
  });

  final bool selected;
  final String logoAsset;
  final Color color;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: locked ? 0.35 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: GameBrandLogo(asset: logoAsset, height: 40, width: 72),
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
                    ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
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
