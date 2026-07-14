import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/theme/app_colors.dart';
import '../services/dynamic_color_service.dart';

class AlbumArtDisplay extends StatelessWidget {
  final String? artPath;
  final String? title;
  final int? songId;
  final double size;
  final double borderRadius;
  final bool showShadow;
  final bool enableHero;

  const AlbumArtDisplay({
    super.key,
    this.artPath,
    this.title,
    this.songId,
    this.size = 300,
    this.borderRadius = 16,
    this.showShadow = true,
    this.enableHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = enableHero && title != null ? 'album_art_$title' : null;

    Widget child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildContent(),
      ),
    );

    if (heroTag != null) {
      child = Hero(tag: heroTag, child: child);
    }

    return child;
  }

  Widget _buildContent() {
    if (songId != null) {
      return QueryArtworkWidget(
        id: songId!,
        type: ArtworkType.AUDIO,
        artworkBorder: BorderRadius.circular(borderRadius),
        artworkWidth: size,
        artworkHeight: size,
        nullArtworkWidget: _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final gradient = DynamicColorService.gradientFromTitle(title ?? 'music');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AlbumArtPatternPainter(),
            ),
          ),
          Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white.withOpacity(0.45),
              size: size * 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumArtPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = size.width / 12;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
