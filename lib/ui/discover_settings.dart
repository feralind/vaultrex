import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding.dart';
import '../game/game_controller.dart';
import '../models/engagement.dart';
import '../services/bindora_notifications.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/cash_top_up_sheet.dart';
import '../widgets/pixel_cat_buddy.dart';
import 'dev_hub_screen.dart';
import 'discover_feed.dart';
import 'engagement/engagement_hub.dart';
import 'pack_theater_soft_lift_preview.dart';
import 'rentals_screen.dart';
import 'sealed_inventory.dart';
import 'season_quests_screen.dart';
import 'social/account_screen.dart';
import 'social/auction_pit_screen.dart';
import 'social/leaderboard_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  bool _tickerWasOn = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final curve = CurvedAnimation(
      parent: _enter,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curve);
    // No FadeTransition — with HomeShell's TickerMode, a fade frozen at 0
    // paints Discover as a blank black screen over CC.bg.
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curve);
    _enter.value = 1; // first mount if already visible
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = TickerMode.valuesOf(context).enabled;
    if (on && !_tickerWasOn) {
      // Tab became active — rise up from behind.
      _enter.forward(from: 0);
    } else if (!on && _tickerWasOn) {
      // Leaving Discover — snap complete so a paused mid-slide never sticks.
      _enter.value = 1;
    }
    _tickerWasOn = on;
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fid = ref.watch(gameProvider.select((s) => s.franchiseId));
    final lots = ref.watch(gameProvider.select((s) => s.auctions.length));
    final franchise = switch (fid) {
      'pokemon' => 'Pokémon',
      'mtg' => 'Magic',
      'onepiece' => 'One Piece',
      'yugioh' => 'Yu-Gi-Oh!',
      'gundam' => 'Gundam',
      _ => 'Riftbound',
    };

    return SlideTransition(
      position: _slide,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.bottomCenter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
              ListView(
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
                  const DiscoverFeedSections(),
                  _sectionLabel('Today'),
                  const SizedBox(height: 8),
                  const _TodayStrip(),
                  const SizedBox(height: 18),
                  _sectionLabel('Earn'),
                  const SizedBox(height: 8),
                  _DestRow(
                    children: [
                      _DestTile(
                        title: 'Rentals',
                        body: 'Loan slabs · passive candy',
                        color: const Color(0xFF34D399),
                        icon: Icons.handshake_outlined,
                        badge: _rentalBadge(ref),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RentalsScreen(),
                          ),
                        ),
                      ),
                      _DestTile(
                        title: 'Season',
                        body: 'Timed quests & rewards',
                        color: const Color(0xFFFB923C),
                        icon: Icons.flag_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SeasonQuestsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('Compete'),
                  const SizedBox(height: 8),
                  _DestRow(
                    children: [
                      _DestTile(
                        title: 'Auction Pit',
                        body: lots > 0
                            ? '$lots live lots'
                            : 'Restock on Advance Day',
                        color: const Color(0xFFF472B6),
                        icon: Icons.gavel_rounded,
                        pulse: lots > 0,
                        badge: lots > 0 ? '$lots' : null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AuctionPitScreen(),
                          ),
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('Collection HQ'),
                  const SizedBox(height: 8),
                  _DestRow(
                    children: [
                      _DestTile(
                        title: 'Collector Hub',
                        body: 'Daily, upgrades, vault, modes',
                        color: CC.candy,
                        icon: Icons.dashboard_customize_outlined,
                        onTap: () => openEngagementHub(context),
                      ),
                      _DestTile(
                        title: 'Sealed stock',
                        body: 'Open or sell unopened packs',
                        color: const Color(0xFFF59E0B),
                        icon: Icons.inventory_2_outlined,
                        onTap: () => showSealedInventory(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('You'),
                  const SizedBox(height: 8),
                  _DestTile(
                    title: 'Account',
                    body: 'Stats, condition, highlights',
                    color: CC.accent,
                    icon: Icons.person_outline,
                    wide: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AccountScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const WanderingPixelCat(size: 72),
            ],
          ),
        ),
    );
  }

  String? _rentalBadge(WidgetRef ref) {
    final rentals = ref.watch(gameProvider.select((s) => s.activeRentals));
    if (rentals.isEmpty) return null;
    var pending = 0;
    for (final r in rentals.values) {
      pending += r.calculateEarnings();
    }
    if (pending > 0) return '$pending';
    return '${rentals.length}';
  }
}

Widget _sectionLabel(String text) {
  return Text(
    text,
    style: AppText.jakarta(
      fontWeight: FontWeight.w800,
      fontSize: 13,
      letterSpacing: 0.4,
      color: CC.inkMuted,
    ),
  );
}

class _TodayStrip extends ConsumerWidget {
  const _TodayStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eng = ref.watch(gameProvider.select((s) => s.engagement));
    final notifier = ref.read(gameProvider.notifier);
    final claimed = eng.dailyClaimDate == engagementDayKey();
    final streak = eng.dailyStreak;

    return Material(
      color: CC.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openEngagementHub(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CC.line),
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.2,
              colors: [
                CC.candy.withValues(alpha: claimed ? 0.06 : 0.16),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                claimed ? Icons.check_circle_outline : Icons.card_giftcard,
                color: claimed ? CC.scan : CC.candy,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claimed
                          ? 'Daily claimed · streak $streak'
                          : 'Daily reward ready',
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      claimed
                          ? 'Open Collector Hub for goals & upgrades'
                          : 'Tap to claim candy and keep your streak',
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!claimed)
                FilledButton(
                  onPressed: () async {
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
                  style: FilledButton.styleFrom(
                    backgroundColor: CC.candy,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Claim'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestRow extends StatelessWidget {
  const _DestRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ],
      ),
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
    this.badge,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool pulse;
  final bool wide;
  final String? badge;

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
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.wide ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 22),
            const Spacer(),
            if (widget.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  widget.badge!,
                  style: AppText.jakarta(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                  ),
                ),
              ),
          ],
        ),
        if (widget.wide) ...[
          const SizedBox(height: 12),
        ] else
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
    );

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = widget.pulse ? 0.10 + _pulse.value * 0.12 : 0.16;
        final tile = Material(
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

        return widget.wide ? tile : SizedBox.expand(child: tile);
      },
      child: body,
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
        const _NotificationSettingsCard(),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Advance day', style: AppText.jakarta(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '1 day ≈ 2h real time (also auto-ticks when you return).',
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Pack theater preview',
            style: AppText.jakarta(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Live pack peel demo — no pack purchase needed',
            style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
          ),
          trailing: const Icon(Icons.play_circle_outline_rounded),
          onTap: () => openPackTheaterSoftLiftPreview(context),
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

class _NotificationSettingsCard extends StatefulWidget {
  const _NotificationSettingsCard();

  @override
  State<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard> {
  NotificationPrefs? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await BindoraNotifications.instance.loadPrefs();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Notifications',
            style: AppText.jakarta(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Local reminders — daily, PSA, auctions, rentals, comeback.',
            style: AppText.jakarta(
              color: CC.inkMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (_loading || prefs == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Consumer(
              builder: (context, ref, _) {
                Future<void> apply(NotificationPrefs next) async {
                  setState(() => _prefs = next);
                  await BindoraNotifications.instance.savePrefs(next);
                  await BindoraNotifications.instance.requestPermission();
                  await BindoraNotifications.instance
                      .syncFromGame(ref.read(gameProvider));
                }

                return Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Daily reward',
                        style: AppText.jakarta(fontWeight: FontWeight.w700),
                      ),
                      value: prefs.daily,
                      onChanged: (v) => apply(prefs.copyWith(daily: v)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'PSA ready',
                        style: AppText.jakarta(fontWeight: FontWeight.w700),
                      ),
                      value: prefs.psa,
                      onChanged: (v) => apply(prefs.copyWith(psa: v)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Auction Pit',
                        style: AppText.jakarta(fontWeight: FontWeight.w700),
                      ),
                      value: prefs.auction,
                      onChanged: (v) => apply(prefs.copyWith(auction: v)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Rental earnings',
                        style: AppText.jakarta(fontWeight: FontWeight.w700),
                      ),
                      value: prefs.rental,
                      onChanged: (v) => apply(prefs.copyWith(rental: v)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Comeback nudge',
                        style: AppText.jakarta(fontWeight: FontWeight.w700),
                      ),
                      value: prefs.comeback,
                      onChanged: (v) => apply(prefs.copyWith(comeback: v)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
