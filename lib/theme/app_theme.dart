import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/enums.dart';
import 'app_spacing.dart';
import 'app_text.dart';

/// Bindora dark collector chrome.
class CC {
  static const bg = Color(0xFF0A0C12);
  static const bgElevated = Color(0xFF12151E);
  static const card = Color(0xFF161A24);
  static const cardSoft = Color(0xFF1C2230);
  static const ink = Color(0xFFF5F7FA);
  static const inkMuted = Color(0xFF9AA3B5);
  static const line = Color(0xFF2A3142);
  static const accent = Color(0xFF5B8CFF); // periwinkle CTA
  static const accentHot = Color(0xFF7C9CFF);
  static const scan = Color(0xFFB8F000); // lime live / rare pulse
  static const candy = Color(0xFFA78BFA);
  static const cash = Color(0xFF34D399);
  static const soldOut = Color(0xFF6B7280);
  static const glowBlue = Color(0x332B5BFF);
  static const glowPink = Color(0x33C026D3);
  static const glowTeal = Color(0x3322D3EE);

  /// Rarity chip / edge colors (single source of truth).
  static Color rarityColor(Rarity rarity) => switch (rarity) {
        Rarity.common => const Color(0xFF9CA3AF),
        Rarity.uncommon => cash,
        Rarity.rare => const Color(0xFF60A5FA),
        Rarity.epic => const Color(0xFFC084FC),
        Rarity.showcase => const Color(0xFFFBBF24),
        Rarity.overnumbered => const Color(0xFFFB923C),
        Rarity.signature => const Color(0xFFF472B6),
        Rarity.ultimate => const Color(0xFFF87171),
        Rarity.promo => const Color(0xFF2DD4BF),
        Rarity.token => soldOut,
        Rarity.none => soldOut,
      };

  static ThemeData dark() {
    final base = AppText.textTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: scan,
        surface: card,
        onSurface: ink,
        outline: line,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppText.titleSm(color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpace.rCard),
          ),
          textStyle: AppText.jakarta(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.6,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpace.rCard),
          ),
          textStyle: AppText.jakarta(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardSoft,
        selectedColor: accent.withValues(alpha: 0.22),
        disabledColor: card,
        labelStyle: AppText.label(color: ink),
        secondaryLabelStyle: AppText.label(color: inkMuted),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.rChip),
          side: const BorderSide(color: line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgElevated,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final on = s.contains(WidgetState.selected);
          return AppText.jakarta(
            fontSize: 10,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? ink : inkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final on = s.contains(WidgetState.selected);
          return IconThemeData(size: 22, color: on ? ink : inkMuted);
        }),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardSoft,
        contentTextStyle: AppText.body(color: ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.rChip),
        ),
      ),
    );
  }
}
