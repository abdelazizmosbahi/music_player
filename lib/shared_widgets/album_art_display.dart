import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/theme/app_colors.dart';
import '../services/dynamic_color_service.dart';

class AlbumArtDisplay extends StatefulWidget {
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
  State<AlbumArtDisplay> createState() => _AlbumArtDisplayState();
}

class _AlbumArtDisplayState extends State<AlbumArtDisplay>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _artBytes;
  bool _isLoading = false;
  int? _loadedSongId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant AlbumArtDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      _artBytes = null;
      _loadedSongId = null;
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork() async {
    if (widget.songId == null || _isLoading) return;
    if (_loadedSongId == widget.songId && _artBytes != null) return;

    _isLoading = true;
    try {
      final onAudioQuery = OnAudioQuery();
      final bytes = await onAudioQuery.queryArtwork(
        widget.songId!,
        ArtworkType.AUDIO,
        size: 512,
        quality: 100,
      );
      if (mounted && _loadedSongId != widget.songId) {
        setState(() {
          _artBytes = bytes;
          _loadedSongId = widget.songId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final heroTag = widget.enableHero && widget.title != null
        ? 'album_art_${widget.title}'
        : null;

    Widget child = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.showShadow
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
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: _buildContent(),
      ),
    );

    if (heroTag != null) {
      child = Hero(tag: heroTag, child: child);
    }

    return child;
  }

  Widget _buildContent() {
    if (_artBytes != null && _artBytes!.isNotEmpty) {
      return Image.memory(
        _artBytes!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final gradient = DynamicColorService.gradientFromTitle(widget.title ?? 'music');

    return Container(
      width: widget.size,
      height: widget.size,
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
              size: widget.size * 0.3,
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
