import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vaultrex dark collector chrome.
class CC {
  static const bg = Color(0xFF0A0C12);
  static const bgElevated = Color(0xFF12151E);
  static const card = Color(0xFF161A24);
  static const cardSoft = Color(0xFF1C2230);
  static const ink = Color(0xFFF5F7FA);
  static const inkMuted = Color(0xFF9AA3B5);
  static const line = Color(0xFF2A3142);
  static const accent = Color(0xFF5B8CFF); // periwinkle CTA like RC
  static const accentHot = Color(0xFF7C9CFF);
  static const scan = Color(0xFFB8F000); // lime scan ring
  static const candy = Color(0xFFA78BFA);
  static const soldOut = Color(0xFF6B7280);
  static const glowBlue = Color(0x332B5BFF);
  static const glowPink = Color(0x33C026D3);
  static const glowTeal = Color(0x3322D3EE);

  static ThemeData dark() {
    final base = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
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
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.6,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgElevated,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final on = s.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
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
        contentTextStyle: GoogleFonts.plusJakartaSans(color: ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
