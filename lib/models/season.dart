/// Reward currency for season quest claims.
enum RewardType { candy, xp, cash }

extension RewardTypeX on RewardType {
  String get label => switch (this) {
        RewardType.candy => 'candy',
        RewardType.xp => 'XP',
        RewardType.cash => 'cash',
      };
}

/// One tracked objective inside a [Season].
class SeasonQuest {
  const SeasonQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.trackId,
    required this.target,
    required this.rewardType,
    required this.rewardAmount,
    this.progress = 0,
    this.claimed = false,
  });

  final String id;
  final String title;
  final String description;
  /// Hook key: `rip` | `list` | `grade`.
  final String trackId;
  final int target;
  final int progress;
  final RewardType rewardType;
  final int rewardAmount;
  final bool claimed;

  bool get complete => progress >= target;

  SeasonQuest copyWith({
    String? id,
    String? title,
    String? description,
    String? trackId,
    int? target,
    int? progress,
    RewardType? rewardType,
    int? rewardAmount,
    bool? claimed,
  }) {
    return SeasonQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      trackId: trackId ?? this.trackId,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      rewardType: rewardType ?? this.rewardType,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'trackId': trackId,
        'target': target,
        'progress': progress,
        'rewardType': rewardType.name,
        'rewardAmount': rewardAmount,
        'claimed': claimed,
      };

  factory SeasonQuest.fromJson(Map<String, dynamic> j) => SeasonQuest(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        trackId: j['trackId'] as String? ?? 'rip',
        target: j['target'] as int? ?? 1,
        progress: j['progress'] as int? ?? 0,
        rewardType: RewardType.values.firstWhere(
          (e) => e.name == j['rewardType'],
          orElse: () => RewardType.candy,
        ),
        rewardAmount: j['rewardAmount'] as int? ?? 0,
        claimed: j['claimed'] as bool? ?? false,
      );
}

/// Timed event with a set of quests.
class Season {
  const Season({
    required this.id,
    required this.name,
    required this.startMs,
    required this.endMs,
    required this.quests,
  });

  final String id;
  final String name;
  final int startMs;
  final int endMs;
  final List<SeasonQuest> quests;

  bool isActive([int? nowMs]) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return now >= startMs && now < endMs;
  }

  bool isExpired([int? nowMs]) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return now >= endMs;
  }

  int daysRemaining([int? nowMs]) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (now >= endMs) return 0;
    return ((endMs - now) / Duration.millisecondsPerDay).ceil();
  }

  Season copyWith({
    String? id,
    String? name,
    int? startMs,
    int? endMs,
    List<SeasonQuest>? quests,
  }) {
    return Season(
      id: id ?? this.id,
      name: name ?? this.name,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      quests: quests ?? this.quests,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startMs': startMs,
        'endMs': endMs,
        'quests': quests.map((q) => q.toJson()).toList(),
      };

  factory Season.fromJson(Map<String, dynamic> j) => Season(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Season',
        startMs: j['startMs'] as int? ?? 0,
        endMs: j['endMs'] as int? ?? 0,
        quests: (j['quests'] as List? ?? [])
            .map((e) => SeasonQuest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Default seeded season when save has none — rotates by fortnight.
  factory Season.dragonHunt([DateTime? now]) => Season.forNow(now);

  /// Local liveops: pick a season template from the current 14-day bucket.
  factory Season.forNow([DateTime? now]) {
    final start = now ?? DateTime.now();
    final epoch = DateTime.utc(2024, 1, 1);
    final fortnight = start.toUtc().difference(epoch).inDays ~/ 14;
    switch (fortnight % 3) {
      case 1:
        return Season._binderRush(start);
      case 2:
        return Season._slabSeason(start);
      default:
        return Season._dragonHuntBody(start);
    }
  }

  factory Season._dragonHuntBody(DateTime start) {
    return Season(
      id: 'dragon_hunt_$start',
      name: 'The Dragon Hunt',
      startMs: start.millisecondsSinceEpoch,
      endMs: start.add(const Duration(days: 14)).millisecondsSinceEpoch,
      quests: const [
        SeasonQuest(
          id: 'sq_rip_5',
          title: 'Rip 5 packs',
          description: 'Open five packs during the season.',
          trackId: 'rip',
          target: 5,
          rewardType: RewardType.candy,
          rewardAmount: 800,
        ),
        SeasonQuest(
          id: 'sq_list_3',
          title: 'List 3 cards',
          description: 'Put three cards up for sale online.',
          trackId: 'list',
          target: 3,
          rewardType: RewardType.candy,
          rewardAmount: 500,
        ),
        SeasonQuest(
          id: 'sq_grade_2',
          title: 'Grade 2 cards',
          description: 'Send two cards to PSA grading.',
          trackId: 'grade',
          target: 2,
          rewardType: RewardType.xp,
          rewardAmount: 25,
        ),
        SeasonQuest(
          id: 'sq_rip_12',
          title: 'Case cracker',
          description: 'Rip twelve packs before the season ends.',
          trackId: 'rip',
          target: 12,
          rewardType: RewardType.candy,
          rewardAmount: 1500,
        ),
        SeasonQuest(
          id: 'sq_list_8',
          title: 'Shop floor',
          description: 'List eight cards online this season.',
          trackId: 'list',
          target: 8,
          rewardType: RewardType.cash,
          rewardAmount: 40,
        ),
      ],
    );
  }

  factory Season._binderRush(DateTime start) {
    return Season(
      id: 'binder_rush_$start',
      name: 'Binder Rush',
      startMs: start.millisecondsSinceEpoch,
      endMs: start.add(const Duration(days: 14)).millisecondsSinceEpoch,
      quests: const [
        SeasonQuest(
          id: 'br_rip_8',
          title: 'Fill the pages',
          description: 'Rip eight packs this season.',
          trackId: 'rip',
          target: 8,
          rewardType: RewardType.candy,
          rewardAmount: 1000,
        ),
        SeasonQuest(
          id: 'br_list_5',
          title: 'Move the dupes',
          description: 'List five cards online.',
          trackId: 'list',
          target: 5,
          rewardType: RewardType.candy,
          rewardAmount: 600,
        ),
        SeasonQuest(
          id: 'br_grade_1',
          title: 'First slab of the rush',
          description: 'Send one card to PSA.',
          trackId: 'grade',
          target: 1,
          rewardType: RewardType.xp,
          rewardAmount: 20,
        ),
        SeasonQuest(
          id: 'br_rip_15',
          title: 'Album grind',
          description: 'Rip fifteen packs before the season ends.',
          trackId: 'rip',
          target: 15,
          rewardType: RewardType.candy,
          rewardAmount: 1800,
        ),
      ],
    );
  }

  factory Season._slabSeason(DateTime start) {
    return Season(
      id: 'slab_season_$start',
      name: 'Slab Season',
      startMs: start.millisecondsSinceEpoch,
      endMs: start.add(const Duration(days: 14)).millisecondsSinceEpoch,
      quests: const [
        SeasonQuest(
          id: 'ss_grade_3',
          title: 'Queue three',
          description: 'Send three cards to PSA grading.',
          trackId: 'grade',
          target: 3,
          rewardType: RewardType.candy,
          rewardAmount: 900,
        ),
        SeasonQuest(
          id: 'ss_rip_6',
          title: 'Raw for the slab',
          description: 'Rip six packs for candidates.',
          trackId: 'rip',
          target: 6,
          rewardType: RewardType.candy,
          rewardAmount: 700,
        ),
        SeasonQuest(
          id: 'ss_list_4',
          title: 'Fund the fees',
          description: 'List four cards online.',
          trackId: 'list',
          target: 4,
          rewardType: RewardType.cash,
          rewardAmount: 35,
        ),
        SeasonQuest(
          id: 'ss_grade_5',
          title: 'Grading house',
          description: 'Send five cards to PSA this season.',
          trackId: 'grade',
          target: 5,
          rewardType: RewardType.xp,
          rewardAmount: 40,
        ),
      ],
    );
  }
}
