import 'package:flutter/material.dart';

class AppThemeTokens {
  // ==========================================
  // 1. UKURAN (SIZES & SPACING)
  // ==========================================
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // ==========================================
  // 2. PARAMETER ANIMASI (ANIMATIONS)
  // ==========================================
  static const Duration pageTransitionIn = Duration(milliseconds: 450);
  static const Duration pageTransitionOut = Duration(milliseconds: 400);
  static const Curve animationCurve = Curves.easeInOutCubic;

  // ==========================================
  // 3. TIPOGRAFI / GAYA TEKS (TEXT STYLES)
  // ==========================================
  static const TextStyle heading = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );
}
