class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  /// Returns the timestamp in total milliseconds.
  int get timestampMs => timestamp.inMilliseconds;

  /// Returns the formatted timestamp as "[MM:SS.xx]".
  String get formattedTimestamp {
    final mins = timestamp.inMinutes;
    final secs = timestamp.inSeconds.remainder(60);
    final ms = timestamp.inMilliseconds.remainder(1000);
    return '[$mins:${secs.toString().padLeft(2, '0')}.${(ms ~/ 10).toString().padLeft(2, '0')}]';
  }

  @override
  String toString() => '$formattedTimestamp $text';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          text == other.text;

  @override
  int get hashCode => timestamp.hashCode ^ text.hashCode;
}
