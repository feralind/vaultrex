import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'fake_google_pay_sheet.dart';

/// Amount picker → fake Google Pay → credit wallet cash.
Future<bool> showCashTopUp(BuildContext context, WidgetRef ref) async {
  final amount = await showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CashAmountSheet(),
  );
  if (amount == null || amount <= 0) return false;
  if (!context.mounted) return false;

  final paid = await showFakeGooglePay(
    context,
    amount: amount,
    merchant: 'Vaultrex Wallet',
  );
  if (!paid || !context.mounted) return false;

  await ref.read(gameProvider.notifier).topUpCash(amount);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          amount >= 1000
              ? 'Wallet topped up +\$${amount.toStringAsFixed(0)} · nobody saw that 😉'
              : 'Added \$${amount.toStringAsFixed(2)} to your balance.',
        ),
      ),
    );
  }
  return true;
}

class _Preset {
  const _Preset(this.amount, this.label, {this.wink = false});
  final double amount;
  final String label;
  final bool wink;
}

const _presets = <_Preset>[
  _Preset(10, '\$10'),
  _Preset(25, '\$25'),
  _Preset(50, '\$50'),
  _Preset(100, '\$100'),
  _Preset(250, '\$250'),
  _Preset(500, '\$500'),
  _Preset(9999, '\$9,999\n“oops”', wink: true),
];

class _CashAmountSheet extends StatefulWidget {
  const _CashAmountSheet();

  @override
  State<_CashAmountSheet> createState() => _CashAmountSheetState();
}

class _CashAmountSheetState extends State<_CashAmountSheet> {
  final _controller = TextEditingController(text: '50');
  double? _selectedPreset = 50;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _parsed {
    final raw = _controller.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return null;
    return double.parse(v.clamp(1, 99999).toStringAsFixed(2));
  }

  void _pickPreset(_Preset p) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = p.amount;
      _controller.text =
          p.amount == p.amount.roundToDouble()
              ? p.amount.toStringAsFixed(0)
              : p.amount.toStringAsFixed(2);
    });
  }

  void _continue() {
    final amount = _parsed;
    if (amount == null) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final amount = _parsed;
    final cheesy = (amount ?? 0) >= 1000;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: CC.bgElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CC.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top up wallet',
                    style: AppText.jakarta(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: CC.inkMuted),
                ),
              ],
            ),
            Text(
              'Add Vaultrex cash for packs, market, and PSA. '
              'Totally normal banking energy.',
              style: AppText.jakarta(
                color: CC.inkMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: AppText.jakarta(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF34D399),
              ),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: AppText.jakarta(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF34D399),
                ),
                filled: true,
                fillColor: CC.card,
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() => _selectedPreset = null),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _presets)
                  ChoiceChip(
                    label: Text(
                      p.label,
                      textAlign: TextAlign.center,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: p.wink ? 11 : 13,
                        height: p.wink ? 1.15 : 1.2,
                        color: p.wink && _selectedPreset == p.amount
                            ? Colors.white
                            : (p.wink ? CC.accentHot : null),
                      ),
                    ),
                    selected: _selectedPreset == p.amount,
                    onSelected: (_) => _pickPreset(p),
                    selectedColor: p.wink ? CC.accentHot : CC.accent,
                    backgroundColor: p.wink
                        ? CC.accent.withValues(alpha: 0.12)
                        : CC.card,
                    side: BorderSide(
                      color: p.wink ? CC.accentHot.withValues(alpha: 0.55) : CC.line,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: p.wink ? 10 : 8,
                      vertical: p.wink ? 6 : 0,
                    ),
                  ),
              ],
            ),
            if (cheesy) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CC.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CC.accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'Dev grant detected 😉  Bank of America says “sure, why not.” '
                  'This is simulated cash — stack it if you want to cheat a little.',
                  style: AppText.jakarta(
                    color: CC.accentHot,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: amount == null ? null : _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: CC.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  amount == null
                      ? 'Enter an amount'
                      : 'Continue to Google Pay · \$${amount.toStringAsFixed(2)}',
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Simulated top-up · no real charges',
              textAlign: TextAlign.center,
              style: AppText.jakarta(
                color: CC.inkMuted.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
