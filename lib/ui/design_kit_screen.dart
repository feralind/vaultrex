import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Debug-only design system checklist.
class DesignKitScreen extends StatelessWidget {
  const DesignKitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(title: const Text('Design kit')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s16),
        children: [
          Text('Colors', style: AppText.titleSm()),
          const SizedBox(height: AppSpace.s8),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              _swatch('bg', CC.bg),
              _swatch('elevated', CC.bgElevated),
              _swatch('card', CC.card),
              _swatch('accent', CC.accent),
              _swatch('scan', CC.scan),
              _swatch('candy', CC.candy),
              _swatch('cash', CC.cash),
              for (final r in Rarity.values)
                if (r != Rarity.none)
                  _swatch(r.name, CC.rarityColor(r)),
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          Text('Type', style: AppText.titleSm()),
          const SizedBox(height: AppSpace.s8),
          Text('Display', style: AppText.display()),
          Text('Title', style: AppText.title()),
          Text('Title sm', style: AppText.titleSm()),
          Text('Body copy for collector chrome.', style: AppText.body()),
          Text('Muted supporting line.', style: AppText.bodySm()),
          Text('LABEL', style: AppText.label()),
          Text('\$123.45', style: AppText.tabular(color: CC.cash)),
          const SizedBox(height: AppSpace.s24),
          Text('Components', style: AppText.titleSm()),
          const SizedBox(height: AppSpace.s8),
          const ScreenTitle('Screen title', subtitle: 'Optional subtitle'),
          const SizedBox(height: AppSpace.s12),
          const BalanceBar(candy: 250, cash: 42.5),
          const SizedBox(height: AppSpace.s12),
          FilterChipBar(
            padding: EdgeInsets.zero,
            children: [
              AppChip(label: 'All', selected: true, onTap: () {}),
              AppChip(label: 'Foil', onTap: () {}),
              AppChip(label: 'PSA', onTap: () {}),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          FilledButton(onPressed: () {}, child: const Text('Primary CTA')),
          const SizedBox(height: AppSpace.s8),
          OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
          const SizedBox(height: AppSpace.s24),
          Text('Radius ${AppSpace.rCard} / chip ${AppSpace.rChip}',
              style: AppText.bodySm()),
        ],
      ),
    );
  }

  Widget _swatch(String name, Color c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(AppSpace.rChip),
            border: Border.all(color: CC.line),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: AppText.label()),
      ],
    );
  }
}
