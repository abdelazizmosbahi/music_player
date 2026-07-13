import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
    double height = 1.4,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Display
  static TextStyle displayLarge = _base(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle displayMedium = _base(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle displaySmall = _base(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Headings
  static TextStyle headingLarge = _base(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle headingMedium = _base(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle headingSmall = _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body
  static TextStyle bodyLarge = _base(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Labels
  static TextStyle labelLarge = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle labelMedium = _base(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = _base(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Secondary color variants
  static TextStyle bodyMediumSecondary = _base(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static TextStyle bodySmallSecondary = _base(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static TextStyle headingSmallSecondary = _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // Accent
  static TextStyle accent = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );

  // Now Playing
  static TextStyle nowPlayingTitle = _base(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle nowPlayingArtist = _base(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Lyrics
  static TextStyle lyricActive = _base(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle lyricInactive = _base(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.5,
  );

  static TextStyle lyricPast = _base(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textDisabled,
    height: 1.5,
  );
}
