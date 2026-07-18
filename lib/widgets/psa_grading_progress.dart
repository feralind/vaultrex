import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Inline PSA send button: progress stays on the button; sheet stays dismissible.
class PsaSendButton extends ConsumerStatefulWidget {
  const PsaSendButton({
    super.key,
    required this.instanceId,
  });

  final String instanceId;

  @override
  ConsumerState<PsaSendButton> createState() => _PsaSendButtonState();
}

class _PsaSendButtonState extends ConsumerState<PsaSendButton> {
  Timer? _tick;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      final job = _activeJob(ref.read(gameProvider));
      if (job != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  GradingJob? _activeJob(GameState state) {
    for (final g in state.grading) {
      if (g.ownedInstanceId == widget.instanceId && !g.revealed) return g;
    }
    return null;
  }

  OwnedCard? _owned(GameState state) {
    for (final c in state.collection) {
      if (c.instanceId == widget.instanceId) return c;
    }
    return null;
  }

  double _progress(GradingJob job) {
    final secs = job.company.realtimeSeconds;
    final readyAt = job.readyAtMs;
    if (readyAt == null || secs <= 0) return job.ready ? 1 : 0;
    final start = readyAt - secs * 1000;
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now - start) / (secs * 1000)).clamp(0.0, 1.0);
  }

  String _status(GradingJob job, double t) {
    if (job.ready || t >= 0.88) return 'Finalizing…';
    if (t >= 0.62) return 'Slabbing…';
    if (t >= 0.28) return 'Grading…';
    return 'PSA receiving…';
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(gameProvider.notifier)
          .sendToGrading(widget.instanceId, GradingCompany.psa);
      HapticFeedback.selectionClick();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final owned = _owned(state);
    final listed = owned?.listedAsk != null;
    final graded = owned?.graded ?? false;
    final job = _activeJob(state);

    if (graded && owned != null) {
      final g = owned.grade ?? 0;
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonal(
          onPressed: null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(
            g >= 10
                ? 'PSA 10 · Gem Mint'
                : 'PSA ${g.toStringAsFixed(g % 1 == 0 ? 0 : 1)}',
            style: AppText.jakarta(fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    if (job != null) {
      final t = _progress(job);
      final status = _status(job, t);
      return SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CC.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CC.line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w700,
                    color: CC.inkMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: t,
                    minHeight: 8,
                    backgroundColor: CC.line,
                    color: CC.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can close this sheet — grading continues.',
                  style: AppText.jakarta(
                    fontSize: 11,
                    color: CC.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final busy = _sending || listed;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: busy ? null : _send,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        child: _sending
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Send to PSA · \$${GradingCompany.psa.fee}',
                style: AppText.jakarta(fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
