import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class DynamicColorService {
  static final DynamicColorService _instance = DynamicColorService._();
  factory DynamicColorService() => _instance;
  DynamicColorService._();

  final Map<String, PaletteColor> _cache = {};

  /// Extracts dominant colors from an image provider.
  Future<PaletteData> extractColors(ImageProvider imageProvider, {String? key}) async {
    // Check cache
    if (key != null && _cache.containsKey(key)) {
      final cached = _cache[key]!;
      return PaletteData.fromPalette(cached);
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 8,
        size: const Size(200, 200),
      );

      final dominant = palette.dominantColor;
      if (dominant != null && key != null) {
        _cache[key] = dominant;
      }

      return PaletteData(
        dominant: dominant?.color ?? Colors.grey,
        vibrant: palette.vibrantColor?.color,
        darkVibrant: palette.darkVibrantColor?.color,
        lightVibrant: palette.lightVibrantColor?.color,
        muted: palette.mutedColor?.color,
        darkMuted: palette.darkMutedColor?.color,
        lightMuted: palette.lightMutedColor?.color,
      );
    } catch (e) {
      return PaletteData.empty();
    }
  }

  /// Generates a background gradient from a string (for placeholders without images).
  static LinearGradient gradientFromTitle(String title) {
    final hash = title.hashCode;
    final hue1 = (hash % 360).abs().toDouble();
    final hue2 = ((hash >> 8) % 360).abs().toDouble();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromAHSL(1.0, hue1, 0.55, 0.25).toColor(),
        HSLColor.fromAHSL(1.0, hue2, 0.45, 0.15).toColor(),
      ],
    );
  }

  /// Generates a dynamic background color for the Now Playing screen.
  static Color bgColorFromTitle(String title) {
    final hash = title.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.5, 0.2).toColor();
  }

  /// Generates a consistent avatar color from a name.
  static Color avatarColor(String name) {
    final hash = name.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.55).toColor();
  }

  void clearCache() {
    _cache.clear();
  }
}

class PaletteData {
  final Color dominant;
  final Color? vibrant;
  final Color? darkVibrant;
  final Color? lightVibrant;
  final Color? muted;
  final Color? darkMuted;
  final Color? lightMuted;

  const PaletteData({
    required this.dominant,
    this.vibrant,
    this.darkVibrant,
    this.lightVibrant,
    this.muted,
    this.darkMuted,
    this.lightMuted,
  });

  factory PaletteData.empty() => const PaletteData(dominant: Colors.grey);

  factory PaletteData.fromPalette(PaletteColor palette) {
    return PaletteData(
      dominant: palette.color,
      vibrant: palette.color,
    );
  }

  /// Returns a suitable background color for the Now Playing screen.
  Color get nowPlayingBg => darkMuted ?? darkVibrant ?? dominant;

  /// Returns a suitable accent color overlay.
  Color get accentOverlay => vibrant?.withOpacity(0.3) ?? dominant.withOpacity(0.3);

  /// Returns a list of gradient colors for a blurred background.
  List<Color> get gradientColors => [
        darkMuted ?? dominant,
        dominant.withOpacity(0.6),
      ];
}
