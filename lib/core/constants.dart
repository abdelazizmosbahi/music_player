class AppConstants {
  AppConstants._();

  static const String appName = 'LocalWave';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Offline Music Player';

  // Database
  static const String dbName = 'localwave.db';
  static const int dbVersion = 1;

  // Audio
  static const Duration crossfadeDuration = Duration(seconds: 3);
  static const Duration seekInterval = Duration(seconds: 10);
  static const Duration positionUpdateInterval = Duration(milliseconds: 200);

  // Search
  static const Duration searchDebounce = Duration(milliseconds: 300);

  // Pagination
  static const int songsPerPage = 50;

  // Sleep Timer
  static const List<int> sleepTimerOptions = [15, 30, 45, 60, 90, 120];

  // Supported audio formats
  static const List<String> supportedExtensions = [
    '.mp3',
    '.m4a',
    '.aac',
    '.flac',
    '.ogg',
    '.wav',
    '.wma',
    '.opus',
  ];

  // Supported lyrics formats
  static const List<String> lyricsExtensions = ['.lrc'];

  // Storage keys
  static const String keyCrossfadeDuration = 'crossfade_duration';
  static const String keyGaplessPlayback = 'gapless_playback';
  static const String keyAccentColor = 'accent_color';
  static const String keyLastPlayedSong = 'last_played_song';
  static const String keyRecentSearches = 'recent_searches';
  static const String keyScanComplete = 'scan_complete';

  // Limit for recent searches
  static const int maxRecentSearches = 20;
}
