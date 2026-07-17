import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/enums.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// ~10s simulated PSA pipeline with status steps, then auto-reveal.
Future<double?> showPsaGradingProgress(
  BuildContext context,
  WidgetRef ref, {
  required String instanceId,
}) async {
  final notifier = ref.read(gameProvider.notifier);
  final before = ref.read(gameProvider).grading.map((g) => g.id).toSet();
  await notifier.sendToGrading(instanceId, GradingCompany.psa);
  final after = ref.read(gameProvider).grading;
  String? jobId;
  for (final g in after) {
    if (!before.contains(g.id) && g.ownedInstanceId == instanceId) {
      jobId = g.id;
      break;
    }
  }
  if (jobId == null) {
    for (final g in after) {
      if (g.ownedInstanceId == instanceId && !g.revealed) {
        jobId = g.id;
        break;
      }
    }
  }

  if (jobId == null) {
    if (context.mounted) {
      final msg = ref.read(gameProvider).message ?? 'Could not start grading.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    return null;
  }

  if (!context.mounted) return null;
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PsaProgressDialog(jobId: jobId!),
  );
}

class _PsaProgressDialog extends ConsumerStatefulWidget {
  const _PsaProgressDialog({required this.jobId});
  final String jobId;

  @override
  ConsumerState<_PsaProgressDialog> createState() => _PsaProgressDialogState();
}

class _PsaProgressDialogState extends ConsumerState<_PsaProgressDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String _status = 'PSA receiving…';
  double? _grade;

  static const _steps = [
    (0.0, 'PSA receiving…'),
    (0.28, 'Grading…'),
    (0.62, 'Slabbing…'),
    (0.88, 'Finalizing…'),
  ];

  @override
  void initState() {
    super.initState();
    final secs = GradingCompany.psa.realtimeSeconds;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: secs),
    )..addListener(() {
        final t = _ctrl.value;
        for (final s in _steps.reversed) {
          if (t >= s.$1) {
            if (_status != s.$2) setState(() => _status = s.$2);
            break;
          }
        }
      });
    _run();
  }

  Future<void> _run() async {
    await _ctrl.forward(from: 0);
    if (!mounted) return;
    final grade =
        await ref.read(gameProvider.notifier).completeRealtimeGrading(widget.jobId);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _grade = grade;
      _status = grade == null
          ? 'Grading failed — fee was charged. Try again from Collection.'
          : grade >= 10
              ? 'GEM MINT 10!'
              : 'PSA ${grade.toStringAsFixed(grade % 1 == 0 ? 0 : 1)}';
    });
    await Future<void>.delayed(
      Duration(milliseconds: grade == null ? 1600 : 900),
    );
    if (mounted) Navigator.pop(context, grade);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CC.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'PSA Grading',
        style: AppText.jakarta(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _status,
            style: AppText.jakarta(
              color: CC.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _grade != null ? 1 : _ctrl.value,
                  minHeight: 8,
                  backgroundColor: CC.line,
                  color: CC.accent,
                ),
              );
            },
          ),
          if (_grade != null) ...[
            const SizedBox(height: 14),
            Text(
              _grade! >= 10
                  ? 'Slab ready — Gem Mint 10'
                  : 'Slab ready — ${_grade!.toStringAsFixed(_grade! % 1 == 0 ? 0 : 1)}',
              style: AppText.jakarta(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF34D399),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
