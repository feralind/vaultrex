import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';
import '../models/models.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/card_inspect_page.dart';
import '../widgets/game_widgets.dart';

/// Full-screen binder pages with 3×3 pockets.
class BinderRoomScreen extends ConsumerStatefulWidget {
  const BinderRoomScreen({super.key, required this.binderId});

  final String binderId;

  @override
  ConsumerState<BinderRoomScreen> createState() => _BinderRoomScreenState();
}

class _BinderRoomScreenState extends ConsumerState<BinderRoomScreen> {
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Binder? _binder(GameState state) {
    for (final b in state.binders) {
      if (b.id == widget.binderId) return b;
    }
    return null;
  }

  Set<String> _boundIds(GameState state) {
    final out = <String>{};
    for (final b in state.binders) {
      out.addAll(b.cardInstanceIds);
    }
    return out;
  }

  Future<void> _rename(Binder binder) async {
    final ctrl = TextEditingController(text: binder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CC.bgElevated,
        title: Text(
          'Rename binder',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Binder name',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    await ref.read(gameProvider.notifier).renameBinder(binder.id, name);
  }

  Future<void> _delete(Binder binder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CC.bgElevated,
        title: Text(
          'Delete binder?',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '“${binder.name}” will be removed. Cards stay in your collection.',
          style: AppText.jakarta(color: CC.inkMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(gameProvider.notifier).deleteBinder(binder.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickCard(Binder binder) async {
    final state = ref.read(gameProvider);
    final bound = _boundIds(state);
    final available = state.collection
        .where((c) => !bound.contains(c.instanceId))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unbound cards in collection.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BinderCardPickerSheet(available: available),
    );
    if (picked == null || !mounted) return;
    final ok = await ref
        .read(gameProvider.notifier)
        .addCardToBinder(binder.id, picked);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add that card.')),
      );
    }
  }

  Future<void> _inspect(OwnedCard owned) async {
    final notifier = ref.read(gameProvider.notifier);
    final def = notifier.cardById(owned.cardId);
    if (def == null) return;
    await openCardInspect(
      context,
      def: def,
      foil: owned.foil,
      grade: owned.grade,
      company: owned.gradingCompany,
    );
  }

  Future<void> _remove(Binder binder, String instanceId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CC.bgElevated,
        title: Text(
          'Remove from binder?',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'The card stays in your collection.',
          style: AppText.jakarta(color: CC.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref
        .read(gameProvider.notifier)
        .removeCardFromBinder(binder.id, instanceId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final binder = _binder(state);
    if (binder == null) {
      return Scaffold(
        backgroundColor: CC.bg,
        appBar: AppBar(title: const Text('Binder')),
        body: Center(
          child: Text(
            'Binder not found.',
            style: AppText.jakarta(color: CC.inkMuted),
          ),
        ),
      );
    }

    final pageCount = math.max(1, state.engagement.binderPagesUnlocked);
    final ids = binder.cardInstanceIds;
    final byId = {
      for (final c in state.collection) c.instanceId: c,
    };
    final color = Color(binder.colorHex);

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text(binder.name),
        actions: [
          IconButton(
            tooltip: 'Rename',
            onPressed: () => _rename(binder),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _delete(binder),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${ids.length} / ${pageCount * 9} pockets · $pageCount page${pageCount == 1 ? '' : 's'}',
                  style: AppText.jakarta(
                    color: CC.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: pageCount,
              itemBuilder: (context, page) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: 9,
                          itemBuilder: (context, slot) {
                            final index = page * 9 + slot;
                            final instanceId =
                                index < ids.length ? ids[index] : null;
                            final owned =
                                instanceId != null ? byId[instanceId] : null;
                            return _BinderPocket(
                              color: color,
                              owned: owned,
                              instanceId: instanceId,
                              onEmptyTap: () => _pickCard(binder),
                              onFilledTap: owned == null
                                  ? null
                                  : () => _inspect(owned),
                              onFilledLongPress: instanceId == null
                                  ? null
                                  : () => _remove(binder, instanceId),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Page ${page + 1} of $pageCount',
                        style: AppText.jakarta(
                          color: CC.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BinderPocket extends ConsumerWidget {
  const _BinderPocket({
    required this.color,
    required this.owned,
    required this.instanceId,
    required this.onEmptyTap,
    required this.onFilledTap,
    required this.onFilledLongPress,
  });

  final Color color;
  final OwnedCard? owned;
  final String? instanceId;
  final VoidCallback onEmptyTap;
  final VoidCallback? onFilledTap;
  final VoidCallback? onFilledLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (instanceId == null) {
      return Material(
        color: CC.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onEmptyTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                color: color.withValues(alpha: 0.7),
                size: 28,
              ),
            ),
          ),
        ),
      );
    }

    final def = owned == null
        ? null
        : ref.read(gameProvider.notifier).cardById(owned!.cardId);
    final url = def?.displayArtUrl ?? '';

    return Material(
      color: CC.card,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onFilledTap,
        onLongPress: onFilledLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CC.line),
          ),
          padding: const EdgeInsets.all(4),
          child: owned == null || url.isEmpty
              ? Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: CC.inkMuted.withValues(alpha: 0.7),
                  ),
                )
              : CardArt(
                  url: url,
                  foil: owned!.foil,
                  autoPlay: false,
                  width: double.infinity,
                  height: double.infinity,
                  radius: 8,
                ),
        ),
      ),
    );
  }
}

class _BinderCardPickerSheet extends ConsumerStatefulWidget {
  const _BinderCardPickerSheet({required this.available});

  final List<OwnedCard> available;

  @override
  ConsumerState<_BinderCardPickerSheet> createState() =>
      _BinderCardPickerSheetState();
}

class _BinderCardPickerSheetState
    extends ConsumerState<_BinderCardPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(gameProvider.notifier);
    final q = _query.trim().toLowerCase();
    final filtered = widget.available.where((c) {
      if (q.isEmpty) return true;
      final def = notifier.cardById(c.cardId);
      final name = (def?.name ?? c.cardId).toLowerCase();
      final set = (def?.setCode ?? '').toLowerCase();
      return name.contains(q) || set.contains(q) || c.cardId.toLowerCase().contains(q);
    }).toList();

    final h = MediaQuery.sizeOf(context).height;

    return Container(
      height: h * 0.78,
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
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add to binder',
                    style: AppText.jakarta(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search collection…',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: CC.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: CC.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: CC.line),
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching cards.',
                      style: AppText.jakarta(color: CC.inkMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final owned = filtered[i];
                      final def = notifier.cardById(owned.cardId);
                      final title = def?.name ?? owned.cardId;
                      final subtitle = def == null
                          ? owned.cardId
                          : '${def.setCode} · #${def.number ?? '?'}';
                      return Material(
                        color: CC.card,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              Navigator.pop(context, owned.instanceId),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                CardArt(
                                  url: def?.displayArtUrl ?? '',
                                  foil: owned.foil,
                                  autoPlay: false,
                                  width: 48,
                                  height: 68,
                                  radius: 8,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.jakarta(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: AppText.jakarta(
                                          color: CC.inkMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: CC.accent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
