import 'dart:io';
import '../../core/constants.dart';
import '../models/lyric_line.dart';

class LrcParser {
  /// Parses a .lrc file and returns a list of LyricLine objects.
  /// Returns an empty list if the file cannot be read or parsed.
  static Future<List<LyricLine>> parseFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      return parseLrc(content);
    } catch (e) {
      return [];
    }
  }

  /// Parses an LRC format string and returns a list of LyricLine objects.
  static List<LyricLine> parseLrc(String content) {
    final lines = content.split('\n');
    final lyrics = <LyricLine>[];

    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed != null) {
        lyrics.add(parsed);
      }
    }

    // Sort by timestamp
    lyrics.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lyrics;
  }

  /// Parses a single LRC line. Supports multiple timestamps per line.
  /// Format: [MM:SS.xx]text or [MM:SS.xxx]text or [MM:SS]text
  static LyricLine? _parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    // Match timestamp pattern: [MM:SS.xx] or [MM:SS.xxx] or [MM:SS]
    final timestampRegex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]');
    final matches = timestampRegex.allMatches(trimmed).toList();

    if (matches.isEmpty) return null;

    // Extract text after all timestamps
    String text = trimmed;
    for (final match in matches) {
      text = text.substring(match.end);
    }
    text = text.trim();

    // Skip metadata tags (ar, ti, al, by, etc.)
    if (_isMetadataTag(text, matches.first)) return null;

    // Use the last timestamp (for multi-timestamp lines)
    final lastMatch = matches.last;
    final timestamp = _parseTimestamp(lastMatch);

    return LyricLine(timestamp: timestamp, text: text);
  }

  /// Parses a timestamp from a regex match.
  static Duration _parseTimestamp(RegExpMatch match) {
    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final msString = match.group(3);

    int milliseconds = 0;
    if (msString != null) {
      // Normalize to 3 digits: "5" -> 500, "50" -> 500, "500" -> 500
      final padded = msString.padRight(3, '0').substring(0, 3);
      milliseconds = int.parse(padded);
    }

    return Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  /// Checks if a line is a metadata tag (like [ar:Artist], [ti:Title], etc.).
  static bool _isMetadataTag(String text, RegExpMatch firstMatch) {
    final fullMatch = firstMatch.group(0)!;
    // Metadata patterns: [ar:...], [ti:...], [al:...], [by:...], [offset:...], [re:...], [ve:...]
    final metaPatterns = RegExp(r'^\[(ar|ti|al|by|offset|re|ve):', caseSensitive: false);
    return metaPatterns.hasMatch(fullMatch);
  }

  /// Parses metadata tags from an LRC file.
  static Future<Map<String, String>> parseMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return {};

      final content = await file.readAsString();
      return _extractMetadata(content);
    } catch (e) {
      return {};
    }
  }

  static Map<String, String> _extractMetadata(String content) {
    final metadata = <String, String>{};
    final metaRegex = RegExp(r'^\[(ar|ti|al|by|offset|re|ve):(.+)\]$', caseSensitive: false);

    for (final line in content.split('\n')) {
      final match = metaRegex.firstMatch(line.trim());
      if (match != null) {
        final key = match.group(1)!.toLowerCase();
        final value = match.group(2)!.trim();
        metadata[key] = value;
      }
    }

    return metadata;
  }

  /// Converts a list of LyricLine back to LRC format string.
  static String toLrc(List<LyricLine> lyrics) {
    final buffer = StringBuffer();
    for (final line in lyrics) {
      buffer.writeln(line.formattedTimestamp + line.text);
    }
    return buffer.toString();
  }

  /// Saves a list of LyricLines as an .lrc file.
  static Future<void> saveFile(String filePath, List<LyricLine> lyrics) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(toLrc(lyrics));
  }

  /// Auto-detects whether [text] is already LRC format or plain text,
  /// and returns parsed LyricLines accordingly.
  static List<LyricLine> autoParse(String text) {
    final timestampRegex = RegExp(r'\[\d{1,2}:\d{2}(?:\.\d{1,3})?\]');
    final lines = text.split('\n');
    int lrcCount = 0;
    for (final line in lines) {
      if (timestampRegex.hasMatch(line)) lrcCount++;
    }

    // If more than half the non-empty lines have timestamps, treat as LRC
    final nonEmpty = lines.where((l) => l.trim().isNotEmpty).length;
    if (nonEmpty > 0 && lrcCount / nonEmpty > 0.5) {
      return parseLrc(text);
    }

    // Otherwise treat as plain text with auto-timing
    return fromPlainText(text);
  }

  /// Generates a basic LRC file from plain text with auto-timed intervals.
  /// Each line is spaced [interval] apart, starting from [startOffset].
  static List<LyricLine> fromPlainText(
    String plainText, {
    Duration interval = const Duration(seconds: 4),
    Duration startOffset = Duration.zero,
  }) {
    final lines = plainText.split('\n');
    final lyrics = <LyricLine>[];

    var currentOffset = startOffset;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        lyrics.add(LyricLine(
          timestamp: currentOffset,
          text: trimmed,
        ));
        currentOffset += interval;
      }
    }

    return lyrics;
  }
}
