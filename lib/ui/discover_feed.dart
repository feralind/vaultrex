import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/engagement_defs.dart';
import '../data/featured_packs.dart';
import '../game/game_controller.dart';
import '../game/rival_sim.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/game_widgets.dart';
import 'engagement/engagement_hub.dart';
import 'featured_pack_detail.dart';
import 'social/leaderboard_screen.dart';

/// Feed blocks inserted above Discover destinations.
class DiscoverFeedSections extends ConsumerWidget {
  const DiscoverFeedSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeaturedTeaserSection(),
        SizedBox(height: 16),
        _DailyMissionsSection(),
        SizedBox(height: 16),
        _TrendingSection(),
        SizedBox(height: 16),
        _LeaderboardStripSection(),
        SizedBox(height: 18),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppText.titleSm(),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _FeaturedTeaserSection extends ConsumerWidget {
  const _FeaturedTeaserSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fid = ref.watch(gameProvider.select((s) => s.franchiseId));
    final packs = featuredPacksFor(fid).take(6).toList();
    if (packs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader('Featured packs'),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: packs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final pack = packs[i];
              return _FeaturedPackChip(
                pack: pack,
                onTap: () => showFeaturedPackDetail(context, ref, pack),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedPackChip extends StatelessWidget {
  const _FeaturedPackChip({required this.pack, required this.onTap});

  final FeaturedPackDef pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CC.cardSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 112,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CC.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    pack.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.inventory_2_outlined,
                      color: pack.tier.bloomColors.first,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pack.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(color: CC.ink).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${pack.candyPrice} candy',
                style: AppText.label(color: CC.candy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyMissionsSection extends ConsumerWidget {
  const _DailyMissionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eng = ref.watch(gameProvider.select((s) => s.engagement));
    final today = engagementDayKey();
    final progress = eng.dailyGoalsDate == today
        ? eng.dailyGoalProgress
        : {for (final g in dailyGoalDefs) g.id: 0};
    final claimed = eng.dailyGoalsDate == today
        ? eng.claimedDailyGoals
        : <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          'Daily missions',
          trailing: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DailyHubScreen(),
              ),
            ),
            child: Text(
              'Open',
              style: AppText.jakarta(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: CC.accent,
              ),
            ),
          ),
        ),
        Material(
          color: CC.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DailyHubScreen(),
              ),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CC.line),
              ),
              child: Column(
                children: [
                  for (final g in dailyGoalDefs) ...[
                    if (g != dailyGoalDefs.first) const SizedBox(height: 10),
                    _MissionRow(
                      title: g.title,
                      current: (progress[g.id] ?? 0).clamp(0, g.target),
                      target: g.target,
                      claimed: claimed.contains(g.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.title,
    required this.current,
    required this.target,
    required this.claimed,
  });

  final String title;
  final int current;
  final int target;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final frac = target == 0 ? 0.0 : current / target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppText.body().copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              claimed ? 'Claimed' : '$current/$target',
              style: AppText.label(
                color: claimed ? CC.scan : CC.inkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: CC.cardSoft,
            color: claimed ? CC.scan : CC.candy,
          ),
        ),
      ],
    );
  }
}

class _TrendingSection extends ConsumerWidget {
  const _TrendingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(gameProvider.select((s) => s.ready));
    final events = ref.watch(gameProvider.select((s) => s.events));
    if (!ready) return const SizedBox.shrink();

    final notifier = ref.read(gameProvider.notifier);
    final hotSets = events.map((e) => e.setCode).toSet();
    final cards = List<CardDef>.from(
      notifier.catalog.cards.where(
        (c) => c.marketPrice > 0 && c.displayArtUrl.isNotEmpty,
      ),
    );
    cards.sort((a, b) {
      final aHot = hotSets.contains(a.setCode) ? 1.35 : 1.0;
      final bHot = hotSets.contains(b.setCode) ? 1.35 : 1.0;
      return (b.marketPrice * bHot).compareTo(a.marketPrice * aHot);
    });
    final top = cards.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader('Trending'),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = top[i];
              final hot = hotSets.contains(c.setCode);
              return Container(
                width: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CC.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hot ? CC.scan.withValues(alpha: 0.45) : CC.line,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: PortraitSlotArt(
                          url: c.displayArtUrl,
                          width: 56,
                          height: 78,
                          landscape: c.isLandscapeCard,
                          radius: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '\$${c.marketPrice.toStringAsFixed(c.marketPrice >= 100 ? 0 : 2)}',
                      style: AppText.jakarta(
                        color: hot ? CC.scan : const Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LeaderboardStripSection extends ConsumerWidget {
  const _LeaderboardStripSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(gameProvider.select((s) => s.ready));
    final player = ref.watch(gameProvider.select((s) => s.player));
    if (!ready) return const SizedBox.shrink();

    final notifier = ref.read(gameProvider.notifier);
    final binder = notifier.totalCollectionValue();
    final board = RivalSim.buildBoard(
      playerValue: binder,
      businessLevel: player.businessLevel,
      metric: RivalBoardMetric.binder,
      playerCardsSold: player.cardsSold,
      playerGemsPulled: player.gemsPulled,
    );
    final top3 = board.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          'Leaderboard',
          trailing: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LeaderboardScreen(),
              ),
            ),
            child: Text(
              'Full board',
              style: AppText.jakarta(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: CC.accent,
              ),
            ),
          ),
        ),
        Material(
          color: CC.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LeaderboardScreen(),
              ),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CC.line),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < top3.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _PodiumChip(entry: top3[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PodiumChip extends StatelessWidget {
  const _PodiumChip({required this.entry});

  final RivalBoardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFF94A3B8),
      _ => const Color(0xFFB45309),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: CC.cardSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.isPlayer
              ? CC.accent.withValues(alpha: 0.5)
              : CC.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${entry.rank}',
            style: AppText.jakarta(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: medal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.jakarta(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: entry.isPlayer ? CC.accent : CC.ink,
            ),
          ),
          Text(
            entry.scoreLabel,
            style: AppText.jakarta(
              color: CC.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
