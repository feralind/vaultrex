import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Simulated Google Pay checkout — dark night mode, never contacts Google/banks.
Future<bool> showFakeGooglePay(
  BuildContext context, {
  required double amount,
  String merchant = 'Vaultrex',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FakeGooglePaySheet(
      amount: amount,
      merchant: merchant,
    ),
  );
  return result == true;
}

enum _PayMode { now, later }

enum _CardBrand { visa, mastercard }

class _FakeGooglePaySheet extends StatefulWidget {
  const _FakeGooglePaySheet({
    required this.amount,
    required this.merchant,
  });

  final double amount;
  final String merchant;

  @override
  State<_FakeGooglePaySheet> createState() => _FakeGooglePaySheetState();
}

class _FakeGooglePaySheetState extends State<_FakeGooglePaySheet> {
  _PayMode _mode = _PayMode.now;
  _CardBrand _brand = _CardBrand.visa;
  bool _busy = false;
  bool _done = false;

  static const _last4 = '4242';

  void _tick() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  Future<void> _continue() async {
    if (_busy) return;
    _tick();
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    SystemSound.play(SystemSoundType.click);
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: CC.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _busy ? null : () => Navigator.pop(context, false),
                icon: const Icon(Icons.close, color: CC.inkMuted),
              ),
              const Spacer(),
              const _GPayMark(),
              const Spacer(),
              CircleAvatar(
                radius: 16,
                backgroundColor: CC.accent,
                child: Text(
                  'V',
                  style: AppText.jakarta(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: CC.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegPill(
                    label: 'Pay Now',
                    selected: _mode == _PayMode.now,
                    onTap: () {
                      _tick();
                      setState(() => _mode = _PayMode.now);
                    },
                  ),
                ),
                Expanded(
                  child: _SegPill(
                    label: 'Pay Later',
                    selected: _mode == _PayMode.later,
                    checked: _mode == _PayMode.later,
                    onTap: () {
                      _tick();
                      setState(() => _mode = _PayMode.later);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: CC.cardSoft,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _busy
                  ? null
                  : () {
                      _tick();
                      setState(() {
                        _brand = _brand == _CardBrand.visa
                            ? _CardBrand.mastercard
                            : _CardBrand.visa;
                      });
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    _BrandBadge(brand: _brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank of America',
                            style: AppText.jakarta(
                              color: CC.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _brand == _CardBrand.visa
                                ? 'Visa Debit  ·  •••• $_last4'
                                : 'Mastercard Debit  ·  •••• $_last4',
                            style: AppText.jakarta(
                              color: CC.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: CC.inkMuted),
                  ],
                ),
              ),
            ),
          ),
          if (_mode == _PayMode.later) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Simulated approval — still settles with Vaultrex cash.',
                style: AppText.jakarta(
                  color: CC.accentHot,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pay ${widget.merchant}',
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '\$${widget.amount.toStringAsFixed(2)}',
                style: AppText.jakarta(
                  color: CC.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _continue,
              style: FilledButton.styleFrom(
                backgroundColor: CC.accent,
                disabledBackgroundColor: CC.accent.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _done
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: AppText.jakarta(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: CC.inkMuted.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Text(
                'Your payment details are encrypted',
                style: AppText.jakarta(
                  color: CC.inkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Simulated checkout · no real charges',
            style: AppText.jakarta(
              color: CC.inkMuted.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegPill extends StatelessWidget {
  const _SegPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.checked = false,
  });

  final String label;
  final bool selected;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CC.cardSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (checked) ...[
                const Icon(Icons.check, size: 16, color: CC.accent),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppText.jakarta(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? CC.ink : CC.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.brand});
  final _CardBrand brand;

  @override
  Widget build(BuildContext context) {
    if (brand == _CardBrand.visa) {
      return Container(
        width: 44,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F71),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CC.line),
        ),
        child: Text(
          'VISA',
          style: AppText.jakarta(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.6,
          ),
        ),
      );
    }
    return Container(
      width: 44,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEB001B), Color(0xFFF79E1B)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'MC',
        style: AppText.jakarta(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _GPayMark extends StatelessWidget {
  const _GPayMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'G',
          style: AppText.jakarta(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: const Color(0xFF8AB4F8),
          ),
        ),
        Text(
          ' Pay',
          style: AppText.jakarta(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: CC.ink,
          ),
        ),
      ],
    );
  }
}
