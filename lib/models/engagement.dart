import 'dart:math' as math;

import '../data/engagement_defs.dart';

class PullHistoryEntry {
  const PullHistoryEntry({
    required this.cardId,
    required this.foil,
    required this.atMs,
    this.packLabel,
    this.fairValue,
  });

  final String cardId;
  final bool foil;
  final int atMs;
  final String? packLabel;
  final double? fairValue;

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'foil': foil,
        'atMs': atMs,
        'packLabel': packLabel,
        'fairValue': fairValue,
      };

  factory PullHistoryEntry.fromJson(Map<String, dynamic> j) => PullHistoryEntry(
        cardId: j['cardId'] as String,
        foil: j['foil'] as bool? ?? false,
        atMs: j['atMs'] as int? ?? 0,
        packLabel: j['packLabel'] as String?,
        fairValue: (j['fairValue'] as num?)?.toDouble(),
      );
}

/// Persisted engagement progress (daily, pity, vault, milestones).
class EngagementState {
  const EngagementState({
    this.pullHistory = const [],
    this.vaultInstanceIds = const [],
    this.dailyClaimDate,
    this.dailyStreak = 0,
    this.dailyGoalsDate,
    this.dailyGoalProgress = const {},
    this.claimedDailyGoals = const {},
    this.featuredPity = const {},
    this.setMilestonesClaimed = const {},
    this.binderPagesUnlocked = 2,
    this.survivalBestRound = 0,
    this.gradedRevealedCount = 0,
    this.pendingAchievementIds = const [],
    this.pendingResumeMessage,
    this.featuredDropEndsAtMs,
    this.lastRivalBoardSize = 0,
    this.rivalMoodSeed = 0,
  });

  final List<PullHistoryEntry> pullHistory;
  final List<String> vaultInstanceIds;
  final String? dailyClaimDate; // yyyy-MM-dd
  final int dailyStreak;
  final String? dailyGoalsDate;
  final Map<String, int> dailyGoalProgress;
  final Set<String> claimedDailyGoals;
  final Map<String, int> featuredPity;
  final Set<String> setMilestonesClaimed;
  final int binderPagesUnlocked;
  final int survivalBestRound;
  final int gradedRevealedCount;
  /// Session-only unlock toasts (not persisted).
  final List<String> pendingAchievementIds;
  /// Session-only resume celebration.
  final String? pendingResumeMessage;
  /// Wall-clock end for timed featured restock (persisted).
  final int? featuredDropEndsAtMs;
  /// Last unlocked rival board size (pit / leaderboard feel).
  final int lastRivalBoardSize;
  /// Day-seeded mood salt so pit feed feels alive across sessions.
  final int rivalMoodSeed;

  EngagementState copyWith({
    List<PullHistoryEntry>? pullHistory,
    List<String>? vaultInstanceIds,
    String? dailyClaimDate,
    int? dailyStreak,
    String? dailyGoalsDate,
    Map<String, int>? dailyGoalProgress,
    Set<String>? claimedDailyGoals,
    Map<String, int>? featuredPity,
    Set<String>? setMilestonesClaimed,
    int? binderPagesUnlocked,
    int? survivalBestRound,
    int? gradedRevealedCount,
    List<String>? pendingAchievementIds,
    String? pendingResumeMessage,
    bool clearResume = false,
    int? featuredDropEndsAtMs,
    int? lastRivalBoardSize,
    int? rivalMoodSeed,
  }) {
    return EngagementState(
      pullHistory: pullHistory ?? this.pullHistory,
      vaultInstanceIds: vaultInstanceIds ?? this.vaultInstanceIds,
      dailyClaimDate: dailyClaimDate ?? this.dailyClaimDate,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      dailyGoalsDate: dailyGoalsDate ?? this.dailyGoalsDate,
      dailyGoalProgress: dailyGoalProgress ?? this.dailyGoalProgress,
      claimedDailyGoals: claimedDailyGoals ?? this.claimedDailyGoals,
      featuredPity: featuredPity ?? this.featuredPity,
      setMilestonesClaimed: setMilestonesClaimed ?? this.setMilestonesClaimed,
      binderPagesUnlocked: binderPagesUnlocked ?? this.binderPagesUnlocked,
      survivalBestRound: survivalBestRound ?? this.survivalBestRound,
      gradedRevealedCount: gradedRevealedCount ?? this.gradedRevealedCount,
      pendingAchievementIds:
          pendingAchievementIds ?? this.pendingAchievementIds,
      pendingResumeMessage: clearResume
          ? null
          : (pendingResumeMessage ?? this.pendingResumeMessage),
      featuredDropEndsAtMs: featuredDropEndsAtMs ?? this.featuredDropEndsAtMs,
      lastRivalBoardSize: lastRivalBoardSize ?? this.lastRivalBoardSize,
      rivalMoodSeed: rivalMoodSeed ?? this.rivalMoodSeed,
    );
  }

  Map<String, dynamic> toJson() => {
        'pullHistory': pullHistory.map((e) => e.toJson()).toList(),
        'vaultInstanceIds': vaultInstanceIds,
        'dailyClaimDate': dailyClaimDate,
        'dailyStreak': dailyStreak,
        'dailyGoalsDate': dailyGoalsDate,
        'dailyGoalProgress': dailyGoalProgress,
        'claimedDailyGoals': claimedDailyGoals.toList(),
        'featuredPity': featuredPity,
        'setMilestonesClaimed': setMilestonesClaimed.toList(),
        'binderPagesUnlocked': binderPagesUnlocked,
        'survivalBestRound': survivalBestRound,
        'gradedRevealedCount': gradedRevealedCount,
        'featuredDropEndsAtMs': featuredDropEndsAtMs,
        'lastRivalBoardSize': lastRivalBoardSize,
        'rivalMoodSeed': rivalMoodSeed,
      };

  factory EngagementState.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const EngagementState();
    final progressRaw = j['dailyGoalProgress'];
    final pityRaw = j['featuredPity'];
    return EngagementState(
      pullHistory: (j['pullHistory'] as List? ?? [])
          .map((e) => PullHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      vaultInstanceIds:
          (j['vaultInstanceIds'] as List? ?? []).cast<String>(),
      dailyClaimDate: j['dailyClaimDate'] as String?,
      dailyStreak: j['dailyStreak'] as int? ?? 0,
      dailyGoalsDate: j['dailyGoalsDate'] as String?,
      dailyGoalProgress: progressRaw is Map
          ? progressRaw.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            )
          : const {},
      claimedDailyGoals: {
        ...(j['claimedDailyGoals'] as List? ?? []).cast<String>(),
      },
      featuredPity: pityRaw is Map
          ? pityRaw.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            )
          : const {},
      setMilestonesClaimed: {
        ...(j['setMilestonesClaimed'] as List? ?? []).cast<String>(),
      },
      binderPagesUnlocked: j['binderPagesUnlocked'] as int? ?? 2,
      survivalBestRound: j['survivalBestRound'] as int? ?? 0,
      gradedRevealedCount: j['gradedRevealedCount'] as int? ?? 0,
      featuredDropEndsAtMs: j['featuredDropEndsAtMs'] as int?,
      lastRivalBoardSize: j['lastRivalBoardSize'] as int? ?? 0,
      rivalMoodSeed: j['rivalMoodSeed'] as int? ?? 0,
    );
  }
}

/// Calendar day key in local time.
String engagementDayKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

int dailyClaimCandyForStreak(int streak) {
  final s = streak.clamp(1, 7);
  return 200 + s * 75;
}

/// Chase heat 0–100 from consecutive dry featured rips.
int pityHeatPercent(int dryCount) =>
    (dryCount * 12).clamp(0, 100);

double pityWeightBoost(int dryCount) {
  if (dryCount <= 0) return 1.0;
  return 1.0 + math.min(0.85, dryCount * 0.08);
}

class GhostRankEntry {
  const GhostRankEntry({
    required this.name,
    required this.value,
    required this.isPlayer,
  });

  final String name;
  final double value;
  final bool isPlayer;
}

/// Flavor-only weekly board seeded by week number + player value.
List<GhostRankEntry> buildGhostLeaderboard({
  required double playerValue,
  required String playerName,
  int? weekSeed,
}) {
  final now = DateTime.now();
  final seed = weekSeed ?? (now.year * 100 + (now.difference(DateTime(now.year)).inDays ~/ 7));
  final rng = math.Random(seed);
  final entries = <GhostRankEntry>[];
  for (var i = 0; i < ghostCollectorNames.length; i++) {
    final base = playerValue * (0.55 + rng.nextDouble() * 0.9);
    final jitter = (rng.nextDouble() - 0.5) * playerValue * 0.15;
    entries.add(
      GhostRankEntry(
        name: ghostCollectorNames[i],
        value: math.max(50, base + jitter),
        isPlayer: false,
      ),
    );
  }
  entries.add(
    GhostRankEntry(name: playerName, value: playerValue, isPlayer: true),
  );
  entries.sort((a, b) => b.value.compareTo(a.value));
  return entries;
}
