import 'package:flutter/material.dart';

/// Flip 4–friendly responsive grid helpers (narrow tall portrait ≈ 360–430 logical).
class FlipLayout {
  FlipLayout._();

  /// Phone / Flip cover: 3 cols. Tablet+: more.
  static int packCrossAxisCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 520) return 3;
    if (w < 800) return 4;
    return 5;
  }

  /// Collection uses the same Flip-first 3-col phone layout.
  static int collectionCrossAxisCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 520) return 3;
    if (w < 800) return 4;
    return 5;
  }

  /// Card tile: art + 2-line name + set + price. Narrower cells need more height.
  static double collectionAspectRatio(BuildContext context) {
    final cols = collectionCrossAxisCount(context);
    // Tall enough for TCG art (or PSA slab) + labels without clipping.
    return switch (cols) {
      3 => 0.42,
      4 => 0.40,
      _ => 0.44,
    };
  }

  /// Pack shop tiles (art-heavy + 2-line title + price row).
  static double packAspectRatio(BuildContext context) {
    final cols = packCrossAxisCount(context);
    return switch (cols) {
      3 => 0.56,
      4 => 0.54,
      _ => 0.58,
    };
  }
}
