import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/card_detail_sheet.dart';
import '../widgets/game_widgets.dart';
import '../widgets/portfolio_value_chart.dart';
import 'create_binder_sheet.dart';
import 'flip_layout.dart';
import 'sealed_inventory.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _set = 'ALL';
  String _query = '';
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
    final notifier = ref.read(gameProvider.notifier);
    if (!state.ready) {
      return const Center(child: CircularProgressIndicator(color: CC.accent));
    }

    double value = 0;
    for (final o in state.collection) {
      value += notifier.fairFor(o);
    }
    final unique = state.collection.map((c) => c.cardId).toSet().length;

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
                      notifier.activeGameId == 'pokemon'
                          ? 'Pokémon collection'
                          : notifier.activeGameId == 'mtg'
                              ? 'Magic collection'
                              : 'Riftbound collection',
                      style: AppText.jakarta(
                        color: CC.inkMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.edit_note, size: 16, color: CC.inkMuted),
                        const SizedBox(width: 8),
                        Icon(Icons.ios_share, size: 16, color: CC.inkMuted),
                      ],
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
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: CC.ink,
          indicatorWeight: 3,
          labelColor: CC.ink,
          unselectedLabelColor: CC.inkMuted,
          labelStyle: AppText.jakarta(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: AppText.jakarta(fontWeight: FontWeight.w500, fontSize: 14),
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
              key: ValueKey(_tabIndex),
              child: switch (_tabIndex) {
                0 => _InsightsTab(value: value, count: unique),
                1 => _CardsTab(
                    set: _set,
                    query: _query,
                    onSet: (s) => setState(() => _set = s),
                    onQuery: (q) => setState(() => _query = q),
                  ),
                2 => _SetsTab(),
                3 => const _BindersTab(),
                _ => const _VaultTab(),
              },
            ),
          ),
        ),
      ],
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
          style: AppText.jakarta(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) {
            return Text(
              '\$${v.toStringAsFixed(2)}',
              style: AppText.jakarta(
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        PortfolioValueChart(points: series, height: 172),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _InsightStat(
                label: 'Unique cards',
                value: '$count',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InsightStat(
                label: 'Tracked days',
                value: '${history.isEmpty ? 1 : history.length}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightStat extends StatelessWidget {
  const _InsightStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CC.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.jakarta(
              color: CC.inkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppText.jakarta(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
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
    // Always keep several Create New slots visible (Rare Candy–style grid).
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
    return Container(
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CC.line.withValues(alpha: 0.9)),
      ),
      clipBehavior: Clip.antiAlias,
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
                      child: Icon(Icons.lock, size: 14, color: Colors.white70),
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
    );
  }
}

class _CardsTab extends ConsumerWidget {
  const _CardsTab({
    required this.set,
    required this.query,
    required this.onSet,
    required this.onQuery,
  });

  final String set;
  final String query;
  final ValueChanged<String> onSet;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final filtered = state.collection.where((o) {
      final def = notifier.cardById(o.cardId);
      if (def == null) return false;
      if (set != 'ALL' && def.setCode != set) return false;
      if (query.isNotEmpty &&
          !def.name.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final setCodes = notifier.catalog.bySet.keys.toList()..sort();
    final chipSets = ['ALL', ...setCodes];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'All cards',
            style: AppText.jakarta(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
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
              _SquareIcon(Icons.swap_vert),
              const SizedBox(width: 8),
              _SquareIcon(Icons.tune),
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
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: set == s,
                      onSelected: (_) => onSet(s),
                      selectedColor: CC.accent.withValues(alpha: 0.25),
                      backgroundColor: CC.card,
                      labelStyle: AppText.jakarta(
                        fontWeight: FontWeight.w600,
                        color: CC.ink,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: set == s ? CC.accent : CC.line),
                    ),
                  ),
                )
                .toList(),
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
                        'Open Instapacks to add cards here.',
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
                    final owned = filtered[i];
                    final def = notifier.cardById(owned.cardId)!;
                    return OwnedCardTile(
                      def: def,
                      owned: owned,
                      fair: notifier.fairFor(owned),
                      onTap: () => _detail(context, ref, owned, def),
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
    OwnedCard owned,
    CardDef def,
  ) async {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.read(gameProvider);
    final fair = notifier.fairFor(owned);
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
  }
}

class _SetsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (!state.ready) return const SizedBox.shrink();
    final sets = notifier.catalog.isPokemon
        ? notifier.catalog.bySet.keys.toList()
        : notifier.catalog.isMtg
            ? notifier.catalog.bySet.keys.toList()
            : ['OGS', 'OGN', 'SFD', 'UNL'];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final code = sets[i];
        final all = notifier.catalog.bySet[code] ?? [];
        final owned = state.collection
            .where((c) => notifier.cardById(c.cardId)?.setCode == code)
            .map((c) => c.cardId)
            .toSet()
            .length;
        final name = all.isNotEmpty ? all.first.setName : code;
        final pct = all.isEmpty ? 0.0 : owned / all.length;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CC.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CC.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppText.jakarta(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '$owned / ${all.length}',
                style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: CC.cardSoft,
                  color: CC.accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: CC.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: CC.inkMuted, size: 20),
    );
  }
}

class _VaultTab extends StatelessWidget {
  const _VaultTab();

  @override
  Widget build(BuildContext context) {
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
          'Sealed product you own stays here until you rip or sell it.',
          style: AppText.jakarta(
            color: CC.inkMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        const SealedInventoryBanner(),
        const SizedBox(height: 12),
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
