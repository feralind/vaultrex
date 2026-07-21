import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/unified_collection.dart';
import '../game/game_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/card_detail_sheet.dart';
import '../widgets/game_widgets.dart';
import '../widgets/portfolio_value_chart.dart';
import '../widgets/ui_kit.dart';
import 'binder_room_screen.dart';
import 'create_binder_sheet.dart';
import 'engagement/engagement_hub.dart';
import 'flip_layout.dart';
import 'sealed_inventory.dart';

enum _CardSort {
  valueDesc,
  valueAsc,
  nameAsc,
  rarityDesc,
  foilFirst,
}

extension on _CardSort {
  String get label => switch (this) {
        _CardSort.valueDesc => 'Value ↓',
        _CardSort.valueAsc => 'Value ↑',
        _CardSort.nameAsc => 'Name',
        _CardSort.rarityDesc => 'Rarity',
        _CardSort.foilFirst => 'Foil first',
      };
}

int _rarityRank(Rarity r) => switch (r) {
      Rarity.ultimate => 100,
      Rarity.signature => 90,
      Rarity.overnumbered => 80,
      Rarity.showcase => 70,
      Rarity.epic => 60,
      Rarity.promo => 55,
      Rarity.rare => 50,
      Rarity.uncommon => 40,
      Rarity.common => 30,
      Rarity.token => 10,
      Rarity.none => 0,
    };

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  /// `ALL` or franchise id.
  String _franchise = 'ALL';
  /// `ALL` or `franchiseId::setCode`.
  String _set = 'ALL';
  String _query = '';
  _CardSort _sort = _CardSort.valueDesc;
  int _tabIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this, initialIndex: 1);
    _tabIndex = _tabs.index;
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      if (_tabIndex != _tabs.index) {
        setState(() => _tabIndex = _tabs.index);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final async = ref.watch(unifiedCollectionProvider);
    if (!state.ready) {
      return const Center(child: CircularProgressIndicator(color: CC.accent));
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: CC.accent)),
      error: (e, _) => Center(
        child: Text('Could not load collections: $e',
            style: AppText.jakarta(color: CC.inkMuted)),
      ),
      data: (snap) {
        final scopedCards = snap.cardsForFranchise(_franchise);
        final unique = scopedCards.map((c) => c.owned.cardId).toSet().length;
        final value = scopedCards.fold<double>(0, (s, e) => s + e.fair);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: CC.scan, width: 2),
                      color: CC.cardSoft,
                    ),
                    child: const Icon(Icons.person, color: CC.inkMuted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collector',
                          style: AppText.jakarta(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          _franchise == 'ALL'
                              ? 'All franchises'
                              : '${franchiseLabel(_franchise)} collection',
                          style: AppText.jakarta(
                            color: CC.inkMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$unique cards',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '\$${value.toStringAsFixed(2)} value',
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _FranchiseChip(
                    label: 'All',
                    selected: _franchise == 'ALL',
                    onTap: () => setState(() {
                      _franchise = 'ALL';
                      _set = 'ALL';
                    }),
                  ),
                  for (final id in kCollectionFranchiseIds)
                    _FranchiseChip(
                      label: franchiseLabel(id),
                      selected: _franchise == id,
                      onTap: () => setState(() {
                        _franchise = id;
                        _set = 'ALL';
                      }),
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: CC.ink,
              indicatorWeight: 3,
              labelColor: CC.ink,
              unselectedLabelColor: CC.inkMuted,
              labelStyle:
                  AppText.jakarta(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle:
                  AppText.jakarta(fontWeight: FontWeight.w500, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Insights'),
                Tab(text: 'Collection'),
                Tab(text: 'Sets'),
                Tab(text: 'Binders'),
                Tab(text: 'Vault'),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                child: KeyedSubtree(
                  key: ValueKey('$_tabIndex|$_franchise|$_sort'),
                  child: switch (_tabIndex) {
                    0 => _InsightsTab(value: value, count: unique),
                    1 => _CardsTab(
                        snap: snap,
                        franchise: _franchise,
                        set: _set,
                        query: _query,
                        sort: _sort,
                        onSet: (s) => setState(() => _set = s),
                        onQuery: (q) => setState(() => _query = q),
                        onSort: (s) => setState(() => _sort = s),
                      ),
                    2 => _SetsTab(snap: snap, franchise: _franchise),
                    3 => const _BindersTab(),
                    _ => const _VaultTab(),
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FranchiseChip extends StatelessWidget {
  const _FranchiseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      selected: selected,
      onTap: onTap,
      compact: true,
    );
  }
}

class _InsightsTab extends ConsumerWidget {
  const _InsightsTab({required this.value, required this.count});
  final double value;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(gameProvider.select((s) => s.valueHistory));
    final series = PortfolioValueChart.seriesForDisplay(
      history,
      currentValue: value,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'Your collection',
          style: AppText.display(),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) {
            return Text(
              '\$${v.toStringAsFixed(2)}',
              style: AppText.display().copyWith(fontSize: 36, letterSpacing: -1),
            );
          },
        ),
        Text(
          '$count unique cards across selected franchises',
          style: AppText.bodySm(),
        ),
        const SizedBox(height: 18),
        PortfolioValueChart(points: series, height: 172),
        const SizedBox(height: 16),
        const SealedInventoryBanner(),
      ],
    );
  }
}

class _CardsTab extends ConsumerWidget {
  const _CardsTab({
    required this.snap,
    required this.franchise,
    required this.set,
    required this.query,
    required this.sort,
    required this.onSet,
    required this.onQuery,
    required this.onSort,
  });

  final UnifiedCollectionSnapshot snap;
  final String franchise;
  final String set;
  final String query;
  final _CardSort sort;
  final ValueChanged<String> onSet;
  final ValueChanged<String> onQuery;
  final ValueChanged<_CardSort> onSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var filtered = snap.cardsForFranchise(franchise).where((e) {
      if (set != 'ALL') {
        if (franchise == 'ALL') {
          if ('${e.franchiseId}::${e.def.setCode}' != set) return false;
        } else if (e.def.setCode != set) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final hay =
            '${e.def.name} ${e.def.setCode} ${e.def.setName} ${e.def.number ?? ''}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    filtered = [...filtered];
    switch (sort) {
      case _CardSort.valueDesc:
        filtered.sort((a, b) => b.fair.compareTo(a.fair));
      case _CardSort.valueAsc:
        filtered.sort((a, b) => a.fair.compareTo(b.fair));
      case _CardSort.nameAsc:
        filtered.sort(
          (a, b) => a.def.name.toLowerCase().compareTo(b.def.name.toLowerCase()),
        );
      case _CardSort.rarityDesc:
        filtered.sort((a, b) {
          final c = _rarityRank(b.def.rarity).compareTo(_rarityRank(a.def.rarity));
          return c != 0 ? c : b.fair.compareTo(a.fair);
        });
      case _CardSort.foilFirst:
        filtered.sort((a, b) {
          final c = (b.owned.foil ? 1 : 0).compareTo(a.owned.foil ? 1 : 0);
          return c != 0 ? c : b.fair.compareTo(a.fair);
        });
    }

    final setsScoped = snap.setsForFranchise(franchise);
    final chipSets = <({String value, String label})>[
      (value: 'ALL', label: 'ALL'),
      ...setsScoped.map((s) {
        final value = franchise == 'ALL'
            ? '${s.franchiseId}::${s.setCode}'
            : s.setCode;
        final label = franchise == 'ALL'
            ? '${s.setCode} · ${switch (s.franchiseId) {
                'pokemon' => 'PK',
                'mtg' => 'MTG',
                'onepiece' => 'OP',
                _ => 'RB',
              }}'
            : s.setCode;
        return (value: value, label: label);
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'All cards',
            style: AppText.display(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onQuery,
                  style: AppText.jakarta(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search cards',
                    hintStyle: AppText.jakarta(color: CC.inkMuted),
                    prefixIcon: const Icon(Icons.search, color: CC.inkMuted),
                    filled: true,
                    fillColor: CC.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_CardSort>(
                tooltip: 'Sort',
                initialValue: sort,
                onSelected: onSort,
                itemBuilder: (context) => _CardSort.values
                    .map(
                      (s) => PopupMenuItem(
                        value: s,
                        child: Text(s.label),
                      ),
                    )
                    .toList(),
                child: _SquareIcon(Icons.swap_vert),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: chipSets
                .map(
                  (s) => AppChip(
                    label: s.label,
                    selected: set == s.value,
                    onTap: () => onSet(s.value),
                    compact: true,
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(
            '${filtered.length} shown · ${sort.label}',
            style: AppText.jakarta(color: CC.inkMuted, fontSize: 11),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No cards yet',
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Open Instapacks in any franchise to add cards.',
                        style: AppText.jakarta(color: CC.inkMuted),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 88),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: FlipLayout.collectionCrossAxisCount(context),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 10,
                    childAspectRatio:
                        FlipLayout.collectionAspectRatio(context),
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final entry = filtered[i];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        OwnedCardTile(
                          def: entry.def,
                          owned: entry.owned,
                          fair: entry.fair,
                          onTap: () => _detail(context, ref, entry),
                        ),
                        if (franchise == 'ALL')
                          Positioned(
                            left: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CC.bg.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                franchiseLabel(entry.franchiseId) == 'Pokémon'
                                    ? 'PK'
                                    : franchiseLabel(entry.franchiseId) ==
                                            'Magic'
                                        ? 'MT'
                                        : franchiseLabel(entry.franchiseId) ==
                                                'One Piece'
                                            ? 'OP'
                                            : 'RB',
                                style: AppText.jakarta(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _detail(
    BuildContext context,
    WidgetRef ref,
    UnifiedCardEntry entry,
  ) async {
    final notifier = ref.read(gameProvider.notifier);
    if (notifier.activeGameId != entry.franchiseId) {
      await notifier.switchFranchise(entry.franchiseId);
      if (!context.mounted) return;
    }
    final state = ref.read(gameProvider);
    final owned = state.collection.cast<OwnedCard?>().firstWhere(
          (c) => c?.instanceId == entry.owned.instanceId,
          orElse: () => entry.owned,
        )!;
    final fair = notifier.fairFor(owned);
    final def = notifier.cardById(owned.cardId) ?? entry.def;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CC.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CardDetailSheet.owned(
          owned: owned,
          def: def,
          allMarket: state.market,
          fairPrice: fair,
          suggestedAsk: notifier.suggestedAskFor(owned),
          onListForSale: (ask) => notifier.listOnline(owned.instanceId, ask),
          onQuickFlip: () => notifier.quickFlipCard(owned.instanceId),
          onCancelListing: () async {
            OnlineListing? match;
            for (final l in ref.read(gameProvider).onlineListings) {
              if (l.ownedInstanceId == owned.instanceId) {
                match = l;
                break;
              }
            }
            if (match != null) {
              await notifier.cancelOnlineListing(match.id);
            }
          },
          onSendToPsa: null,
        );
      },
    );
    ref.invalidate(unifiedCollectionProvider);
  }
}

class _SetsTab extends ConsumerWidget {
  const _SetsTab({required this.snap, required this.franchise});

  final UnifiedCollectionSnapshot snap;
  final String franchise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = [...snap.setsForFranchise(franchise)]
      ..sort((a, b) {
        final byGame = a.franchiseId.compareTo(b.franchiseId);
        if (byGame != 0) return byGame;
        return a.setCode.compareTo(b.setCode);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const OneAwayBanner(),
        if (franchise == 'ALL')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Every set across Riftbound, Pokémon, and Magic.',
              style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
            ),
          ),
        ...sets.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: CC.card,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SetCompletionGridScreen(
                        setCode: s.setCode,
                        franchiseId: s.franchiseId,
                        cards: s.cards,
                        ownedUnique: s.ownedUnique,
                      ),
                    ),
                  );
                  ref.read(gameProvider.notifier).checkSetMilestones();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CC.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.setName,
                              style: AppText.jakarta(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            franchiseLabel(s.franchiseId),
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
                        '${s.setCode} · ${s.ownedUnique} / ${s.total}',
                        style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: s.pct,
                          minHeight: 6,
                          backgroundColor: CC.cardSoft,
                          color: CC.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _BindersTab extends ConsumerWidget {
  const _BindersTab();

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final result = await showCreateBinderSheet(context);
    if (result == null) return;
    await ref.read(gameProvider.notifier).createBinder(
          name: result.name,
          colorHex: result.colorHex,
          isPrivate: result.isPrivate,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binders = ref.watch(gameProvider.select((s) => s.binders));
    const createSlots = 4;
    final itemCount = binders.length + createSlots;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (i < binders.length) {
          return _BinderTile(binder: binders[i]);
        }
        return _CreateNewBinderTile(onTap: () => _openCreate(context, ref));
      },
    );
  }
}

class _CreateNewBinderTile extends StatelessWidget {
  const _CreateNewBinderTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CC.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CC.line.withValues(alpha: 0.9)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New',
                style: AppText.jakarta(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Center(
                child: Icon(Icons.add, size: 56, color: CC.ink),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BinderTile extends StatelessWidget {
  const _BinderTile({required this.binder});
  final Binder binder;

  @override
  Widget build(BuildContext context) {
    final color = Color(binder.colorHex);
    return Material(
      color: CC.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BinderRoomScreen(binderId: binder.id),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CC.line.withValues(alpha: 0.9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.4)!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (binder.isPrivate)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child:
                              Icon(Icons.lock, size: 14, color: Colors.white70),
                        ),
                      Center(
                        child: Icon(
                          Icons.collections_bookmark_outlined,
                          size: 36,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        binder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.jakarta(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${binder.cardCount} card${binder.cardCount == 1 ? '' : 's'}',
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultTab extends ConsumerWidget {
  const _VaultTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final total = state.unopened.length;
    final groups = buildSealedPackGroups(state, notifier);
    final mv = sealedInventoryMarketValue(state, notifier);
    final packCount = groups
        .where((g) => !g.fromBox)
        .fold<int>(0, (sum, g) => sum + g.packs.length);
    final boxPackCount = groups
        .where((g) => g.fromBox)
        .fold<int>(0, (sum, g) => sum + g.packs.length);
    final boxLots = groups.where((g) => g.fromBox).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'Vault',
          style: AppText.jakarta(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? 'Sealed product you own stays here until you rip or sell it.'
              : '$total sealed · rough MV \$${mv.toStringAsFixed(2)}',
          style: AppText.jakarta(
            color: CC.inkMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (total > 0) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _VaultChip(
                label: '$total pack${total == 1 ? '' : 's'}',
                icon: Icons.style_outlined,
              ),
              if (boxLots > 0)
                _VaultChip(
                  label: boxPackCount == total
                      ? '$boxLots box lot${boxLots == 1 ? '' : 's'}'
                      : '$boxPackCount from boxes · $packCount loose',
                  icon: Icons.inventory_2_outlined,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SealedInventoryBody(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            emptyMessage: 'Vault is empty.',
          ),
        ] else ...[
          const SizedBox(height: 28),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: CC.inkMuted.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No sealed product yet.\nBuy Instapacks or booster boxes — they land here sealed.',
                    textAlign: TextAlign.center,
                    style: AppText.jakarta(
                      color: CC.inkMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Tip: booster boxes go straight to inventory — they never auto-open.',
          style: AppText.jakarta(
            color: CC.inkMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _VaultChip extends StatelessWidget {
  const _VaultChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CC.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: CC.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.jakarta(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CC.line),
      ),
      child: Icon(icon, color: CC.inkMuted, size: 20),
    );
  }
}

