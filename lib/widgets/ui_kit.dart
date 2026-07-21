import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'brand.dart';

/// Screen title using the design-system type ramp.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(
    this.text, {
    super.key,
    this.subtitle,
  });

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: AppText.display()),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.s4),
          Text(subtitle!, style: AppText.bodySm()),
        ],
      ],
    );
  }
}

/// Candy + cash cluster used across Instapacks / Market headers.
class BalanceBar extends StatelessWidget {
  const BalanceBar({
    super.key,
    required this.candy,
    required this.cash,
    this.onTopUp,
    this.axis = Axis.horizontal,
  });

  final int candy;
  final double cash;
  final VoidCallback? onTopUp;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final kids = <Widget>[
      CandyBalance(candy),
      SizedBox(
        width: axis == Axis.horizontal ? AppSpace.s8 : 0,
        height: axis == Axis.vertical ? AppSpace.s8 : 0,
      ),
      CashBalance(cash, onTap: onTopUp),
    ];
    if (axis == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: kids,
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: kids);
  }
}

/// Compact filter / tag chip.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: AppSpace.durFast,
      curve: AppSpace.curveOut,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.s8 : AppSpace.s12,
        vertical: compact ? 6 : AppSpace.s8,
      ),
      decoration: BoxDecoration(
        color: selected ? CC.accent.withValues(alpha: 0.18) : CC.cardSoft,
        borderRadius: BorderRadius.circular(AppSpace.rChip),
        border: Border.all(
          color: selected ? CC.accent.withValues(alpha: 0.55) : CC.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpace.s4),
          ],
          Text(
            label,
            style: AppText.label(
              color: selected ? CC.ink : CC.inkMuted,
            ).copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? CC.ink : CC.inkMuted,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpace.rChip),
        child: child,
      ),
    );
  }
}

/// Horizontal scrolling chip row.
class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpace.s16),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.s8),
            children[i],
          ],
        ],
      ),
    );
  }
}
