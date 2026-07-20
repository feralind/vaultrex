import 'dart:math' as math;

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

  // Dedicated onboarding entities — not shared with shop pack tiers.
  static const _packLeft = 'assets/onboarding/onboarding_firstscreen_left.png';
  static const _packRight = 'assets/onboarding/onboarding_firstscreen_right.png';
  static const _packMiddle =
      'assets/onboarding/onboarding_firstscreen_middle.png';

  /// 17.5% smaller baseline, then +20% for this screen.
  static const _packScale = 0.825 * 1.20;

  @override
  Widget build(BuildContext context) {
    const leftW = 148.0 * _packScale;
    const leftH = 222.0 * _packScale;
    const midW = 196.0 * _packScale;
    const midH = 294.0 * _packScale;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 360 * _packScale + 40,
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
                // Art is already tilted — pull side packs in toward center.
                // Each pack floats on its own rhythm (phase + duration).
                Positioned(
                  left: 36,
                  top: 52,
                  child: _PackHover(
                    duration: const Duration(milliseconds: 2650),
                    amplitude: 5.5,
                    start: 0.0,
                    child: _HeroPackImage(
                      asset: _packLeft,
                      width: leftW,
                      height: leftH,
                    ),
                  ),
                ),
                Positioned(
                  right: 36,
                  top: 40,
                  child: _PackHover(
                    duration: const Duration(milliseconds: 3920),
                    amplitude: 6.5,
                    start: 0.62,
                    child: _HeroPackImage(
                      asset: _packRight,
                      width: leftW,
                      height: leftH,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: _PackHover(
                    duration: const Duration(milliseconds: 3180),
                    amplitude: 7.5,
                    start: 0.28,
                    child: Transform.rotate(
                      angle: -0.04,
                      child: _HeroPackImage(
                        asset: _packMiddle,
                        width: midW,
                        height: midH,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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

/// Independent vertical hover — each pack gets its own duration / phase.
class _PackHover extends StatefulWidget {
  const _PackHover({
    required this.child,
    required this.duration,
    required this.amplitude,
    this.start = 0,
  });

  final Widget child;
  final Duration duration;
  final double amplitude;
  /// Initial controller value 0..1 so packs don't start in sync.
  final double start;

  @override
  State<_PackHover> createState() => _PackHoverState();
}

class _PackHoverState extends State<_PackHover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.start.clamp(0.0, 1.0),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Soft sine-ish bob from reverse easeInOut.
        final t = Curves.easeInOut.transform(_c.value);
        final dy = (t * 2 - 1) * widget.amplitude;
        // Tiny secondary wobble so motion isn't a perfect mirror of neighbors.
        final wobble =
            math.sin(_c.value * math.pi * 2 + widget.start * math.pi) * 0.6;
        return Transform.translate(
          offset: Offset(0, dy + wobble),
          child: child,
        );
      },
      child: widget.child,
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
  // Dedicated onboarding screen-2 entities — not shared with shop tiers.
  static const _packLeft =
      'assets/onboarding/onboarding_secondscreen_left.png';
  static const _packRight =
      'assets/onboarding/onboarding_secondscreen_right.png';
  static const _packCenter =
      'assets/onboarding/onboarding_secondscreen_middle.png';

  /// 17.5% smaller baseline, then +20% for this screen.
  static const _packScale = 0.825 * 1.20;

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
    // Fan packs: +20% size, spread farther apart.
    const packW = 200.0 * _packScale;
    const packH = 300.0 * _packScale;
    const fanSpread = 104.0;

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
                height: 420,
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
                          child: _PackHover(
                            duration: const Duration(milliseconds: 2780),
                            amplitude: 6,
                            start: 0.12,
                            child: _HeroPackImage(
                              asset: _packLeft,
                              width: packW,
                              height: packH,
                            ),
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
                          child: _PackHover(
                            duration: const Duration(milliseconds: 4050),
                            amplitude: 7,
                            start: 0.71,
                            child: _HeroPackImage(
                              asset: _packRight,
                              width: packW,
                              height: packH,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Center — upright, in front.
                    Transform.translate(
                      offset: Offset(0, 36 * (1 - t)),
                      child: Opacity(
                        opacity: t,
                        child: _PackHover(
                          duration: const Duration(milliseconds: 3360),
                          amplitude: 8,
                          start: 0.41,
                          child: _HeroPackImage(
                            asset: _packCenter,
                            width: packW + 12,
                            height: packH + 18,
                          ),
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
