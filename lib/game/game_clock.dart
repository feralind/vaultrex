/// Wall-clock ↔ in-game day mapping.
///
/// **Game day:** [dayLength] of real phone time (2 hours) → auctions, rivals,
/// catch-up ticks, leaderboard board day.
///
/// **Real-life calendar day:** daily candy claim + daily goals use
/// [engagementDayKey] / [realLifeDayKey] (once per local calendar day) — NOT
/// this 2h clock.
abstract final class GameClock {
  static const Duration dayLength = Duration(hours: 2);
  static const int dayLengthMs = 2 * 60 * 60 * 1000;

  /// Monotonic day index from Unix epoch (changes every [dayLength]).
  static int daySeed([DateTime? now]) {
    final ms = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return ms ~/ dayLengthMs;
  }

  /// How many full in-game days elapsed between [fromMs] and [toMs].
  static int daysElapsed(int fromMs, int toMs) {
    if (toMs <= fromMs) return 0;
    return (toMs - fromMs) ~/ dayLengthMs;
  }

  /// Time left in the current 2h day window.
  static Duration remainingInDay([DateTime? now]) {
    final ms = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final into = ms % dayLengthMs;
    return Duration(milliseconds: dayLengthMs - into);
  }

  static String remainingLabel([DateTime? now]) {
    final r = remainingInDay(now);
    final m = r.inMinutes;
    if (m >= 60) {
      final h = m ~/ 60;
      final rem = m % 60;
      return rem == 0 ? '${h}h left' : '${h}h ${rem}m left';
    }
    return '${m}m left';
  }
}
