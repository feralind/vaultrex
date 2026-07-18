import 'package:flutter/material.dart';

import '../data/onboarding.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _page = PageController();
  int _index = 0;
  String _game = 'riftbound';

  Future<void> _next() async {
    if (_index < 2) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await OnboardingStore.complete(gameId: _game);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return GlowBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    if (_index > 0)
                      IconButton(
                        onPressed: () => _page.previousPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      )
                    else
                      const SizedBox(width: 48),
                    const Expanded(child: Center(child: CandyLogo(size: 28))),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    const _IntroPage(),
                    const _RipPacksPage(),
                    _CollectPage(
                      selected: _game,
                      onSelect: (id) => setState(() => _game = id),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(_index == 2 ? 'CONTINUE' : 'NEXT'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final on = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: on ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: on ? CC.ink : CC.inkMuted.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }),
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

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  // Featured pack arts (same assets as Instapacks).
  static const _packLeft = 'assets/featured_packs/riftbound/pack_legendary.png';
  static const _packRight = 'assets/featured_packs/riftbound/pack_mythic.png';
  static const _packFront = 'assets/featured_packs/riftbound/pack_rare.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 360,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 24,
                  right: 24,
                  top: 40,
                  bottom: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFF59E0B).withValues(alpha: 0.32),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -4,
                  top: 48,
                  child: Transform.rotate(
                    angle: -0.22,
                    child: _HeroPackImage(asset: _packLeft, width: 148, height: 222),
                  ),
                ),
                Positioned(
                  right: -4,
                  top: 36,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: _HeroPackImage(asset: _packRight, width: 148, height: 222),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Transform.rotate(
                    angle: -0.04,
                    child: _HeroPackImage(asset: _packFront, width: 196, height: 294),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const BindoraMark(size: 72, framed: false),
          const SizedBox(height: 14),
          Text(
            'Bindora',
            style: AppText.jakarta(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Built for collectors',
            style: AppText.jakarta(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Rip packs, track your collection, and chase the cards you want.',
            textAlign: TextAlign.center,
            style: AppText.jakarta(
              color: CC.inkMuted,
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _HeroPackImage extends StatelessWidget {
  const _HeroPackImage({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _RipPacksPage extends StatefulWidget {
  const _RipPacksPage();

  @override
  State<_RipPacksPage> createState() => _RipPacksPageState();
}

class _RipPacksPageState extends State<_RipPacksPage>
    with SingleTickerProviderStateMixin {
  // Featured pack arts — fanned like the onboarding reference.
  static const _packLeft = 'assets/featured_packs/riftbound/pack_legendary.png';
  static const _packRight = 'assets/featured_packs/riftbound/pack_mythic.png';
  static const _packCenter = 'assets/featured_packs/riftbound/pack_rare.png';

  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ~2× the previous onboarding fan (~104×156 → ~200×300).
    const packW = 200.0;
    const packH = 300.0;
    const fanSpread = 72.0;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                height: 380,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Soft dim glow behind the fan.
                    Positioned(
                      left: 28,
                      right: 28,
                      top: 48,
                      bottom: 24,
                      child: Opacity(
                        opacity: t * 0.85,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFF59E0B).withValues(alpha: 0.22),
                                const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Left — behind, ~18° CCW.
                    Transform.translate(
                      offset: Offset(
                        -fanSpread - 40 * (1 - t),
                        12 + 28 * (1 - t),
                      ),
                      child: Opacity(
                        opacity: t,
                        child: Transform.rotate(
                          angle: -0.32, // ~18°
                          child: _HeroPackImage(
                            asset: _packLeft,
                            width: packW,
                            height: packH,
                          ),
                        ),
                      ),
                    ),
                    // Right — behind, ~18° CW.
                    Transform.translate(
                      offset: Offset(
                        fanSpread + 40 * (1 - t),
                        12 + 28 * (1 - t),
                      ),
                      child: Opacity(
                        opacity: t,
                        child: Transform.rotate(
                          angle: 0.32, // ~18°
                          child: _HeroPackImage(
                            asset: _packRight,
                            width: packW,
                            height: packH,
                          ),
                        ),
                      ),
                    ),
                    // Center — upright, in front.
                    Transform.translate(
                      offset: Offset(0, 36 * (1 - t)),
                      child: Opacity(
                        opacity: t,
                        child: _HeroPackImage(
                          asset: _packCenter,
                          width: packW + 12,
                          height: packH + 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rip real cards',
                style: AppText.jakarta(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Real cards in every Instapack!',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ship them or exchange them for Candy to buy more packs.',
                textAlign: TextAlign.center,
                style: AppText.jakarta(
                  color: CC.inkMuted,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        );
      },
    );
  }
}

class _CollectPage extends StatelessWidget {
  const _CollectPage({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you collect?',
            style: AppText.jakarta(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'So we can personalize your home page.',
            style: AppText.jakarta(color: CC.inkMuted),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              itemCount: kGames.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                // Taller tiles so enlarged game logos stay readable.
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, i) {
                final g = kGames[i];
                return GamePickTile(
                  name: g.name,
                  logoAsset: g.logoAsset,
                  accent: g.color,
                  selected: selected == g.id,
                  enabled: g.enabled,
                  logoScale: g.logoScale,
                  onTap: () => onSelect(g.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
