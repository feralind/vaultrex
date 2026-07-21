import 'dart:math' as math;

import '../data/riftbound_catalog.dart';
import '../data/rival_personas.dart';
import '../models/enums.dart';
import '../models/models.dart';
import 'game_clock.dart';

/// Competitive daily boards — what you're actually racing on.
enum RivalBoardMetric {
  binder,
  flips,
  greens,
}

extension RivalBoardMetricX on RivalBoardMetric {
  String get label => switch (this) {
        RivalBoardMetric.binder => 'Binder value',
        RivalBoardMetric.flips => 'Cash flipped',
        RivalBoardMetric.greens => 'Green hits',
      };

  String get blurb => switch (this) {
        RivalBoardMetric.binder =>
          'Who stacked the fattest portfolio today.',
        RivalBoardMetric.flips =>
          'Estimated cash from cards sold — flip energy.',
        RivalBoardMetric.greens =>
          'Chase / gem pulls logged. Green means you hit.',
      };

  String get unitHint => switch (this) {
        RivalBoardMetric.binder => 'portfolio \$',
        RivalBoardMetric.flips => 'sold \$',
        RivalBoardMetric.greens => 'hits',
      };
}

class RivalBoardEntry {
  const RivalBoardEntry({
    required this.persona,
    required this.score,
    required this.status,
    required this.isPlayer,
    required this.metric,
    this.rank = 0,
  });

  final RivalPersona? persona;
  /// Primary ranking number (\$ or hit count depending on [metric]).
  final double score;
  final RivalStatus status;
  final bool isPlayer;
  final RivalBoardMetric metric;
  final int rank;

  String get displayName =>
      isPlayer ? 'You' : (persona?.handle ?? 'Rival');

  /// Back-compat alias used by older call sites.
  double get value => score;

  String get scoreLabel {
    switch (metric) {
      case RivalBoardMetric.binder:
      case RivalBoardMetric.flips:
        if (score >= 1000) {
          return '\$${(score / 1000).toStringAsFixed(1)}k';
        }
        return '\$${score.toStringAsFixed(0)}';
      case RivalBoardMetric.greens:
        return score.round().toString();
    }
  }
}

class RivalShowcaseCard {
  const RivalShowcaseCard({
    required this.def,
    required this.foil,
    required this.condition,
    required this.graded,
    this.grade,
  });

  final CardDef def;
  final bool foil;
  final Condition condition;
  final bool graded;
  final double? grade;
}

class RivalSim {
  /// Day-stable seed — one board day = [GameClock.dayLength] real time (~2h).
  static int daySeed([DateTime? now]) => GameClock.daySeed(now);

  /// Alias for older call sites — same as [daySeed].
  static int weekSeed([DateTime? now]) => daySeed(now);

  /// Rough cash-from-sales proxy when we don't track lifetime revenue.
  static double playerFlipCash({
    required int cardsSold,
    required double binderValue,
  }) {
    final ticket = math.max(4.0, binderValue / math.max(12, cardsSold + 8));
    return cardsSold * ticket;
  }

  static List<RivalBoardEntry> buildBoard({
    required double playerValue,
    required int businessLevel,
    RivalBoardMetric metric = RivalBoardMetric.binder,
    int playerCardsSold = 0,
    int playerGemsPulled = 0,
    int? day,
  }) {
    final seed = day ?? daySeed();
    final n = rivalBoardSizeForLevel(businessLevel);
    final roster = rivalPersonas.take(n).toList();
    final playerScore = _playerScore(
      metric: metric,
      binderValue: playerValue,
      cardsSold: playerCardsSold,
      gemsPulled: playerGemsPulled,
    );
    final entries = <RivalBoardEntry>[];

    for (var i = 0; i < roster.length; i++) {
      final p = roster[i];
      final local = math.Random(seed * 31 + p.seed + metric.index * 97);
      entries.add(
        RivalBoardEntry(
          persona: p,
          score: _rivalScore(
            metric: metric,
            playerScore: playerScore,
            local: local,
            persona: p,
          ),
          status: _statusFor(local, i),
          isPlayer: false,
          metric: metric,
        ),
      );
    }

    entries.add(
      RivalBoardEntry(
        persona: null,
        score: playerScore,
        status: RivalStatus.idle,
        isPlayer: true,
        metric: metric,
      ),
    );

    entries.sort((a, b) => b.score.compareTo(a.score));
    return [
      for (var i = 0; i < entries.length; i++)
        RivalBoardEntry(
          persona: entries[i].persona,
          score: entries[i].score,
          status: entries[i].status,
          isPlayer: entries[i].isPlayer,
          metric: metric,
          rank: i + 1,
        ),
    ];
  }

  static double _playerScore({
    required RivalBoardMetric metric,
    required double binderValue,
    required int cardsSold,
    required int gemsPulled,
  }) {
    return switch (metric) {
      RivalBoardMetric.binder => math.max(0.0, binderValue),
      RivalBoardMetric.flips => playerFlipCash(
          cardsSold: cardsSold,
          binderValue: binderValue,
        ),
      RivalBoardMetric.greens => gemsPulled.toDouble(),
    };
  }

  static double _rivalScore({
    required RivalBoardMetric metric,
    required double playerScore,
    required math.Random local,
    required RivalPersona persona,
  }) {
    var bias = persona.wealthMult;
    final tags = persona.personality;
    final agr = persona.aggression;
    switch (metric) {
      case RivalBoardMetric.binder:
        if (tags.contains('collector') || tags.contains('whale')) {
          bias *= 1.18;
        }
        if (tags.contains('bulk') || tags.contains('flipper')) bias *= 0.92;
        bias *= 1.0 + agr * 0.12;
      case RivalBoardMetric.flips:
        if (tags.contains('flipper') || tags.contains('dealer')) {
          bias *= 1.22;
        }
        if (tags.contains('collector') || tags.contains('patient')) {
          bias *= 0.90;
        }
        bias *= 1.0 + agr * 0.18;
      case RivalBoardMetric.greens:
        if (tags.contains('foil-hunter') ||
            tags.contains('hype') ||
            tags.contains('impulsive')) {
          bias *= 1.28;
        }
        if (tags.contains('practical') || tags.contains('bulk')) bias *= 0.85;
        bias *= 1.0 + agr * 0.22;
    }

    final floor = switch (metric) {
      RivalBoardMetric.binder => 80.0,
      RivalBoardMetric.flips => 18.0,
      RivalBoardMetric.greens => 1.0,
    };
    // Richer + more competitive: rivals often sit above the player.
    final spread = 0.75 + local.nextDouble() * 1.15 + agr * 0.35;
    final jitter =
        (local.nextDouble() - 0.5) * math.max(1.0, playerScore) * 0.18;
    final raw = playerScore * spread * bias + jitter;
    if (metric == RivalBoardMetric.greens) {
      return math.max(floor, raw).roundToDouble();
    }
    return math.max(floor, raw);
  }

  static RivalStatus _statusFor(math.Random rng, int i) {
    final roll = rng.nextDouble();
    // Louder pit: more high-bid / sweating.
    if (roll < 0.22) return RivalStatus.highBid;
    if (roll < 0.42) return RivalStatus.sweating;
    if (roll < 0.55) return RivalStatus.listing;
    if (roll < 0.62) return RivalStatus.tappedOut;
    return RivalStatus.idle;
  }

  static int playerRank({
    required double playerValue,
    required int businessLevel,
    RivalBoardMetric metric = RivalBoardMetric.binder,
    int playerCardsSold = 0,
    int playerGemsPulled = 0,
  }) {
    final board = buildBoard(
      playerValue: playerValue,
      businessLevel: businessLevel,
      metric: metric,
      playerCardsSold: playerCardsSold,
      playerGemsPulled: playerGemsPulled,
    );
    for (final e in board) {
      if (e.isPlayer) return e.rank;
    }
    return board.length;
  }

  /// Deterministic showcase cards for a rival from the active catalog.
  static List<RivalShowcaseCard> showcaseFor(
    RivalPersona persona,
    GameCatalog catalog, {
    int count = 12,
  }) {
    final cards = catalog.cards
        .where((c) => c.marketPrice > 0.25 && c.rarity != Rarity.token)
        .toList();
    if (cards.isEmpty) return const [];

    final rng = math.Random(persona.seed * 17 + daySeed());
    final sorted = [...cards]
      ..sort((a, b) => b.marketPrice.compareTo(a.marketPrice));
    final pool = sorted.take(math.min(80, sorted.length)).toList();
    final out = <RivalShowcaseCard>[];
    final used = <String>{};

    while (out.length < count && used.length < pool.length) {
      final def = pool[rng.nextInt(pool.length)];
      if (!used.add(def.id)) continue;
      final foil = def.rarity.isRarePlus
          ? rng.nextDouble() < 0.55
          : rng.nextDouble() < 0.18;
      final graded = rng.nextDouble() < 0.12;
      out.add(
        RivalShowcaseCard(
          def: def,
          foil: foil,
          condition: rng.nextDouble() < 0.85
              ? Condition.nearMint
              : Condition.mint,
          graded: graded,
          grade: graded ? (8.5 + rng.nextDouble() * 1.5) : null,
        ),
      );
    }
    return out;
  }

  /// Flavor feed lines for Auction Pit.
  static List<String> pitFeedFor({
    required RivalPersona? highBidder,
    required String cardName,
    required double bid,
    required int endsInTurns,
    int? secsLeft,
    int? paddleCount,
  }) {
    final name = highBidder?.handle ?? 'A rival';
    final secs = secsLeft;
    final paddles = paddleCount ?? 4;
    return [
      if (secs != null && secs <= 5)
        'HAMMER — ${secs}s left. Paddles flying.',
      if (secs != null && secs > 5 && secs <= 10)
        'Clock bleeding — $secs on the hammer.',
      if (secs == null && endsInTurns <= 1)
        'Anti-snipe: clock got a slap — paddles up.',
      '$name holds \$${bid.toStringAsFixed(2)} on $cardName.',
      if (highBidder != null) highBidder.quirk,
      '$paddles paddles still waving in the pit.',
      if (secs != null && secs <= 3)
        'Going once… going twice…',
      'Read the room. Don\'t feed the hype.',
    ];
  }
}
