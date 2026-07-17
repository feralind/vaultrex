import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding.dart';
import '../data/riftbound_catalog.dart';
import '../game/game_controller.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/cash_top_up_sheet.dart';
import 'sealed_inventory.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPokemon =
        ref.watch(gameProvider.select((s) => s.franchiseId)) == 'pokemon';
    final franchise = isPokemon ? 'Pokémon' : 'Riftbound';
    final packBlurb = isPokemon
        ? 'Rip Scarlet & Violet–era packs with real street pricing.'
        : 'Rip Origins, Spiritforged, and Unleashed packs with real street pricing.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'Discover',
          style: AppText.jakarta(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$franchise drops, trends, and collector tips.',
          style: AppText.jakarta(color: CC.inkMuted),
        ),
        const SizedBox(height: 18),
        Builder(
          builder: (context) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showSealedInventory(context),
                borderRadius: BorderRadius.circular(16),
                child: _banner(
                  title: 'Sealed inventory',
                  body:
                      'Boxes land here sealed. Open packs when you want — or sell them back.',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _banner(
          title: 'Instapacks are live',
          body: packBlurb,
          color: CC.accent,
        ),
        const SizedBox(height: 12),
        _banner(
          title: 'Track every pull',
          body: 'Foil, centering, condition, and slab grades — all in your Collection.',
          color: const Color(0xFF22D3EE),
        ),
        const SizedBox(height: 12),
        _banner(
          title: 'List online',
          body: 'Price your cards and let simulated buyers fill over time.',
          color: CC.candy,
        ),
      ],
    );
  }

  Widget _banner({
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CC.line),
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [color.withValues(alpha: 0.18), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.jakarta(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppText.jakarta(
              color: CC.inkMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cash = ref.watch(gameProvider.select((s) => s.player.cash));
    final candy = ref.watch(gameProvider.select((s) => s.player.candy));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: AppText.jakarta(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CC.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Wallet',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Top up simulated cash anytime. Large amounts are… encouraged. 😉',
                style: AppText.jakarta(
                  color: CC.inkMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CashBalance(cash),
                  const SizedBox(width: 8),
                  CandyBalance(candy),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => showCashTopUp(context, ref),
                  icon: const Icon(Icons.add_card_outlined, size: 18),
                  label: Text(
                    'Top up with Google Pay',
                    style: AppText.jakarta(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: CC.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: CC.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Advance day'),
          subtitle: const Text('Restock Instapacks & resolve listings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ref.read(gameProvider.notifier).advanceDay(),
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: CC.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Replay intro'),
          onTap: () async {
            await OnboardingStore.reset();
            GameCatalog.clearCache();
            if (context.mounted) {
              // Parent shell watches onboarding via restart — show snack.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restart the app to see onboarding again.')),
              );
            }
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Legal',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Vaultrex is a personal offline collecting/market sim. '
          'Riftbound names and related IP belong to Riot Games. '
          'Pokémon and Pokémon TCG names/marks belong to Nintendo / Creatures / Game Freak / The Pokémon Company. '
          'Prices from TCGCSV/TCGplayer public data. '
          'Not affiliated with those rights holders.',
          style: AppText.jakarta(
            color: CC.inkMuted,
            height: 1.45,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
