class DurationFormatter {
  DurationFormatter._();

  /// Formats a Duration to "MM:SS" or "H:MM:SS" for longer durations.
  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats to "MM:SS / MM:SS" style.
  static String formatRange(Duration current, Duration total) {
    return '${format(current)} / ${format(total)}';
  }

  /// Returns a human-readable relative time string.
  static String formatRelative(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    if (minutes > 0) {
      return '$minutes min';
    }
    return '${duration.inSeconds} sec';
  }

  /// Converts milliseconds string to Duration.
  static Duration fromMilliseconds(int ms) {
    return Duration(milliseconds: ms);
  }
}
