import 'dart:math';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/theme/app_colors.dart';

class AlbumArtPlaceholder extends StatelessWidget {
  final double size;
  final String? title;
  final int? songId;
  final BorderRadius borderRadius;
  final IconData icon;

  const AlbumArtPlaceholder({
    super.key,
    this.size = 48,
    this.title,
    this.songId,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.icon = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    if (songId != null) {
      return QueryArtworkWidget(
        id: songId!,
        type: ArtworkType.AUDIO,
        artworkBorder: borderRadius,
        artworkWidth: size,
        artworkHeight: size,
        size: 256,
        quality: 100,
        artworkQuality: FilterQuality.high,
        nullArtworkWidget: _buildGradient(),
      );
    }
    return _buildGradient();
  }

  Widget _buildGradient() {
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

Color colorFromString(String input) {
  final hash = input.hashCode;
  final hue = (hash % 360).abs().toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.65, 0.55).toColor();
}

Color randomColor() {
  final random = Random();
  return HSLColor.fromAHSL(
    1.0,
    random.nextDouble() * 360,
    0.6,
    0.6,
  ).toColor();
}
