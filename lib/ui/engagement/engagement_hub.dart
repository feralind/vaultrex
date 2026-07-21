import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/engagement_defs.dart';
import '../../data/featured_packs.dart';
import '../../data/unified_collection.dart';
import '../../game/game_controller.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/bindora_feel.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pack_theater_v2.dart';
import '../../widgets/ui_kit.dart';
import '../rentals_screen.dart';
import '../season_quests_screen.dart';

// ─── Shared tiles ───────────────────────────────────────────────────────────

class MarketEventBanner extends ConsumerWidget {
  const MarketEventBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(gameProvider.select((s) => s.events));
    if (events.isEmpty) return const SizedBox.shrink();
    final e = events.first;
    final hot = e.multiplier >= 1;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (hot ? CC.accent : CC.candy).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hot ? Icons.local_fire_department : Icons.ac_unit,
            color: hot ? CC.accent : CC.candy,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.title} · ${e.multiplier.toStringAsFixed(2)}× · ${e.turnsLeft}d left',
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.description,
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 11,
                    height: 1.3,
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

class OneAwayBanner extends ConsumerWidget {
  const OneAwayBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(gameProvider.select((s) => s.ready));
    if (!ready) return const SizedBox.shrink();
    final away = ref.read(gameProvider.notifier).oneAwaySets();
    if (away.isEmpty) return const SizedBox.shrink();
    final a = away.first;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CC.accent.withValues(alpha: 0.18),
            CC.card,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CC.accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        '1 card from completing ${a.setName}',
        style: AppText.jakarta(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}

class FeaturedPityChip extends ConsumerWidget {
  const FeaturedPityChip({super.key, required this.packId});

  final String packId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dry = ref.watch(
      gameProvider.select((s) => s.engagement.featuredPity[packId] ?? 0),
    );
    final heat = pityHeatPercent(dry);
    if (heat <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CC.candy.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Chase heat $heat%',
        style: AppText.jakarta(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CC.candy,
        ),
      ),
    );
  }
}

class FeaturedDropTimer extends ConsumerStatefulWidget {
  const FeaturedDropTimer({super.key});

  @override
  ConsumerState<FeaturedDropTimer> createState() => _FeaturedDropTimerState();
}

class _FeaturedDropTimerState extends ConsumerState<FeaturedDropTimer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).ensureFeaturedDropClock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final end = ref.watch(
      gameProvider.select((s) => s.engagement.featuredDropEndsAtMs),
    );
    if (end == null) return const SizedBox.shrink();
    final left = Duration(
      milliseconds: (end - DateTime.now().millisecondsSinceEpoch).clamp(0, 1 << 30),
    );
    final h = left.inHours;
    final m = left.inMinutes.remainder(60);
    return Text(
      'Featured restock in ${h}h ${m}m',
      style: AppText.jakarta(color: CC.inkMuted, fontSize: 11),
    );
  }
}

// ─── Discover hub tiles ─────────────────────────────────────────────────────

void openEngagementHub(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const EngagementHubScreen()),
  );
}

class EngagementHubScreen extends ConsumerWidget {
  const EngagementHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameProvider.select((s) => s.player));
    final eng = ref.watch(gameProvider.select((s) => s.engagement));
    final season = ref.watch(gameProvider.select((s) => s.activeSeason));
    final rentalCount =
        ref.watch(gameProvider.select((s) => s.activeRentals.length));
    final title = businessTitleForLevel(player.businessLevel);
    final upgradesOwned = player.ownedUpgrades.length;
    final claimedToday = eng.dailyClaimDate == engagementDayKey();
    final seasonDone =
        season?.quests.where((q) => q.complete).length ?? 0;
    final seasonTotal = season?.quests.length ?? 0;

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: const Text('Collector Hub'),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          AppSpace.s8,
          AppSpace.s16,
          32,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: ScreenTitle(
                  'Collector Hub',
                  subtitle: 'Daily, upgrades, vault, and modes',
                ),
              ),
              BalanceBar(candy: player.candy, cash: player.cash),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          _sectionLabel('Progress'),
          _hubCard(
            context,
            title: '$title · Lv ${player.businessLevel}',
            body:
                '${businessBlurb(player.businessLevel)} · ${eng.binderPagesUnlocked} binder pages · ${player.xp} XP',
            color: CC.accent,
            chip: 'Lv ${player.businessLevel}',
            onTap: () => _push(context, const BusinessProgressScreen()),
          ),
          _hubCard(
            context,
            title: 'Achievements',
            body:
                '${player.unlockedAchievements.length}/${achievementDefs.length} unlocked',
            color: CC.scan,
            chip: '${player.unlockedAchievements.length}',
            onTap: () => _push(context, const AchievementsGalleryScreen()),
          ),
          _sectionLabel('Daily'),
          _hubCard(
            context,
            title: 'Daily claim & goals',
            body: claimedToday
                ? 'Streak day ${eng.dailyStreak} — claimed today'
                : 'Claim free candy · streak day ${eng.dailyStreak}',
            color: CC.candy,
            chip: claimedToday ? 'claimed' : 'ready',
            chipSelected: !claimedToday,
            onTap: () => _push(context, const DailyHubScreen()),
          ),
          _hubCard(
            context,
            title: 'Season Quests',
            body: season == null
                ? 'Timed challenges & rewards'
                : '${season.name} · $seasonDone/$seasonTotal done',
            color: CC.cash,
            chip: season == null ? null : '${season.daysRemaining()}d',
            onTap: () => _push(context, const SeasonQuestsScreen()),
          ),
          _sectionLabel('Collection tools'),
          _hubCard(
            context,
            title: 'Shop upgrades',
            body: '$upgradesOwned owned · fee cut, Quick Flip, Auto-Snipe…',
            color: CC.accentHot,
            chip: '$upgradesOwned',
            onTap: () => _push(context, const UpgradesShopScreen()),
          ),
          _hubCard(
            context,
            title: 'Pull history',
            body: '${eng.pullHistory.length} pulls logged',
            color: CC.cash,
            onTap: () => _push(context, const PullHistoryScreen()),
          ),
          _hubCard(
            context,
            title: 'Vault',
            body: '${eng.vaultInstanceIds.length}/12 display slots',
            color: CC.candy,
            chip: '${eng.vaultInstanceIds.length}/12',
            onTap: () => _push(context, const VaultRoomScreen()),
          ),
          _hubCard(
            context,
            title: 'Rentals',
            body: rentalCount > 0
                ? '$rentalCount cards on loan · passive candy'
                : 'Loan graded slabs for candy',
            color: CC.cash,
            onTap: () => _push(context, const RentalsScreen()),
          ),
          _sectionLabel('Modes'),
          _hubCard(
            context,
            title: 'Modes',
            body: 'Sealed draft · Weekly seed · Survival',
            color: CC.accent,
            onTap: () => _push(context, const ModesHubScreen()),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, AppSpace.s12, 2, AppSpace.s8),
      child: Text(text.toUpperCase(), style: AppText.label()),
    );
  }

  Widget _hubCard(
    BuildContext context, {
    required String title,
    required String body,
    required Color color,
    required VoidCallback onTap,
    String? chip,
    bool chipSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: Material(
        color: CC.card,
        borderRadius: BorderRadius.circular(AppSpace.rCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpace.rCard),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpace.rCard),
              border: Border.all(color: CC.line),
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [color.withValues(alpha: 0.16), Colors.transparent],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.titleSm()),
                      const SizedBox(height: AppSpace.s4),
                      Text(body, style: AppText.bodySm()),
                    ],
                  ),
                ),
                if (chip != null) ...[
                  const SizedBox(width: AppSpace.s8),
                  AppChip(
                    label: chip,
                    compact: true,
                    selected: chipSelected,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Screens ────────────────────────────────────────────────────────────────

class DailyHubScreen extends ConsumerWidget {
  const DailyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eng = ref.watch(gameProvider.select((s) => s.engagement));
    final player = ref.watch(gameProvider.select((s) => s.player));
    final notifier = ref.read(gameProvider.notifier);
    final claimed = eng.dailyClaimDate == engagementDayKey();
    final progress = eng.dailyGoalsDate == engagementDayKey()
        ? eng.dailyGoalProgress
        : {for (final g in dailyGoalDefs) g.id: 0};
    final yesterday = engagementDayKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final previewStreak = claimed
        ? eng.dailyStreak
        : (eng.dailyClaimDate == yesterday ? eng.dailyStreak + 1 : 1);
    final candyPreview = dailyClaimCandyForStreak(previewStreak);
    final goalsDone = dailyGoalDefs.where((g) {
      final p = progress[g.id] ?? 0;
      return p >= g.target;
    }).length;

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: const Text('Daily'),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          AppSpace.s8,
          AppSpace.s16,
          32,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ScreenTitle(
                  'Daily',
                  subtitle: claimed
                      ? 'Streak day ${eng.dailyStreak} · come back tomorrow'
                      : 'Claim free candy · keep the streak alive',
                ),
              ),
              BalanceBar(candy: player.candy, cash: player.cash),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(AppSpace.rCard),
              border: Border.all(
                color: claimed
                    ? CC.line
                    : CC.candy.withValues(alpha: 0.45),
              ),
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  CC.candy.withValues(alpha: claimed ? 0.06 : 0.18),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Daily login', style: AppText.titleSm()),
                    ),
                    AppChip(
                      label: 'Day ${claimed ? eng.dailyStreak : previewStreak}',
                      selected: !claimed,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  claimed
                      ? 'Already claimed today. Streak holds at ${eng.dailyStreak}.'
                      : '+$candyPreview candy waiting · claim today to continue your streak.',
                  style: AppText.bodySm(),
                ),
                const SizedBox(height: AppSpace.s16),
                FilledButton(
                  onPressed: claimed
                      ? null
                      : () async {
                          await BindoraHaptics.claim();
                          await notifier.claimDailyLogin();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: CC.accent,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpace.s16,
                      horizontal: AppSpace.s24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpace.rCard),
                    ),
                  ),
                  child: Text(
                    claimed
                        ? 'Claimed · streak ${eng.dailyStreak}'
                        : 'Claim +$candyPreview candy',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s24),
          Text('Goals', style: AppText.titleSm()),
          const SizedBox(height: AppSpace.s4),
          Text(
            '$goalsDone / ${dailyGoalDefs.length} complete',
            style: AppText.bodySm(),
          ),
          const SizedBox(height: AppSpace.s12),
          ...dailyGoalDefs.map((g) {
            final p = progress[g.id] ?? 0;
            final done = p >= g.target;
            final taken = eng.claimedDailyGoals.contains(g.id);
            final frac =
                g.target == 0 ? 0.0 : (p / g.target).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s12),
              child: Container(
                padding: const EdgeInsets.all(AppSpace.s16),
                decoration: BoxDecoration(
                  color: CC.card,
                  borderRadius: BorderRadius.circular(AppSpace.rCard),
                  border: Border.all(
                    color: done && !taken
                        ? CC.scan.withValues(alpha: 0.45)
                        : CC.line,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(g.title, style: AppText.titleSm()),
                        ),
                        AppChip(
                          label: '$p / ${g.target}',
                          compact: true,
                          selected: done && !taken,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 6,
                        backgroundColor: CC.cardSoft,
                        color: taken
                            ? CC.inkMuted
                            : done
                                ? CC.scan
                                : CC.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s12),
                    Row(
                      children: [
                        Text(
                          '+${g.candyReward} candy',
                          style: AppText.label(color: CC.candy),
                        ),
                        const SizedBox(width: AppSpace.s8),
                        Text(
                          '+${g.xpReward} XP',
                          style: AppText.label(),
                        ),
                        const Spacer(),
                        if (taken)
                          const AppChip(
                            label: 'Claimed',
                            compact: true,
                          )
                        else if (done)
                          AppChip(
                            label: 'Claim',
                            selected: true,
                            compact: true,
                            onTap: () => notifier.claimDailyGoal(g.id),
                          )
                        else
                          Text('In progress', style: AppText.label()),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AchievementsGalleryScreen extends ConsumerWidget {
  const AchievementsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked =
        ref.watch(gameProvider.select((s) => s.player.unlockedAchievements));
    final unlockedCount = unlocked.length;
    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: CC.bg,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          AppSpace.s8,
          AppSpace.s16,
          32,
        ),
        itemCount: achievementDefs.length + 1,
        separatorBuilder: (_, i) =>
            SizedBox(height: i == 0 ? AppSpace.s16 : AppSpace.s12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return ScreenTitle(
              'Achievements',
              subtitle:
                  '$unlockedCount / ${achievementDefs.length} unlocked',
            );
          }
          final a = achievementDefs[i - 1];
          final on = unlocked.contains(a.id);
          return Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(AppSpace.rCard),
              border: Border.all(
                color: on ? CC.accent.withValues(alpha: 0.5) : CC.line,
              ),
              gradient: on
                  ? RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.2,
                      colors: [
                        CC.accent.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CC.cardSoft,
                    borderRadius: BorderRadius.circular(AppSpace.rChip),
                    border: Border.all(color: CC.line),
                  ),
                  child: Icon(
                    on ? Icons.emoji_events : Icons.lock_outline,
                    color: on ? CC.accent : CC.inkMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: AppText.titleSm(
                          color: on ? CC.ink : CC.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(a.description, style: AppText.bodySm()),
                    ],
                  ),
                ),
                if (on)
                  const AppChip(label: 'Done', compact: true, selected: true),
              ],
            ),
          );
        },
      ),
    );
  }
}

class UpgradesShopScreen extends ConsumerWidget {
  const UpgradesShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameProvider.select((s) => s.player));
    final notifier = ref.read(gameProvider.notifier);
    final ownedCount = player.ownedUpgrades.length;
    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: const Text('Upgrades'),
        backgroundColor: CC.bg,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          AppSpace.s8,
          AppSpace.s16,
          32,
        ),
        itemCount: upgrades.length + 1,
        separatorBuilder: (_, i) =>
            SizedBox(height: i == 0 ? AppSpace.s16 : AppSpace.s12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ScreenTitle(
                    'Upgrades',
                    subtitle:
                        '$ownedCount owned · fee cut, Quick Flip, Auto-Snipe…',
                  ),
                ),
                BalanceBar(candy: player.candy, cash: player.cash),
              ],
            );
          }
          final u = upgrades[i - 1];
          final owned = player.ownedUpgrades.contains(u.id);
          final can = !owned &&
              player.xp >= u.requiredXp &&
              player.cash >= u.cost;
          return Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(AppSpace.rCard),
              border: Border.all(
                color: owned
                    ? CC.accent.withValues(alpha: 0.4)
                    : CC.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(u.name, style: AppText.titleSm()),
                    ),
                    if (owned)
                      const AppChip(
                        label: 'Owned',
                        compact: true,
                        selected: true,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.s4),
                Text(u.description, style: AppText.bodySm()),
                const SizedBox(height: AppSpace.s12),
                Row(
                  children: [
                    Text(
                      '\$${u.cost}',
                      style: AppText.tabular(color: CC.cash, fontSize: 13),
                    ),
                    const SizedBox(width: AppSpace.s8),
                    Text(
                      '${u.requiredXp} XP',
                      style: AppText.label(),
                    ),
                    const Spacer(),
                    if (!owned)
                      FilledButton(
                        onPressed:
                            can ? () => notifier.buyUpgrade(u.id) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: CC.accent,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s16,
                            vertical: AppSpace.s8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpace.rCard),
                          ),
                        ),
                        child: const Text('Buy'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AuctionsScreen extends ConsumerWidget {
  const AuctionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctions = ref.watch(gameProvider.select((s) => s.auctions));
    final notifier = ref.read(gameProvider.notifier);
    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text('Auctions', style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: auctions.isEmpty
          ? Center(child: Text('No lots — Advance Day to restock.', style: AppText.jakarta(color: CC.inkMuted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: auctions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = auctions[i];
                final def = notifier.cardById(a.cardId);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CC.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CC.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def?.name ?? a.cardId,
                        style: AppText.jakarta(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bid \$${a.currentBid.toStringAsFixed(2)} · +${a.minIncrement.toStringAsFixed(2)} · ${a.endsInTurns}d'
                        '${a.rivalName != null ? ' · vs ${a.rivalName}' : ''}'
                        '${a.playerIsHighBidder ? ' · YOU lead' : ''}',
                        style: AppText.jakarta(fontSize: 12, color: CC.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => notifier.bidAuction(a.id),
                          child: const Text('Bid'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class PullHistoryScreen extends ConsumerWidget {
  const PullHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(gameProvider.select((s) => s.engagement.pullHistory));
    final notifier = ref.read(gameProvider.notifier);
    final fmt = DateFormat('MMM d · HH:mm');
    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text('Pull history', style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: history.isEmpty
          ? Center(child: Text('Rip a pack to start the reel.', style: AppText.jakarta(color: CC.inkMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final e = history[i];
                final def = notifier.cardById(e.cardId);
                final url = def?.imageUrlSmall ?? def?.imageUrl ?? '';
                return ListTile(
                  leading: url.isEmpty
                      ? const Icon(Icons.style)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 40,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                  title: Text(
                    def?.name ?? e.cardId,
                    style: AppText.jakarta(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: Text(
                    [
                      if (e.packLabel != null) e.packLabel!,
                      if (e.foil) 'Foil',
                      if (e.fairValue != null)
                        '\$${e.fairValue!.toStringAsFixed(2)}',
                      fmt.format(DateTime.fromMillisecondsSinceEpoch(e.atMs)),
                    ].join(' · '),
                    style: AppText.jakarta(fontSize: 11, color: CC.inkMuted),
                  ),
                );
              },
            ),
    );
  }
}

class VaultRoomScreen extends ConsumerWidget {
  const VaultRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(gameProvider.select((s) => s.engagement.vaultInstanceIds));
    final collection = ref.watch(gameProvider.select((s) => s.collection));
    final notifier = ref.read(gameProvider.notifier);
    final byId = {for (final c in collection) c.instanceId: c};

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text('Vault', style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 12,
        itemBuilder: (context, i) {
          final id = i < ids.length ? ids[i] : null;
          final owned = id == null ? null : byId[id];
          final def = owned == null ? null : notifier.cardById(owned.cardId);
          return Container(
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CC.line),
            ),
            child: owned == null || def == null
                ? Center(
                    child: Text(
                      'Empty',
                      style: AppText.jakarta(color: CC.inkMuted, fontSize: 11),
                    ),
                  )
                : GestureDetector(
                    onLongPress: () => notifier.removeFromVault(owned.instanceId),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          Expanded(
                            child: GyroFoilCard(
                              imageUrl: def.imageUrl,
                              foil: owned.foil,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            def.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.jakarta(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickForVault(context, ref),
        label: const Text('Add grail'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _pickForVault(BuildContext context, WidgetRef ref) async {
    final state = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final candidates = [...state.collection]
      ..sort((a, b) => notifier.fairFor(b).compareTo(notifier.fairFor(a)));
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: CC.card,
      builder: (ctx) => ListView(
        children: candidates.take(30).map((o) {
          final def = notifier.cardById(o.cardId);
          return ListTile(
            title: Text(def?.name ?? o.cardId),
            subtitle: Text('\$${notifier.fairFor(o).toStringAsFixed(2)}'),
            onTap: () async {
              await notifier.addToVault(o.instanceId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

class BusinessProgressScreen extends ConsumerWidget {
  const BusinessProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameProvider.select((s) => s.player));
    final pages = ref.watch(gameProvider.select((s) => s.engagement.binderPagesUnlocked));
    final notifier = ref.read(gameProvider.notifier);
    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text('Business', style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            businessTitleForLevel(player.businessLevel),
            style: AppText.jakarta(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            'Level ${player.businessLevel} · ${player.xp} XP · $pages binder pages',
            style: AppText.jakarta(color: CC.inkMuted),
          ),
          const SizedBox(height: 16),
          ...businessTitles.map(
            (t) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                player.businessLevel >= t.minLevel
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: player.businessLevel >= t.minLevel ? CC.accent : CC.inkMuted,
              ),
              title: Text('${t.title} (Lv ${t.minLevel})'),
              subtitle: Text(t.blurb),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => notifier.buyBinderPage(),
            child: const Text('Buy binder page (1500 candy)'),
          ),
        ],
      ),
    );
  }
}

class GhostLeaderboardScreen extends ConsumerWidget {
  const GhostLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final value = notifier.totalCollectionValue();
    final board = buildGhostLeaderboard(
      playerValue: value,
      playerName: 'You',
    );
    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text('Weekly board', style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Flavor ranks only — generated personas, not real players.',
              style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: board.length,
              itemBuilder: (context, i) {
                final e = board[i];
                return ListTile(
                  leading: Text('#${i + 1}', style: AppText.jakarta(fontWeight: FontWeight.w800)),
                  title: Text(
                    e.name,
                    style: AppText.jakarta(
                      fontWeight: e.isPlayer ? FontWeight.w800 : FontWeight.w600,
                      color: e.isPlayer ? CC.accent : CC.ink,
                    ),
                  ),
                  trailing: Text('\$${e.value.toStringAsFixed(0)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ModesHubScreen extends ConsumerWidget {
  const ModesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = ref.watch(gameProvider.select((s) => s.engagement.survivalBestRound));
    final notifier = ref.read(gameProvider.notifier);
    final sets = notifier.catalog.bySet.keys.toList()..sort();

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text('Modes', style: AppText.jakarta(fontWeight: FontWeight.w800)),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Sealed draft', style: AppText.jakarta(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('2400 candy · 3 packs from one set', style: AppText.jakarta(color: CC.inkMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sets.take(12).map((code) {
              return ActionChip(
                label: Text(code),
                onPressed: () async {
                  final pulls = await notifier.runSealedDraft(setCode: code);
                  if (pulls != null && context.mounted) {
                    await showPackTheaterV2(context, ref, alreadyOpened: true);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final pulls = await notifier.runWeeklyChallenge();
              if (pulls != null && context.mounted) {
                await showPackTheaterV2(context, ref, alreadyOpened: true);
              }
            },
            child: const Text('Weekly seeded challenge (900 candy)'),
          ),
          const SizedBox(height: 16),
          Text('Survival best: round $best', style: AppText.jakarta(color: CC.inkMuted)),
          FilledButton.tonal(
            onPressed: () async {
              var round = 1;
              while (await notifier.survivalRound(round: round)) {
                round++;
                if (round > 40) break;
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Survival ended at round ${round - 1}')),
                );
              }
            },
            child: const Text('Run survival session'),
          ),
        ],
      ),
    );
  }
}

class SetCompletionGridScreen extends ConsumerWidget {
  const SetCompletionGridScreen({
    super.key,
    required this.setCode,
    this.franchiseId,
    this.cards,
    this.ownedUnique,
  });

  final String setCode;
  final String? franchiseId;
  final List<CardDef>? cards;
  final int? ownedUnique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final async = ref.watch(unifiedCollectionProvider);

    List<CardDef> all;
    Set<String> ownedIds;

    if (cards != null) {
      all = cards!;
      ownedIds = async.maybeWhen(
        data: (snap) {
          final entries = snap.cards.where(
            (e) =>
                e.def.setCode == setCode &&
                (franchiseId == null || e.franchiseId == franchiseId),
          );
          return entries.map((e) => e.owned.cardId).toSet();
        },
        orElse: () => <String>{},
      );
    } else {
      all = notifier.catalog.bySet[setCode] ?? [];
      final collection = ref.watch(gameProvider.select((s) => s.collection));
      ownedIds = collection
          .where((c) => notifier.cardById(c.cardId)?.setCode == setCode)
          .map((c) => c.cardId)
          .toSet();
    }

    final title = all.isEmpty
        ? setCode
        : franchiseId != null
            ? '${all.first.setName} · ${franchiseLabel(franchiseId!)}'
            : all.first.setName;

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text(
          title,
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        backgroundColor: CC.bg,
      ),
      body: Column(
        children: [
          if (ownedUnique != null || all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${ownedIds.length} / ${all.length} collected',
                style: AppText.jakarta(color: CC.inkMuted, fontSize: 13),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: all.length,
              itemBuilder: (context, i) {
                final def = all[i];
                final have = ownedIds.contains(def.id);
                return Container(
                  decoration: BoxDecoration(
                    color: CC.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: have ? CC.accent.withValues(alpha: 0.4) : CC.line,
                    ),
                  ),
                  child: have
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: def.imageUrlSmall.isNotEmpty
                                ? def.imageUrlSmall
                                : def.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            def.number ?? '?',
                            style: AppText.jakarta(
                              color: CC.inkMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pointer-tilt foil (gyro stub without sensors dependency).
class GyroFoilCard extends StatefulWidget {
  const GyroFoilCard({super.key, required this.imageUrl, this.foil = false});

  final String imageUrl;
  final bool foil;

  @override
  State<GyroFoilCard> createState() => _GyroFoilCardState();
}

class _GyroFoilCardState extends State<GyroFoilCard> {
  double _dx = 0;
  double _dy = 0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(e.position);
        final nx = (local.dx / box.size.width - 0.5).clamp(-0.5, 0.5);
        final ny = (local.dy / box.size.height - 0.5).clamp(-0.5, 0.5);
        setState(() {
          _dx = nx * 2;
          _dy = ny * 2;
        });
      },
      onPointerUp: (_) => setState(() {
        _dx = 0;
        _dy = 0;
      }),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(_dx * 0.35)
          ..rotateX(-_dy * 0.35),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.imageUrl.isNotEmpty)
              CachedNetworkImage(imageUrl: widget.imageUrl, fit: BoxFit.cover)
            else
              const ColoredBox(color: Color(0xFF1A1D24)),
            if (widget.foil)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + _dx, -1 + _dy),
                      end: Alignment(1 + _dx, 1 + _dy),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.28),
                        Colors.cyanAccent.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Post-rip “Open another” sheet.
Future<void> showOpenAnotherSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final state = ref.read(gameProvider);
  final notifier = ref.read(gameProvider.notifier);
  final hasInv = state.unopened.isNotEmpty;
  final candy = state.player.candy;
  final cash = state.player.cash;
  final packs = featuredPacksFor(state.franchiseId);
  FeaturedPackDef? cheap;
  for (final p in packs) {
    if (cheap == null || p.candyPrice < cheap.candyPrice) cheap = p;
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: CC.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Open another?',
                style: AppText.jakarta(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Keep the streak going.',
                style: AppText.jakarta(color: CC.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (hasInv)
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    await showPackTheaterV2(context, ref);
                  },
                  child: Text('Open inventory pack (${state.unopened.length} left)'),
                ),
              if (cheap != null) ...[
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: (candy >= cheap.candyPrice || cash >= cheap.priceUsd)
                      ? () async {
                          Navigator.pop(ctx);
                          final pay = candy >= cheap!.candyPrice
                              ? PaymentMethod.candy
                              : PaymentMethod.cash;
                          final ok = await notifier.buyFeaturedPack(
                            cheap.id,
                            payWith: pay,
                          );
                          if (ok && context.mounted) {
                            await showPackTheaterV2(
                              context,
                              ref,
                              alreadyOpened: true,
                              packImageUrl: cheap.assetPath,
                            );
                          }
                        }
                      : null,
                  child: Text(
                    'Buy ${cheap.name} · ${cheap.candyPrice} candy / \$${cheap.priceUsd.toStringAsFixed(2)}',
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done for now'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
