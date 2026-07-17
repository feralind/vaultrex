import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Result from [showCreateBinderSheet].
class CreateBinderResult {
  const CreateBinderResult({
    required this.name,
    required this.colorHex,
    required this.isPrivate,
  });

  final String name;
  final int colorHex;
  final bool isPrivate;
}

/// Rare Candy–style Create Binder bottom sheet.
Future<CreateBinderResult?> showCreateBinderSheet(BuildContext context) {
  return showModalBottomSheet<CreateBinderResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CreateBinderSheet(),
  );
}

const _presetColors = <Color>[
  Color(0xFF5B8CFF), // periwinkle
  Color(0xFFA78BFA), // purple
  Color(0xFF38BDF8), // sky
  Color(0xFF2DD4BF), // teal
  Color(0xFFB8F000), // lime
  Color(0xFFFDE68A), // pale yellow
  Color(0xFFFB7185), // coral
  Color(0xFFFDBA74), // peach
  Color(0xFFF9A8D4), // pink
  Color(0xFF1F2430), // dark charcoal
];

class _CreateBinderSheet extends StatefulWidget {
  const _CreateBinderSheet();

  @override
  State<_CreateBinderSheet> createState() => _CreateBinderSheetState();
}

class _CreateBinderSheetState extends State<_CreateBinderSheet> {
  final _nameCtrl = TextEditingController();
  final _hexCtrl = TextEditingController(text: '5B8CFF');
  Color _color = _presetColors.first;
  bool _private = false;
  int? _presetIndex = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(int i) {
    final c = _presetColors[i];
    setState(() {
      _presetIndex = i;
      _color = c;
      _hexCtrl.text = _toHex(c);
    });
  }

  void _applyHex(String raw) {
    final cleaned = raw.replaceAll('#', '').trim().toUpperCase();
    if (cleaned.length != 6) return;
    final v = int.tryParse(cleaned, radix: 16);
    if (v == null) return;
    final c = Color(0xFF000000 | v);
    setState(() {
      _color = c;
      _presetIndex = null;
      for (var i = 0; i < _presetColors.length; i++) {
        if (_presetColors[i].toARGB32() == c.toARGB32()) {
          _presetIndex = i;
          break;
        }
      }
    });
  }

  void _clearHex() {
    setState(() {
      _presetIndex = 0;
      _color = _presetColors.first;
      _hexCtrl.text = _toHex(_color);
    });
  }

  String _toHex(Color c) {
    return c.toARGB32().toRadixString(16).substring(2).toUpperCase();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    Navigator.of(context).pop(
      CreateBinderResult(
        name: name.isEmpty ? 'Binder' : name,
        colorHex: _color.toARGB32(),
        isPrivate: _private,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Material(
            color: CC.bgElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: CC.inkMuted.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CC.cardSoft,
                            border: Border.all(color: CC.line),
                          ),
                          child: const Icon(Icons.close, size: 16, color: CC.ink),
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CoverPreview(color: _color),
                          const SizedBox(height: 18),
                          Text(
                            'Name',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameCtrl,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: 'Binder name',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: CC.inkMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: CC.card,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: CC.line),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: CC.line),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: CC.scan),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Color',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SwatchGrid(
                            colors: _presetColors,
                            selectedIndex: _presetIndex,
                            onSelect: _selectPreset,
                            customSelected: _presetIndex == null,
                            onCustom: () {
                              // Focus hex for custom / eyedropper stand-in.
                              setState(() => _presetIndex = null);
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _hexCtrl,
                                  onChanged: _applyHex,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.6,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9a-fA-F]'),
                                    ),
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: InputDecoration(
                                    prefixText: '# ',
                                    prefixStyle: GoogleFonts.plusJakartaSans(
                                      color: CC.inkMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    filled: true,
                                    fillColor: CC.card,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: CC.line),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: CC.line),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: CC.scan),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: _clearHex,
                                style: TextButton.styleFrom(
                                  foregroundColor: CC.ink,
                                  backgroundColor: CC.card,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: CC.line),
                                  ),
                                ),
                                child: Text(
                                  'Clear',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => setState(() => _private = !_private),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _private,
                                    onChanged: (v) =>
                                        setState(() => _private = v ?? false),
                                    activeColor: CC.scan,
                                    checkColor: Colors.black,
                                    side: const BorderSide(color: CC.inkMuted),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Only you can see this binder',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: CC.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: CC.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Create Binder',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: CC.inkMuted.withValues(alpha: 0.55),
          radius: 16,
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.85),
                Color.lerp(color, Colors.black, 0.35)!,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _NoisePainter(opacity: 0.12),
            child: Center(
              child: Icon(
                Icons.collections_bookmark_outlined,
                size: 42,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({
    required this.colors,
    required this.selectedIndex,
    required this.onSelect,
    required this.customSelected,
    required this.onCustom,
  });

  final List<Color> colors;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool customSelected;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (var i = 0; i < colors.length; i++)
        _Swatch(
          color: colors[i],
          selected: selectedIndex == i,
          onTap: () => onSelect(i),
        ),
      _Swatch(
        color: null,
        selected: customSelected,
        onTap: onCustom,
        rainbow: true,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items,
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.rainbow = false,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  final bool rainbow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? CC.ink : Colors.transparent,
            width: 2.5,
          ),
        ),
        padding: const EdgeInsets.all(2.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rainbow ? null : color,
            gradient: rainbow
                ? const SweepGradient(
                    colors: [
                      Color(0xFFFF5A5A),
                      Color(0xFFFFD166),
                      Color(0xFF06D6A0),
                      Color(0xFF118AB2),
                      Color(0xFF9B5DE5),
                      Color(0xFFFF5A5A),
                    ],
                  )
                : null,
            border: Border.all(color: CC.line.withValues(alpha: 0.6)),
          ),
          child: rainbow
              ? const Icon(Icons.colorize, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      const dash = 6.0;
      const gap = 5.0;
      while (d < metric.length) {
        final next = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity * 0.35);
    const step = 7.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        if (((x + y) ~/ step) % 3 == 0) {
          canvas.drawCircle(Offset(x + 1, y + 1), 0.8, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter old) => old.opacity != opacity;
}
