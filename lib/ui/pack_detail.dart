import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/fake_google_pay_sheet.dart';
import '../widgets/game_widgets.dart';
import '../widgets/pack_theater_v2.dart';
import 'sealed_inventory.dart';

Future<void> showPackDetail(
  BuildContext context,
  WidgetRef ref, {
  required SealedProduct product,
  required SealedListing listing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PackDetailSheet(product: product, listing: listing),
  );
}

class _PackDetailSheet extends ConsumerStatefulWidget {
  const _PackDetailSheet({required this.product, required this.listing});

  final SealedProduct product;
  final SealedListing listing;

  @override
  ConsumerState<_PackDetailSheet> createState() => _PackDetailSheetState();
}

class _PackDetailSheetState extends ConsumerState<_PackDetailSheet> {
  bool _busy = false;

  SealedProduct get product => widget.product;
  SealedListing get listing => widget.listing;

  List<CardDef> _topHits(GameNotifier notifier) {
    final pool = notifier.catalog.bySet[product.setCode] ?? const <CardDef>[];
    final ranked = [...pool]..sort((a, b) => b.marketPrice.compareTo(a.marketPrice));
    return ranked.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final soldOut = listing.stock <= 0;
    final candyCost = (listing.price * 100).round();
    final hits = _topHits(notifier);
    final h = MediaQuery.sizeOf(context).height;
    final art = product.displayArtUrl;

    return Container(
      height: h * 0.92,
      decoration: const BoxDecoration(
        color: CC.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CC.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              children: [
                Center(
                  child: PackVisual(
                    title: product.setCode,
                    imageUrl: art.isEmpty ? null : art,
                    colors: _colorsFor(product.setCode),
                    width: 168,
                    height: 240,
                    franchiseId:
                        ref.watch(gameProvider.select((s) => s.franchiseId)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: AppText.jakarta(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.kind == SealedKind.box
                      ? 'Booster box · ${product.packsPerBox ?? 24} packs'
                      : switch (ref.watch(
                          gameProvider.select((s) => s.franchiseId),
                        )) {
                          'pokemon' =>
                            'Digital Instapack · real Pokémon pulls',
                          'mtg' => 'Digital Instapack · real Magic pulls',
                          'onepiece' =>
                            'Digital Instapack · real One Piece pulls',
                          'yugioh' =>
                            'Digital Instapack · real Yu-Gi-Oh! pulls',
                          'gundam' =>
                            'Digital Instapack · real Gundam pulls',
                          _ => 'Digital Instapack · real Riftbound pulls',
                        },
                  textAlign: TextAlign.center,
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Top hits',
                  style: AppText.jakarta(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chase cards that can appear from this set.',
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ShowcaseCardRow(
                  itemCount: hits.length,
                  itemBuilder: (context, i) {
                    final c = hits[i];
                    const cardW = 168.0;
                    const cardH = cardW * (3.5 / 2.5);
                    return SizedBox(
                      width: cardW,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CardArt(
                            url: c.displayArtUrl,
                            autoPlay: false,
                            width: cardW,
                            height: cardH,
                            radius: 12,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppText.jakarta(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  product.kind == SealedKind.box
                      ? 'Booster boxes add sealed packs to your inventory. '
                          'Open them anytime from Sealed inventory.'
                      : 'Rip the pack, flip every card, then Keep it for your binder '
                          'or Exchange it for Candy.',
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: soldOut
                ? FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      backgroundColor: CC.soldOut,
                      disabledBackgroundColor: CC.soldOut,
                    ),
                    child: const Text('SOLD OUT'),
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ||
                                  notifier.isShopBusy ||
                                  state.player.cash < listing.price
                              ? null
                              : () => _buy(PaymentMethod.cash),
                          child: Text(
                            'BUY NOW  ·  \$${listing.price.toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _busy ||
                                  notifier.isShopBusy ||
                                  state.player.candy < candyCost
                              ? null
                              : () => _buy(PaymentMethod.candy),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CC.candy,
                            side: const BorderSide(color: CC.candy),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cookie, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'BUY WITH  ${_fmtCandy(candyCost)} CANDY',
                                style: AppText.jakarta(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(PaymentMethod method) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final notifier = ref.read(gameProvider.notifier);
      final before = ref.read(gameProvider).unopened.length;
      // Capture a Navigator-hosted context BEFORE popping the sheet.
      // ScaffoldMessenger.context sits above the Navigator and cannot push dialogs —
      // that was silently killing the pack theater after payment.
      final navContext = Navigator.of(context, rootNavigator: true).context;
      if (method == PaymentMethod.cash) {
        final paid = await showFakeGooglePay(context, amount: listing.price);
        if (!paid || !mounted) return;
      }
      await notifier.buySealed(listing.id, payWith: method);
      if (!mounted) return;
      final afterState = ref.read(gameProvider);
      final after = afterState.unopened.length;
      if (after <= before) {
        final msg = afterState.message ?? 'Purchase failed.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      final isRipPack = product.kind == SealedKind.pack;
      final art = product.displayArtUrl.isNotEmpty ? product.displayArtUrl : null;
      final added = after - before;
      // Newly purchased packs are appended — rip the first new one.
      final newPackId = afterState.unopened[before].id;
      Navigator.pop(context);

      // Boxes / decks / kits land in sealed inventory — do not auto-open theater.
      if (!isRipPack) {
        if (!navContext.mounted) return;
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(
              product.kind == SealedKind.box
                  ? 'Added $added sealed packs to inventory. Open them anytime.'
                  : 'Added to sealed inventory. Open or sell anytime.',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                if (navContext.mounted) showSealedInventory(navContext);
              },
            ),
          ),
        );
        return;
      }

      // Single pack: open rip theater after the sheet has dismissed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!navContext.mounted) return;
        showPackTheaterV2(
          navContext,
          ref,
          packId: newPackId,
          packImageUrl: art,
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _fmtCandy(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    return '$n';
  }

  static List<Color> _colorsFor(String code) {
    switch (code) {
      case 'OGN':
        return const [Color(0xFFFDE68A), Color(0xFFB45309)];
      case 'SFD':
        return const [Color(0xFF86EFAC), Color(0xFF166534)];
      case 'UNL':
        return const [Color(0xFF93C5FD), Color(0xFF1E3A8A)];
      default:
        return const [Color(0xFFE2E8F0), Color(0xFF475569)];
    }
  }
}
