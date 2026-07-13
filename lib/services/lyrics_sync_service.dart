import 'dart:async';
import '../data/models/lyric_line.dart';

class LyricsSyncService {
  List<LyricLine> _lyrics = [];
  int _currentLineIndex = -1;
  final StreamController<int> _currentLineController = StreamController<int>.broadcast();

  Stream<int> get currentLineStream => _currentLineController.stream;
  int get currentLineIndex => _currentLineIndex;
  List<LyricLine> get lyrics => List.unmodifiable(_lyrics);
  bool get hasLyrics => _lyrics.isNotEmpty;

  /// Sets the lyrics to sync against.
  void setLyrics(List<LyricLine> lyrics) {
    _lyrics = List.from(lyrics)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _currentLineIndex = -1;
  }

  /// Updates the current position and finds the active lyric line.
  /// Uses binary search for efficiency.
  void updatePosition(Duration position) {
    if (_lyrics.isEmpty) return;

    final newIndex = _findCurrentLine(position);
    if (newIndex != _currentLineIndex) {
      _currentLineIndex = newIndex;
      _currentLineController.add(newIndex);
    }
  }

  /// Binary search to find the current lyric line index.
  /// Returns -1 if before the first line.
  int _findCurrentLine(Duration position) {
    if (_lyrics.isEmpty) return -1;

    int low = 0;
    int high = _lyrics.length - 1;

    // Before the first line
    if (position < _lyrics.first.timestamp) return -1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (_lyrics[mid].timestamp <= position) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    // high is now the index of the last line that starts before or at the current position
    return high;
  }

  /// Gets the current lyric line text, or empty if none is active.
  String get currentText {
    if (_currentLineIndex < 0 || _currentLineIndex >= _lyrics.length) return '';
    return _lyrics[_currentLineIndex].text;
  }

  /// Gets a lyric line at a specific index.
  LyricLine? lineAt(int index) {
    if (index < 0 || index >= _lyrics.length) return null;
    return _lyrics[index];
  }

  /// Gets the index of the line closest to a given timestamp.
  int findClosestLine(Duration timestamp) {
    return _findCurrentLine(timestamp);
  }

  /// Resets the sync state.
  void reset() {
    _currentLineIndex = -1;
    _lyrics.clear();
  }

  void dispose() {
    _currentLineController.close();
  }
}
