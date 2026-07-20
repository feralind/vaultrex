import 'package:flutter/material.dart';

import '../data/onboarding.dart';
import 'brand.dart';

/// Horizontal franchise logos (Riftbound / Pokémon / MTG / locked).
class FranchiseIconRow extends StatelessWidget {
  const FranchiseIconRow({
    super.key,
    required this.activeId,
    required this.onSelect,
    this.height = 64,
  });

  final String activeId;
  final Future<void> Function(GameOption game) onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kGames.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final g = kGames[i];
          return _FranchiseIcon(
            selected: activeId == g.id,
            logoAsset: g.logoAsset,
            color: g.color,
            logoScale: g.logoScale,
            locked: !g.enabled,
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
    this.logoScale = 1,
    this.onTap,
    this.locked = false,
  });

  final bool selected;
  final String logoAsset;
  final Color color;
  final double logoScale;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final markH = 40 * logoScale;
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: locked ? 0.35 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: GameBrandLogo(
                asset: logoAsset,
                height: markH,
                width: logoScale > 1 ? markH : 72,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
