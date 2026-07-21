part of 'game_controller.dart';

mixin _RentalActions on _GameNotifierBase {
  /// Rent an already-graded collection card for passive candy.
  Future<void> startRental(String instanceId) async {
    await cleanupExpiredRentals();
    if (state.activeRentals.containsKey(instanceId)) {
      state = state.copyWith(message: 'That card is already on rental.');
      return;
    }
    final idx =
        state.collection.indexWhere((c) => c.instanceId == instanceId);
    if (idx < 0) {
      state = state.copyWith(message: 'Card not in collection.');
      return;
    }
    final card = state.collection[idx];
    if (!card.graded || card.grade == null) {
      state = state.copyWith(
        message: 'Grade the card first (PSA), then rent it out.',
      );
      return;
    }
    if (card.listedAsk != null) {
      state = state.copyWith(message: 'Delist the card before renting.');
      return;
    }
    if (state.player.candy < kRentalStartFeeCandy) {
      state = state.copyWith(
        message: 'Need $kRentalStartFeeCandy candy to start a rental.',
      );
      return;
    }

    final fair = fairFor(card);
    final grade = card.grade!;
    final rate = (fair * (grade / 10) * 12 + grade * 8)
        .clamp(25.0, 450.0)
        .toDouble();
    final now = DateTime.now().millisecondsSinceEpoch;
    final until =
        now + const Duration(days: kRentalDurationDays).inMilliseconds;
    final rental = CardRental(
      instanceId: instanceId,
      gradeAtTimestamp: now,
      psaGrade: grade,
      dailyEarningRate: double.parse(rate.toStringAsFixed(1)),
      rentedUntilTimestamp: until,
    );
    final player = state.player.copyWith(
      candy: state.player.candy - kRentalStartFeeCandy,
    );
    final next = Map<String, CardRental>.from(state.activeRentals)
      ..[instanceId] = rental;
    state = state.copyWith(
      player: player,
      activeRentals: next,
      message:
          'Rented PSA ${grade.toStringAsFixed(grade == grade.roundToDouble() ? 0 : 1)} '
          '— ${rate.toStringAsFixed(0)} candy/day for $kRentalDurationDays days.',
    );
    await _persist();
  }

  /// Alias: rent only works on already-graded cards.
  Future<void> gradeCardForRental(String instanceId) =>
      startRental(instanceId);

  double getTotalDailyEarnings() {
    final now = DateTime.now().millisecondsSinceEpoch;
    var sum = 0.0;
    for (final r in state.activeRentals.values) {
      if (!r.isExpired(now)) sum += r.dailyEarningRate;
    }
    return sum;
  }

  Future<void> claimRentalEarnings() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    var gain = 0;
    final next = <String, CardRental>{};
    for (final e in state.activeRentals.entries) {
      final r = e.value;
      gain += r.calculateEarnings(now);
      if (r.isExpired(now)) continue;
      next[e.key] = r.copyWith(gradeAtTimestamp: now);
    }
    if (gain <= 0 && next.length == state.activeRentals.length) {
      state = state.copyWith(
        message: 'No rental earnings yet — check back later.',
      );
      return;
    }
    final player = state.player.copyWith(
      candy: state.player.candy + gain,
    );
    state = state.copyWith(
      player: player,
      activeRentals: next,
      message: gain > 0
          ? 'Claimed $gain candy from rentals.'
          : 'Expired rentals cleared.',
    );
    await _persist();
  }

  Future<void> cleanupExpiredRentals() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final before = state.activeRentals.length;
    final next = Map<String, CardRental>.from(state.activeRentals)
      ..removeWhere((_, r) => r.isExpired(now));
    if (next.length == before) return;
    state = state.copyWith(activeRentals: next);
    await _persist();
  }
}
