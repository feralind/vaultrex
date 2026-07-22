import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/models.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/game_widgets.dart';
import '../widgets/ui_kit.dart';

class RentalsScreen extends ConsumerWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final rentals = state.activeRentals.values.toList()
      ..sort((a, b) => a.rentedUntilTimestamp.compareTo(b.rentedUntilTimestamp));
    final daily = notifier.getTotalDailyEarnings();
    final pending = rentals.fold<int>(0, (s, r) => s + r.calculateEarnings());
    final eligible = _eligible(state);

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: const Text('Rentals'),
        backgroundColor: CC.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          AppSpace.s8,
          AppSpace.s16,
          32,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: ScreenTitle(
                  'Rentals',
                  subtitle: 'Loan graded slabs for passive candy',
                ),
              ),
              BalanceBar(
                candy: state.player.candy,
                cash: state.player.cash,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(AppSpace.rCard),
              border: Border.all(
                color: pending > 0
                    ? CC.cash.withValues(alpha: 0.45)
                    : CC.line,
              ),
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  CC.cash.withValues(alpha: pending > 0 ? 0.22 : 0.14),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Passive candy desk', style: AppText.titleSm()),
                    ),
                    if (pending > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: CC.cash.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ready',
                          style: AppText.jakarta(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: CC.cash,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  'Loan PSA slabs · start fee $kRentalStartFeeCandy candy · claim anytime.',
                  style: AppText.bodySm(),
                ),
                const SizedBox(height: AppSpace.s16),
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        label: 'Per day',
                        value: '${daily.toStringAsFixed(0)} candy',
                        color: CC.candy,
                      ),
                    ),
                    Expanded(
                      child: _stat(
                        label: 'Unclaimed',
                        value: '$pending candy',
                        color: CC.cash,
                      ),
                    ),
                    Expanded(
                      child: _stat(
                        label: 'Active',
                        value: '${rentals.length}',
                        color: CC.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s16),
                FilledButton(
                  onPressed: pending > 0 || rentals.any((r) => r.isExpired())
                      ? () => notifier.claimRentalEarnings()
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: pending > 0 ? CC.cash : CC.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpace.s16,
                      horizontal: AppSpace.s24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpace.rCard),
                    ),
                  ),
                  child: Text(
                    pending > 0
                        ? 'Claim $pending candy'
                        : 'Claim earnings',
                    style: AppText.jakarta(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s24),
          Text('Active rentals', style: AppText.titleSm()),
          const SizedBox(height: AppSpace.s4),
          Text(
            rentals.isEmpty
                ? 'Nothing on loan yet'
                : '${rentals.length} card${rentals.length == 1 ? '' : 's'} earning',
            style: AppText.bodySm(),
          ),
          const SizedBox(height: AppSpace.s12),
          if (rentals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s24),
              child: Center(
                child: Text(
                  'No cards on loan.\nPick a graded slab below to start.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySm(),
                ),
              ),
            )
          else
            ...rentals.map((r) {
              final card = state.collection
                  .where((c) => c.instanceId == r.instanceId)
                  .firstOrNull;
              final def =
                  card != null ? notifier.catalog.byId[card.cardId] : null;
              return _RentalTile(
                rental: r,
                def: def,
                foil: card?.foil ?? false,
              );
            }),
          const SizedBox(height: AppSpace.s24),
          Text('Eligible graded cards', style: AppText.titleSm()),
          const SizedBox(height: AppSpace.s4),
          Text(
            'Already slabbed · not listed · not currently rented.',
            style: AppText.bodySm(),
          ),
          const SizedBox(height: AppSpace.s12),
          if (eligible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
              child: Center(
                child: Text(
                  'No free graded cards.\nReveal a PSA slab first, then rent it here.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySm(),
                ),
              ),
            )
          else
            ...eligible.map((card) {
              final def = notifier.catalog.byId[card.cardId];
              return _EligibleTile(
                card: card,
                def: def,
                onRent: () => notifier.startRental(card.instanceId),
              );
            }),
        ],
      ),
    );
  }

  List<OwnedCard> _eligible(GameState state) {
    return state.collection
        .where((c) => c.graded && c.grade != null)
        .where((c) => c.listedAsk == null)
        .where((c) => !state.activeRentals.containsKey(c.instanceId))
        .toList()
      ..sort((a, b) => (b.grade ?? 0).compareTo(a.grade ?? 0));
  }

  Widget _stat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label()),
        const SizedBox(height: AppSpace.s4),
        Text(
          value,
          style: AppText.tabular(color: color, fontSize: 14),
        ),
      ],
    );
  }
}

class _RentalTile extends StatelessWidget {
  const _RentalTile({
    required this.rental,
    required this.def,
    required this.foil,
  });

  final CardRental rental;
  final CardDef? def;
  final bool foil;

  @override
  Widget build(BuildContext context) {
    final url = def?.displayArtUrl ?? '';
    final days = rental.daysRemaining();
    final earn = rental.calculateEarnings();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s12),
        decoration: BoxDecoration(
          color: CC.card,
          borderRadius: BorderRadius.circular(AppSpace.rCard),
          border: Border.all(
            color: rental.isExpired()
                ? CC.scan.withValues(alpha: 0.4)
                : CC.line,
          ),
        ),
        child: Row(
          children: [
            if (url.isNotEmpty)
              PortraitSlotArt(
                url: url,
                width: 44,
                height: 62,
                landscape: def?.isLandscapeCard ?? false,
                foil: foil,
                radius: 6,
              )
            else
              Container(
                width: 44,
                height: 62,
                decoration: BoxDecoration(
                  color: CC.cardSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def?.name ?? 'Card',
                    style: AppText.titleSm(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    'PSA ${rental.psaGrade.toStringAsFixed(rental.psaGrade == rental.psaGrade.roundToDouble() ? 0 : 1)} · '
                    '${rental.dailyEarningRate.toStringAsFixed(0)} candy/day',
                    style: AppText.bodySm(),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  AppChip(
                    label: rental.isExpired()
                        ? 'Expired · $earn pending'
                        : '$days day${days == 1 ? '' : 's'} left · $earn pending',
                    compact: true,
                    selected: rental.isExpired() || earn > 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EligibleTile extends StatelessWidget {
  const _EligibleTile({
    required this.card,
    required this.def,
    required this.onRent,
  });

  final OwnedCard card;
  final CardDef? def;
  final VoidCallback onRent;

  @override
  Widget build(BuildContext context) {
    final url = def?.displayArtUrl ?? '';
    final grade = card.grade!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s8),
      child: Material(
        color: CC.card,
        borderRadius: BorderRadius.circular(AppSpace.rCard),
        child: InkWell(
          onTap: onRent,
          borderRadius: BorderRadius.circular(AppSpace.rCard),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpace.rCard),
              border: Border.all(color: CC.line),
            ),
            child: Row(
              children: [
                if (url.isNotEmpty)
                  PortraitSlotArt(
                    url: url,
                    width: 40,
                    height: 56,
                    landscape: def?.isLandscapeCard ?? false,
                    foil: card.foil,
                    radius: 6,
                  )
                else
                  const SizedBox(width: 40, height: 56),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def?.name ?? card.cardId,
                        style: AppText.titleSm(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        'PSA ${grade.toStringAsFixed(grade == grade.roundToDouble() ? 0 : 1)}',
                        style: AppText.bodySm(),
                      ),
                    ],
                  ),
                ),
                AppChip(
                  label: 'Rent',
                  selected: true,
                  compact: true,
                  onTap: onRent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
