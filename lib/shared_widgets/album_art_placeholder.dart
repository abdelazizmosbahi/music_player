import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AlbumArtPlaceholder extends StatelessWidget {
  final double size;
  final String? title;
  final BorderRadius borderRadius;
  final IconData icon;

  const AlbumArtPlaceholder({
    super.key,
    this.size = 48,
    this.title,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.icon = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.gradientFromString(title ?? 'music');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: size * 0.4,
        ),
      ),
    );
  }
}

/// Generates a deterministic color from a string.
Color colorFromString(String input) {
  final hash = input.hashCode;
  final hue = (hash % 360).abs().toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.65, 0.55).toColor();
}

/// Generates a random pastel-like color for testing.
Color randomColor() {
  final random = Random();
  return HSLColor.fromAHSL(
    1.0,
    random.nextDouble() * 360,
    0.6,
    0.6,
  ).toColor();
}
