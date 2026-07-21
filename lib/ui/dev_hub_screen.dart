import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dev/dev_studio.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/game_widgets.dart';
import 'design_kit_screen.dart';
import 'pack_theater_soft_lift_preview.dart';

/// Shared pending target when long-pressing art in-app.
abstract final class DevImagePick {
  static String? pending;
}

/// Opens Dev Hub and optionally pre-fills an art swap target.
Future<void> openDevHub(BuildContext context, {String? imageTarget}) {
  if (imageTarget != null && imageTarget.isNotEmpty) {
    DevImagePick.pending = imageTarget;
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const DevHubScreen()),
  );
}

/// Full-screen developer hub (debug builds). Open from Settings.
class DevHubScreen extends StatefulWidget {
  const DevHubScreen({super.key});

  @override
  State<DevHubScreen> createState() => _DevHubScreenState();
}

class _DevHubScreenState extends State<DevHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<String> _assets = const [];
  String _filter = '';
  final _targetCtrl = TextEditingController();
  final _replaceCtrl = TextEditingController();
  String? _previewUrl;

  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadAssets();
    final pending = DevImagePick.pending;
    if (pending != null && pending.isNotEmpty) {
      _targetCtrl.text = pending;
      _previewUrl = pending;
      DevImagePick.pending = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabs.animateTo(1);
      });
    }
    DevStudio.instance.addListener(_onStudio);
  }

  @override
  void dispose() {
    DevStudio.instance.removeListener(_onStudio);
    _tabs.dispose();
    _targetCtrl.dispose();
    _replaceCtrl.dispose();
    super.dispose();
  }

  void _onStudio() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAssets() async {
    final fallback = <String>[
      'assets/card_backs/riftbound_back.png',
      'assets/card_backs/pokemon_back.png',
      'assets/card_backs/mtg_back.png',
      'assets/card_backs/onepiece_back.png',
      'assets/logos/bindora.png',
      'assets/logos/riftbound.png',
      'assets/logos/mtg.png',
      'assets/rip/peel_sealed.png',
    ];
    try {
      final raw = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final paths = <String>[];
      for (final key in decoded.keys) {
        final l = key.toLowerCase();
        if (l.endsWith('.png') ||
            l.endsWith('.jpg') ||
            l.endsWith('.jpeg') ||
            l.endsWith('.webp')) {
          paths.add(key);
        }
      }
      paths.sort();
      if (!mounted) return;
      setState(() => _assets = paths.isEmpty ? fallback : paths);
    } catch (_) {
      if (!mounted) return;
      setState(() => _assets = fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dev Hub')),
        body: const Center(child: Text('Debug builds only')),
      );
    }

    final studio = DevStudio.instance;
    final filtered = _filter.isEmpty
        ? _assets
        : _assets
            .where((a) => a.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: CC.bg,
      appBar: AppBar(
        title: Text(
          'Dev Hub',
          style: AppText.jakarta(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Nudge'),
            Tab(text: 'Art swap'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _nudgeTab(studio),
          _artTab(studio, filtered),
          _previewTab(studio),
        ],
      ),
    );
  }

  Widget _nudgeTab(DevStudio studio) {
    final id = studio.selectedId;
    final v = id != null ? studio.valuesFor(id) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Select a target, tweak offsets, then Copy Dart into code.',
          style: AppText.jakarta(color: CC.inkMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Text('Targets', style: _h()),
        const SizedBox(height: 8),
        if (studio.labels.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CC.line),
            ),
            child: Text(
              'No targets yet.\n'
              'Open fullscreen card inspect (tap art in a card sheet) — '
              'it registers “Inspect card”. Or long-press card art.',
              style: AppText.jakarta(
                color: CC.inkMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in studio.labels.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: studio.selectedId == e.key,
                  onSelected: (_) => studio.select(e.key, label: e.value),
                ),
            ],
          ),
        if (id != null && v != null) ...[
          const SizedBox(height: 20),
          Text('Nudge · ${studio.labels[id]}', style: _h()),
          _slider('X', v.dx, -80, 80, (n) {
            studio.setNudge(id, v.copyWith(dx: n));
          }),
          _slider('Y', v.dy, -80, 80, (n) {
            studio.setNudge(id, v.copyWith(dy: n));
          }),
          _slider('Scale', v.scale, 0.5, 1.6, (n) {
            studio.setNudge(id, v.copyWith(scale: n));
          }),
          _slider('Rotate°', v.rotDeg, -30, 30, (n) {
            studio.setNudge(id, v.copyWith(rotDeg: n));
          }),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => studio.resetNudge(id),
                child: const Text('Reset'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: studio.dartSnippet(id)),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied Dart snippet')),
                  );
                },
                child: const Text('Copy Dart'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            studio.dartSnippet(id),
            style: AppText.jakarta(color: CC.inkMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _artTab(DevStudio studio, List<String> filtered) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste a current image URL/path (or long-press card art in-app), '
                'then tap a bundled asset to override it live.',
                style: AppText.jakarta(
                  color: CC.inkMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _targetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Current art (URL or assets/…)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (s) => setState(() => _previewUrl = s.trim()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _replaceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Or paste replacement URL / path',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final t = _targetCtrl.text.trim();
                        final r = _replaceCtrl.text.trim();
                        if (t.isEmpty || r.isEmpty) return;
                        studio.setImageOverride(t, r);
                        setState(() => _previewUrl = r);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Override set → $r')),
                        );
                      },
                      child: const Text('Apply override'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      final t = _targetCtrl.text.trim();
                      if (t.isEmpty) {
                        studio.clearAllImageOverrides();
                      } else {
                        studio.clearImageOverride(t);
                      }
                      setState(() {});
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              if (studio.imageOverrides.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${studio.imageOverrides.length} active override(s)',
                  style: AppText.jakarta(color: CC.accent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Filter assets',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
                onChanged: (s) => setState(() => _filter = s),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _assets.isEmpty ? 'Loading assets…' : 'No matches',
                    style: AppText.jakarta(color: CC.inkMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length.clamp(0, 200),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = filtered[i];
                    return ListTile(
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          a,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      title: Text(
                        a,
                        style: AppText.jakarta(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.swap_horiz),
                      onTap: () {
                        final t = _targetCtrl.text.trim();
                        if (t.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Set “Current art” first (or long-press art in-app).',
                              ),
                            ),
                          );
                          return;
                        }
                        studio.setImageOverride(t, a);
                        setState(() {
                          _replaceCtrl.text = a;
                          _previewUrl = a;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _previewTab(DevStudio studio) {
    final src = _previewUrl ??
        (_targetCtrl.text.trim().isNotEmpty ? _targetCtrl.text.trim() : null);
    final shown = src == null ? null : studio.resolveImage(src);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Design system', style: _h()),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DesignKitScreen()),
          ),
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Open design kit'),
        ),
        const SizedBox(height: 24),
        Text('Pack theater', style: _h()),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => openPackTheaterSoftLiftPreview(context),
          icon: const Icon(Icons.auto_awesome_motion_rounded),
          label: const Text('Live pack peel demo'),
        ),
        const SizedBox(height: 6),
        Text(
          'Swipe-commit peel + pack_open / flip_card SFX.',
          style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        Text('Art preview', style: _h()),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 2.5 / 3.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CC.line),
            ),
            child: shown == null || shown.isEmpty
                ? Center(
                    child: Text(
                      'Pick art in Art swap tab',
                      style: AppText.jakarta(color: CC.inkMuted),
                    ),
                  )
                : shown.startsWith('assets/')
                    ? Image.asset(shown, fit: BoxFit.contain)
                    : Image.network(shown, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 24),
        Text('Tilt playground', style: _h()),
        const SizedBox(height: 6),
        Text(
          'Drag on the card — same feel as fullscreen inspect.',
          style: AppText.jakarta(color: CC.inkMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onPanUpdate: (d) {
              setState(() {
                _tiltY = (_tiltY + d.delta.dx / 140).clamp(-0.45, 0.45);
                _tiltX = (_tiltX - d.delta.dy / 140).clamp(-0.45, 0.45);
              });
            },
            onPanEnd: (_) => setState(() {
              _tiltX = 0;
              _tiltY = 0;
            }),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.00135)
                ..rotateX(_tiltX)
                ..rotateY(_tiltY),
              child: CardArt(
                url: shown ??
                    'https://images.scrydex.com/riftbound/OGS-1/large',
                width: 200,
                height: 280,
                radius: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _tiltX = 0;
            _tiltY = 0;
          }),
          child: const Text('Reset tilt'),
        ),
      ],
    );
  }

  TextStyle _h() => AppText.jakarta(fontWeight: FontWeight.w800, fontSize: 15);

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '$label ${value.toStringAsFixed(1)}',
            style: AppText.jakarta(fontSize: 11, color: CC.inkMuted),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
