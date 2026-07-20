import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/pack_theater_v2.dart';

Future<void> showSealedInventory(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SealedInventorySheet(),
  );
}

/// Groups unopened packs by sealed product (or set when product missing).
class SealedPackGroup {
  SealedPackGroup({
    required this.key,
    required this.setCode,
    required this.title,
    required this.imageUrl,
    required this.packs,
    required this.sellCash,
    required this.fromBox,
  });

  final String key;
  final String setCode;
  final String title;
  final String? imageUrl;
  final List<UnopenedPack> packs;
  final double sellCash;
  final bool fromBox;
}

List<SealedPackGroup> buildSealedPackGroups(
  GameState state,
  GameNotifier notifier,
) {
  final map = <String, List<UnopenedPack>>{};
  for (final p in state.unopened) {
    map.putIfAbsent(p.sealedProductId, () => []).add(p);
  }
  final out = <SealedPackGroup>[];
  for (final entry in map.entries) {
    final packs = entry.value;
    final product = notifier.sealedById(entry.key);
    final setCode = packs.first.setCode;
    String title;
    String? imageUrl;
    var fromBox = false;
    if (product != null) {
      fromBox = product.kind == SealedKind.box;
      title = product.kind == SealedKind.box
          ? '${product.setName} packs'
          : product.name
              .replaceFirst(RegExp(r'^.*? - '), '')
              .replaceAll('Booster ', '');
      imageUrl =
          product.displayArtUrl.isNotEmpty ? product.displayArtUrl : null;
      // Prefer a pack image when inventory came from a box product.
      if (product.kind == SealedKind.box) {
        try {
          final packArt = notifier.catalog.sealed.firstWhere(
            (s) => s.setCode == setCode && s.kind == SealedKind.pack,
          );
          if (packArt.displayArtUrl.isNotEmpty) {
            imageUrl = packArt.displayArtUrl;
          }
        } catch (_) {}
      }
    } else {
      title = '$setCode packs';
      imageUrl = null;
    }
    out.add(SealedPackGroup(
      key: entry.key,
      setCode: setCode,
      title: title,
      imageUrl: imageUrl,
      packs: packs,
      sellCash: notifier.sealedPackSellCash(packs.first),
      fromBox: fromBox,
    ));
  }
  out.sort((a, b) => b.packs.length.compareTo(a.packs.length));
  return out;
}

List<Color> sealedColorsFor(String code) {
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

double sealedInventoryMarketValue(
  GameState state,
  GameNotifier notifier,
) {
  var total = 0.0;
  for (final p in state.unopened) {
    total += notifier.sealedPackMarketValue(p);
  }
  return total;
}

class SealedInventorySheet extends ConsumerWidget {
  const SealedInventorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final total = state.unopened.length;
    final h = MediaQuery.sizeOf(context).height;

    return Container(
      height: h * 0.88,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sealed inventory',
                        style: AppText.jakarta(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total == 0
                            ? 'Buy packs or boxes — they land here sealed.'
                            : '$total sealed pack${total == 1 ? '' : 's'} ready to rip',
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: SealedInventoryBody(
              popSheetBeforeOpen: true,
              emptyMessage:
                  'No sealed packs yet.\nGrab an Instapack or booster box.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable sealed list (Open / Sell) for the inventory sheet and Vault tab.
class SealedInventoryBody extends ConsumerStatefulWidget {
  const SealedInventoryBody({
    super.key,
    this.popSheetBeforeOpen = false,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 28),
    this.emptyMessage =
        'No sealed packs yet.\nGrab an Instapack or booster box.',
    this.shrinkWrap = false,
    this.physics,
  });

  /// When true (sheet), close the bottom sheet before launching pack theater.
  final bool popSheetBeforeOpen;
  final EdgeInsetsGeometry padding;
  final String emptyMessage;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  ConsumerState<SealedInventoryBody> createState() =>
      _SealedInventoryBodyState();
}

class _SealedInventoryBodyState extends ConsumerState<SealedInventoryBody> {
  bool _busy = false;

  Future<void> _openOne(SealedPackGroup group) async {
    if (_busy) return;
    final state = ref.read(gameProvider);
    if (state.lastRip?.isNotEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish current rip first.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final pack = group.packs.first;
      final imageUrl = group.imageUrl;
      final navContext = widget.popSheetBeforeOpen
          ? Navigator.of(context, rootNavigator: true).context
          : context;
      if (widget.popSheetBeforeOpen) {
        Navigator.pop(context);
        await Future<void>.delayed(Duration.zero);
      }
      if (!navContext.mounted) return;
      await showPackTheaterV2(
        navContext,
        ref,
        packId: pack.id,
        packImageUrl: imageUrl,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sellOne(SealedPackGroup group) async {
    final pack = group.packs.first;
    final cash = group.sellCash;
    final candy = (cash * 100).round();
    final choice = await showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: CC.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sell sealed pack',
              style: AppText.jakarta(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Refund ~80% of market value.',
              style: AppText.jakarta(
                color: CC.inkMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, PaymentMethod.cash),
              child: Text('Sell for \$${cash.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, PaymentMethod.candy),
              style: OutlinedButton.styleFrom(
                foregroundColor: CC.candy,
                side: const BorderSide(color: CC.candy),
                minimumSize: const Size.fromHeight(48),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cookie, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sell for $candy Candy',
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await ref.read(gameProvider.notifier).sellUnopenedPack(
          pack.id,
          refundAs: choice,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final groups = buildSealedPackGroups(state, notifier);
    final total = state.unopened.length;

    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            widget.emptyMessage,
            textAlign: TextAlign.center,
            style: AppText.jakarta(
              color: CC.inkMuted,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final g = groups[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CC.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CC.line),
          ),
          child: Row(
            children: [
              PackVisual(
                title: g.setCode,
                imageUrl: g.imageUrl,
                colors: sealedColorsFor(g.setCode),
                width: 64,
                height: 92,
                franchiseId: ref.watch(
                  gameProvider.select((s) => s.franchiseId),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${g.packs.length} sealed · ${g.setCode}',
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sell ~\$${g.sellCash.toStringAsFixed(2)}',
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: FilledButton(
                              onPressed: _busy ? null : () => _openOne(g),
                              child: Text(
                                'Open',
                                style: AppText.jakarta(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: _busy ? null : () => _sellOne(g),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CC.candy,
                                side: const BorderSide(
                                  color: CC.candy,
                                ),
                              ),
                              child: Text(
                                'Sell',
                                style: AppText.jakarta(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact banner used on Instapacks / Collection to open inventory.
class SealedInventoryBanner extends ConsumerWidget {
  const SealedInventoryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(gameProvider.select((s) => s.unopened.length));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showSealedInventory(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CC.line),
            gradient: LinearGradient(
              colors: [
                CC.accent.withValues(alpha: 0.18),
                CC.candy.withValues(alpha: 0.10),
                CC.card,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: CC.bgElevated.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CC.line),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: CC.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sealed inventory',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count == 0
                            ? 'Boxes & packs you buy stay sealed here'
                            : '$count pack${count == 1 ? '' : 's'} ready — Open or Sell',
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: CC.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: AppText.jakarta(
                        fontWeight: FontWeight.w800,
                        color: CC.accent,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: CC.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
