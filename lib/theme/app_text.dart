import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Offline Plus Jakarta Sans text styles + named scale.
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

  static TextStyle display({Color? color}) => jakarta(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.15,
        color: color ?? CC.ink,
      );

  static TextStyle title({Color? color}) => jakarta(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        height: 1.2,
        color: color ?? CC.ink,
      );

  static TextStyle titleSm({Color? color}) => jakarta(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color ?? CC.ink,
      );

  static TextStyle body({Color? color}) => jakarta(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: color ?? CC.ink,
      );

  static TextStyle bodySm({Color? color}) => jakarta(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: color ?? CC.inkMuted,
      );

  static TextStyle label({Color? color}) => jakarta(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.2,
        color: color ?? CC.inkMuted,
      );

  /// Tabular-ish money / candy figures.
  static TextStyle tabular({
    Color? color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      jakarta(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: 0.15,
        height: 1.2,
        color: color ?? CC.ink,
      );

  static TextTheme textTheme([TextTheme? base]) {
    final b = base ?? ThemeData(brightness: Brightness.dark).textTheme;
    TextStyle patch(TextStyle? s, TextStyle named) =>
        (s ?? const TextStyle()).copyWith(
          fontFamily: family,
          fontSize: named.fontSize,
          fontWeight: named.fontWeight,
          letterSpacing: named.letterSpacing,
          height: named.height,
        );
    return b.copyWith(
      displayLarge: patch(b.displayLarge, display()),
      displayMedium: patch(b.displayMedium, display()),
      displaySmall: patch(b.displaySmall, title()),
      headlineLarge: patch(b.headlineLarge, title()),
      headlineMedium: patch(b.headlineMedium, title()),
      headlineSmall: patch(b.headlineSmall, titleSm()),
      titleLarge: patch(b.titleLarge, titleSm()),
      titleMedium: patch(b.titleMedium, body()),
      titleSmall: patch(b.titleSmall, label()),
      bodyLarge: patch(b.bodyLarge, body()),
      bodyMedium: patch(b.bodyMedium, body()),
      bodySmall: patch(b.bodySmall, bodySm()),
      labelLarge: patch(b.labelLarge, label(color: CC.ink)),
      labelMedium: patch(b.labelMedium, label()),
      labelSmall: patch(b.labelSmall, label()),
    );
  }
}
