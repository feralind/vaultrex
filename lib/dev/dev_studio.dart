import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug-only layout/art studio. No-ops in release.
class DevStudio extends ChangeNotifier {
  DevStudio._();
  static final DevStudio instance = DevStudio._();

  bool get enabled => kDebugMode;

  String? selectedId;

  final Map<String, String> labels = {};
  final Map<String, DevNudgeValues> nudges = {};
  /// Original image URL/path → replacement (asset path or http URL).
  final Map<String, String> imageOverrides = {};

  /// Public notify for helpers outside this class.
  void bump() => notifyListeners();

  void select(String id, {String? label}) {
    if (!enabled) return;
    selectedId = id;
    if (label != null) labels[id] = label;
    nudges.putIfAbsent(id, DevNudgeValues.new);
    notifyListeners();
  }

  void register(String id, String label) {
    if (!enabled) return;
    labels[id] = label;
    nudges.putIfAbsent(id, DevNudgeValues.new);
  }

  void unregister(String id) {
    labels.remove(id);
    if (selectedId == id) selectedId = null;
    notifyListeners();
  }

  DevNudgeValues valuesFor(String id) =>
      nudges.putIfAbsent(id, DevNudgeValues.new);

  void setNudge(String id, DevNudgeValues v) {
    nudges[id] = v;
    notifyListeners();
  }

  void resetNudge(String id) {
    nudges[id] = DevNudgeValues();
    notifyListeners();
  }

  void setImageOverride(String original, String replacement) {
    if (!enabled) return;
    imageOverrides[original] = replacement;
    notifyListeners();
  }

  void clearImageOverride(String original) {
    imageOverrides.remove(original);
    notifyListeners();
  }

  void clearAllImageOverrides() {
    imageOverrides.clear();
    notifyListeners();
  }

  String resolveImage(String original) =>
      imageOverrides[original] ?? original;

  String dartSnippet(String id) {
    final v = valuesFor(id);
    if (v.isIdentity) return '// no offset for $id';
    final parts = <String>[];
    if (v.dx != 0 || v.dy != 0) {
      parts.add(
        'Transform.translate(offset: Offset(${v.dx.toStringAsFixed(1)}, ${v.dy.toStringAsFixed(1)}), child: child)',
      );
    }
    if (v.scale != 1) {
      parts.add('Transform.scale(scale: ${v.scale.toStringAsFixed(3)}, child: child)');
    }
    if (v.rotDeg != 0) {
      parts.add(
        'Transform.rotate(angle: ${v.rotDeg.toStringAsFixed(2)} * pi / 180, child: child)',
      );
    }
    return parts.isEmpty ? '// identity' : parts.join('\n→ ');
  }
}

class DevNudgeValues {
  DevNudgeValues({
    this.dx = 0,
    this.dy = 0,
    this.scale = 1,
    this.rotDeg = 0,
  });

  double dx;
  double dy;
  double scale;
  double rotDeg;

  bool get isIdentity =>
      dx == 0 && dy == 0 && scale == 1 && rotDeg == 0;

  DevNudgeValues copyWith({
    double? dx,
    double? dy,
    double? scale,
    double? rotDeg,
  }) =>
      DevNudgeValues(
        dx: dx ?? this.dx,
        dy: dy ?? this.dy,
        scale: scale ?? this.scale,
        rotDeg: rotDeg ?? this.rotDeg,
      );
}

/// Wraps a widget so debug studio can nudge it.
class DevNudge extends StatefulWidget {
  const DevNudge({
    super.key,
    required this.id,
    required this.label,
    required this.child,
  });

  final String id;
  final String label;
  final Widget child;

  @override
  State<DevNudge> createState() => _DevNudgeState();
}

class _DevNudgeState extends State<DevNudge> {
  @override
  void initState() {
    super.initState();
    DevStudio.instance.register(widget.id, widget.label);
    DevStudio.instance.addListener(_onStudio);
  }

  @override
  void dispose() {
    DevStudio.instance.removeListener(_onStudio);
    DevStudio.instance.unregister(widget.id);
    super.dispose();
  }

  void _onStudio() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!DevStudio.instance.enabled) return widget.child;
    final v = DevStudio.instance.valuesFor(widget.id);
    final selected = DevStudio.instance.selectedId == widget.id;
    Widget child = widget.child;
    if (!v.isIdentity) {
      child = Transform.translate(
        offset: Offset(v.dx, v.dy),
        child: Transform.rotate(
          angle: v.rotDeg * 3.1415926535 / 180,
          child: Transform.scale(scale: v.scale, child: child),
        ),
      );
    }
    return GestureDetector(
      onLongPress: () =>
          DevStudio.instance.select(widget.id, label: widget.label),
      child: DecoratedBox(
        decoration: selected
            ? BoxDecoration(
                border: Border.all(color: const Color(0xFF5B8CFF), width: 1.5),
              )
            : const BoxDecoration(),
        child: child,
      ),
    );
  }
}
