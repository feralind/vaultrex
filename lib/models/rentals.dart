/// Candy fee to put a graded card on loan.
const int kRentalStartFeeCandy = 250;

/// Default rental length in days.
const int kRentalDurationDays = 7;

/// A graded collection card loaned out for passive candy earnings.
class CardRental {
  const CardRental({
    required this.instanceId,
    required this.gradeAtTimestamp,
    required this.psaGrade,
    required this.dailyEarningRate,
    required this.rentedUntilTimestamp,
  });

  final String instanceId;
  /// Wall-clock ms when the rental (or last claim window) started.
  final int gradeAtTimestamp;
  final double psaGrade;
  /// Candy earned per full day on loan.
  final double dailyEarningRate;
  final int rentedUntilTimestamp;

  bool isExpired([int? nowMs]) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return now >= rentedUntilTimestamp;
  }

  int daysRemaining([int? nowMs]) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (now >= rentedUntilTimestamp) return 0;
    final ms = rentedUntilTimestamp - now;
    return (ms / Duration.millisecondsPerDay).ceil();
  }

  /// Unclaimed candy accrued since [gradeAtTimestamp], capped at rental end.
  int calculateEarnings([int? nowMs]) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final end = now < rentedUntilTimestamp ? now : rentedUntilTimestamp;
    if (end <= gradeAtTimestamp) return 0;
    final days = (end - gradeAtTimestamp) / Duration.millisecondsPerDay;
    return (days * dailyEarningRate).floor().clamp(0, 1000000);
  }

  CardRental copyWith({
    String? instanceId,
    int? gradeAtTimestamp,
    double? psaGrade,
    double? dailyEarningRate,
    int? rentedUntilTimestamp,
  }) {
    return CardRental(
      instanceId: instanceId ?? this.instanceId,
      gradeAtTimestamp: gradeAtTimestamp ?? this.gradeAtTimestamp,
      psaGrade: psaGrade ?? this.psaGrade,
      dailyEarningRate: dailyEarningRate ?? this.dailyEarningRate,
      rentedUntilTimestamp:
          rentedUntilTimestamp ?? this.rentedUntilTimestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'gradeAtTimestamp': gradeAtTimestamp,
        'psaGrade': psaGrade,
        'dailyEarningRate': dailyEarningRate,
        'rentedUntilTimestamp': rentedUntilTimestamp,
      };

  factory CardRental.fromJson(Map<String, dynamic> j) => CardRental(
        instanceId: j['instanceId'] as String,
        gradeAtTimestamp: j['gradeAtTimestamp'] as int? ?? 0,
        psaGrade: (j['psaGrade'] as num?)?.toDouble() ?? 0,
        dailyEarningRate: (j['dailyEarningRate'] as num?)?.toDouble() ?? 0,
        rentedUntilTimestamp: j['rentedUntilTimestamp'] as int? ?? 0,
      );
}
