part of 'game_controller.dart';

mixin _GradingActions on _GameNotifierBase {
  Future<void> sendToGrading(String instanceId, GradingCompany company) async {
    final card = state.collection.firstWhere((c) => c.instanceId == instanceId);
    if (card.graded || card.listedAsk != null) {
      state = state.copyWith(message: 'Cannot grade this card right now.');
      return;
    }
    if (state.grading.any(
      (g) => g.ownedInstanceId == instanceId && !g.revealed,
    )) {
      state = state.copyWith(message: 'Already at PSA.');
      return;
    }
    final fee = company.fee.toDouble();
    if (state.player.cash < fee) {
      state = state.copyWith(message: 'Need \$${fee.toStringAsFixed(0)} for grading.');
      return;
    }
    final player = state.player.copyWith(cash: state.player.cash - fee);
    final secs = company.realtimeSeconds;
    final job = GradingJob(
      id: _uuid.v4(),
      ownedInstanceId: instanceId,
      company: company,
      turnsLeft: 0,
      readyAtMs: DateTime.now().millisecondsSinceEpoch + secs * 1000,
    );
    state = state.copyWith(
      player: player,
      grading: [...state.grading, job],
      message: 'Sent to ${company.label} · ~${secs}s.',
    );
    _onEngagementGradeSent();
    await _persist();
    // Complete in the background so the card sheet can be dismissed.
    unawaited(_finishRealtimeWhenReady(job.id, secs));
  }

  Future<void> _finishRealtimeWhenReady(String jobId, int secs) async {
    await Future<void>.delayed(Duration(seconds: secs));
    try {
      await completeRealtimeGrading(jobId);
    } catch (_) {
      // Soft-fail; catchUpGrading will retry on resume/bootstrap.
    }
  }

  /// Completes any wall-clock-ready grading jobs (app resume / bootstrap).
  Future<int> catchUpGrading() async {
    await tickRealtimeGrading();
    var n = 0;
    final pending = state.grading
        .where((g) => g.ready && !g.revealed)
        .map((g) => g.id)
        .toList();
    for (final id in pending) {
      await revealSlab(id);
      n++;
    }
    if (n > 0) {
      final prev = state.engagement.pendingResumeMessage;
      final slabMsg = n == 1
          ? 'A slab is ready — check Collection.'
          : '$n slabs ready — check Collection.';
      state = state.copyWith(
        engagement: state.engagement.copyWith(
          pendingResumeMessage:
              prev == null ? slabMsg : '$prev · $slabMsg',
        ),
      );
      await _persist();
    }
    return n;
  }

  /// Marks realtime jobs ready when wall-clock elapsed; returns newly ready ids.
  Future<List<String>> tickRealtimeGrading() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    var changed = false;
    final newly = <String>[];
    for (final g in state.grading) {
      if (g.ready || g.revealed) continue;
      final at = g.readyAtMs;
      if (at != null && now >= at) {
        g.ready = true;
        g.turnsLeft = 0;
        newly.add(g.id);
        changed = true;
      }
    }
    if (changed) {
      state = state.copyWith(grading: [...state.grading]);
      await _persist();
    }
    return newly;
  }

  /// Completes a realtime PSA job after the ~10s wait (mark ready + reveal).
  Future<double?> completeRealtimeGrading(String jobId) async {
    await tickRealtimeGrading();
    GradingJob? job;
    for (final g in state.grading) {
      if (g.id == jobId) {
        job = g;
        break;
      }
    }
    if (job == null) return null;
    if (!job.ready) {
      job.ready = true;
      job.turnsLeft = 0;
      state = state.copyWith(grading: [...state.grading]);
    }
    await revealSlab(jobId);
    for (final g in state.grading) {
      if (g.id == jobId) return g.resultGrade;
    }
    return null;
  }

  Future<void> revealSlab(String jobId) async {
    final job = state.grading.firstWhere((g) => g.id == jobId);
    if (!job.ready || job.revealed) return;
    final card =
        state.collection.firstWhere((c) => c.instanceId == job.ownedInstanceId);
    final grade = _rollGrade(card, job.company);
    job.revealed = true;
    job.resultGrade = grade;
    final updated = state.collection.map((c) {
      if (c.instanceId != card.instanceId) return c;
      return c.copyWith(
        graded: true,
        grade: grade,
        gradingCompany: job.company,
      );
    }).toList();
    var player = state.player;
    if (grade >= 10) {
      player = player.copyWith(gemsPulled: player.gemsPulled + 1);
    }
    player = player.copyWith(xp: player.xp + (grade >= 9.5 ? 15 : 5));
    state = state.copyWith(
      player: player,
      collection: updated,
      grading: [...state.grading],
      message: grade >= 10
          ? 'GEM MINT 10!'
          : '${job.company.label} ${grade.toStringAsFixed(1)}',
    );
    _onEngagementGradeRevealed();
    _checkAchievements();
    _recordCollectionValue();
    await _persist();
  }

  Future<void> massReveal() async {
    if (!state.player.ownedUpgrades.contains('mass_reveal')) {
      state = state.copyWith(message: 'Unlock Mass Reveal first.');
      return;
    }
    final ready = state.grading.where((g) => g.ready && !g.revealed).toList();
    for (final j in ready) {
      await revealSlab(j.id);
    }
  }

  double _rollGrade(OwnedCard card, GradingCompany _) {
    final center = card.centeringScore;
    final sub = (card.surface + card.edges + card.corners) / 3;
    var raw = (center / 10 + sub) / 2;
    // PSA — honest grades, no soft bump
    if (card.defects.contains(FactoryDefect.miscut)) raw -= 1.5;
    if (card.defects.contains(FactoryDefect.bentCorner)) raw -= 0.8;
    raw = raw.clamp(1.0, 10.0);
    // Snap to common grade steps
    final steps = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 8.5, 9.0, 9.5, 10.0];
    return steps.reduce((a, b) => (a - raw).abs() < (b - raw).abs() ? a : b);
  }
}
