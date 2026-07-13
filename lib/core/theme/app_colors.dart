import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core palette
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF282828);
  static const Color cardHover = Color(0xFF333333);

  // Accent
  static const Color accent = Color(0xFF1ED760);
  static const Color accentDark = Color(0xFF1AA34A);
  static const Color accentLight = Color(0xFF3BE477);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF727272);
  static const Color textDisabled = Color(0xFF535353);

  // Borders & Dividers
  static const Color divider = Color(0xFF2A2A2A);
  static const Color border = Color(0xFF333333);

  // Overlays
  static const Color overlay = Color(0x80000000);
  static const Color shimmer = Color(0xFF2A2A2A);

  // Semantic
  static const Color error = Color(0xFFE94560);
  static const Color success = Color(0xFF1ED760);
  static const Color warning = Color(0xFFFFC107);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), background],
  );

  static LinearGradient accentGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  static LinearGradient cardGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, surfaceElevated],
  );

  // Generate a deterministic gradient from a string (song title, etc.)
  static LinearGradient gradientFromString(String input) {
    final hash = input.hashCode;
    final hue1 = (hash % 360).abs().toDouble();
    final hue2 = ((hash >> 8) % 360).abs().toDouble();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromAHSL(1.0, hue1, 0.6, 0.25).toColor(),
        HSLColor.fromAHSL(1.0, hue2, 0.5, 0.15).toColor(),
      ],
    );
  }
}
