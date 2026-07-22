import 'package:flutter/material.dart';

import '../data/onboarding.dart';
import 'brand.dart';

/// Horizontal franchise logos — equal slots, logo glow (no plate background).
class FranchiseIconRow extends StatelessWidget {
  const FranchiseIconRow({
    super.key,
    required this.activeId,
    required this.onSelect,
    this.height = 64,
    this.slotWidth = 92,
  });

  final String activeId;
  final Future<void> Function(GameOption game) onSelect;
  final double height;
  /// Fixed width per franchise so marks line up evenly.
  final double slotWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kGames.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final g = kGames[i];
          return _FranchiseIcon(
            selected: activeId == g.id,
            logoAsset: g.logoAsset,
            color: g.color,
            locked: !g.enabled,
            slotWidth: slotWidth,
            rowHeight: height,
            onTap: g.enabled ? () => onSelect(g) : null,
          );
        },
      ),
    );
  }
}

class _FranchiseIcon extends StatelessWidget {
  const _FranchiseIcon({
    required this.selected,
    required this.logoAsset,
    required this.color,
    required this.slotWidth,
    required this.rowHeight,
    this.onTap,
    this.locked = false,
  });

  final bool selected;
  final String logoAsset;
  final Color color;
  final double slotWidth;
  final double rowHeight;
  final VoidCallback? onTap;
  final bool locked;

  static const _logoBoxH = 36.0;
  static const _underlineH = 3.0;
  static const _gap = 5.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      height: rowHeight,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Opacity(
          opacity: locked ? 0.35 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: slotWidth,
                height: _logoBoxH,
                child: Center(
                  child: GlowingGameLogo(
                    asset: logoAsset,
                    glowColor: color,
                    height: _logoBoxH,
                    width: slotWidth - 8,
                    glowing: selected,
                    glowStrength: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: _gap),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 28 : 0,
                height: _underlineH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.7),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
