import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding.dart';
import '../game/game_controller.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/cash_top_up_sheet.dart';
import 'dev_hub_screen.dart';
import 'engagement/engagement_hub.dart';
import 'sealed_inventory.dart';
import 'social/account_screen.dart';
import 'social/auction_pit_screen.dart';
import 'social/leaderboard_screen.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fid = ref.watch(gameProvider.select((s) => s.franchiseId));
    final lots = ref.watch(gameProvider.select((s) => s.auctions.length));
    final franchise = switch (fid) {
      'pokemon' => 'Pokémon',
      'mtg' => 'Magic',
      _ => 'Riftbound',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'Discover',
          style: AppText.jakarta(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$franchise · live room, rivals, and your shop.',
          style: AppText.jakarta(color: CC.inkMuted),
        ),
        const SizedBox(height: 14),
        const MarketEventBanner(),
        const OneAwayBanner(),
        const SizedBox(height: 6),
        Text(
          'Destinations',
          style: AppText.jakarta(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            _DestTile(
              title: 'Account',
              body: 'Stats, condition, highlights',
              color: CC.accent,
              icon: Icons.person_outline,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              ),
            ),
            _DestTile(
              title: 'Leaderboard',
              body: 'Rivals scale as you level',
              color: const Color(0xFFF59E0B),
              icon: Icons.emoji_events_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LeaderboardScreen(),
                ),
              ),
            ),
            _DestTile(
              title: 'Auction Pit',
              body: lots > 0 ? '$lots live lots' : 'Restock on Advance Day',
              color: const Color(0xFFF472B6),
              icon: Icons.gavel_rounded,
              pulse: lots > 0,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AuctionPitScreen(),
                ),
              ),
            ),
            _DestTile(
              title: 'Collector Hub',
              body: 'Daily, upgrades, vault, modes',
              color: CC.candy,
              icon: Icons.dashboard_customize_outlined,
              onTap: () => openEngagementHub(context),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DestTile(
          title: 'Sealed inventory',
          body: 'Boxes land sealed — open or sell when you want.',
          color: const Color(0xFFF59E0B),
          icon: Icons.inventory_2_outlined,
          wide: true,
          onTap: () => showSealedInventory(context),
        ),
      ],
    );
  }
}

class _DestTile extends StatefulWidget {
  const _DestTile({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
    required this.onTap,
    this.pulse = false,
    this.wide = false,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool pulse;
  final bool wide;

  @override
  State<_DestTile> createState() => _DestTileState();
}

class _DestTileState extends State<_DestTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _DestTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.pulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = widget.pulse ? 0.10 + _pulse.value * 0.12 : 0.16;
        return Material(
          color: CC.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: widget.wide ? double.infinity : null,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CC.line),
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.15,
                  colors: [
                    widget.color.withValues(alpha: glow),
                    Colors.transparent,
                  ],
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, color: widget.color, size: 22),
          const Spacer(),
          Text(
            widget.title,
            style: AppText.jakarta(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            widget.body,
            style: AppText.jakarta(
              color: CC.inkMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cash = ref.watch(gameProvider.select((s) => s.player.cash));
    final candy = ref.watch(gameProvider.select((s) => s.player.candy));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: AppText.jakarta(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CC.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Wallet',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Top up simulated cash anytime. Large amounts are… encouraged. 😉',
                style: AppText.jakarta(
                  color: CC.inkMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '\$${cash.toStringAsFixed(2)}',
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ),
                  Text(
                    '$candy candy',
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w700,
                      color: CC.candy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => showCashTopUp(context, ref),
                child: const Text('Top up cash'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Advance day', style: AppText.jakarta(fontWeight: FontWeight.w700)),
          subtitle: Text(
            'Tick markets, auctions, and events.',
            style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
          ),
          trailing: const Icon(Icons.skip_next_rounded),
          onTap: () => ref.read(gameProvider.notifier).advanceDay(),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Replay intro', style: AppText.jakarta(fontWeight: FontWeight.w700)),
          onTap: () async {
            await OnboardingStore.reset();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restart the app to replay onboarding.')),
            );
          },
        ),
        if (kDebugMode)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Dev Hub', style: AppText.jakarta(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DevHubScreen()),
            ),
          ),
      ],
    );
  }
}
