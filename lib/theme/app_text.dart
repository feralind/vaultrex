import 'package:flutter/material.dart';

/// Offline Plus Jakarta Sans text styles.
abstract final class AppText {
  static const family = 'PlusJakartaSans';

  static TextStyle jakarta({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      fontStyle: fontStyle,
      overflow: overflow,
      shadows: shadows,
    );
  }

  static TextTheme textTheme([TextTheme? base]) {
    final b = base ?? ThemeData(brightness: Brightness.dark).textTheme;
    TextStyle patch(TextStyle? s) =>
        (s ?? const TextStyle()).copyWith(fontFamily: family);
    return b.copyWith(
      displayLarge: patch(b.displayLarge),
      displayMedium: patch(b.displayMedium),
      displaySmall: patch(b.displaySmall),
      headlineLarge: patch(b.headlineLarge),
      headlineMedium: patch(b.headlineMedium),
      headlineSmall: patch(b.headlineSmall),
      titleLarge: patch(b.titleLarge),
      titleMedium: patch(b.titleMedium),
      titleSmall: patch(b.titleSmall),
      bodyLarge: patch(b.bodyLarge),
      bodyMedium: patch(b.bodyMedium),
      bodySmall: patch(b.bodySmall),
      labelLarge: patch(b.labelLarge),
      labelMedium: patch(b.labelMedium),
      labelSmall: patch(b.labelSmall),
    );
  }
}
