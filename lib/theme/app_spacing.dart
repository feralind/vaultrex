import 'package:flutter/material.dart';

/// Spacing / radius / motion scales for Bindora chrome.
abstract final class AppSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;

  static const double rChip = 12;
  static const double rCard = 14;
  static const double rSheet = 20;

  static const Duration durFast = Duration(milliseconds: 120);
  static const Duration durMed = Duration(milliseconds: 200);
  static const Curve curveOut = Curves.easeOutCubic;
}
