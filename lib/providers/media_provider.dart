import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/song.dart';
import '../data/repositories/media_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/playlist_repository.dart';
import '../data/datasources/lyrics_parser.dart';
import '../data/models/lyric_line.dart';
import '../services/audio_player_service.dart';
import '../services/lyrics_sync_service.dart';
import '../services/sleep_timer_service.dart';
import '../services/dynamic_color_service.dart';

// ─── Audio Service ────────────────────────────────────────────

final audioServiceProvider = Provider<AudioPlayerService>((ref) {
  throw UnimplementedError('AudioService not initialized — override in main.dart');
});

// ─── Repositories ─────────────────────────────────────────────

final mediaRepositoryProvider = Provider<MediaRepository>((ref) => MediaRepository());
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) => FavoritesRepository());
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) => PlaylistRepository());

// ─── Services ─────────────────────────────────────────────────

final lyricsSyncServiceProvider = Provider<LyricsSyncService>((ref) => LyricsSyncService());
final sleepTimerServiceProvider = Provider<SleepTimerService>((ref) => SleepTimerService());
final dynamicColorServiceProvider = Provider<DynamicColorService>((ref) => DynamicColorService());

// ─── Derived Player State (from real audio service) ──────────

final currentSongProvider = Provider<Song?>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.currentSong;
});

final isPlayingProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playingStream;
});

final playerPositionProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.positionStream;
});

final playerDurationProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.durationStream;
});

final queueProvider = Provider<List<Song>>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.queue;
});

final queueIndexProvider = Provider<int>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.currentIndex;
});

final shuffleEnabledProvider = Provider<bool>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.shuffleEnabled;
});

final repeatModeProvider = Provider<RepeatMode>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.repeatMode;
});

// ─── Song Lists ───────────────────────────────────────────────

final allSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.getAllSongs();
});

final recentlyAddedProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.getRecentlyAdded(limit: 20);
});

final mostPlayedProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.getMostPlayed(limit: 20);
});

final recentlyPlayedProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.getRecentlyPlayed(limit: 20);
});

final favoriteSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.getFavoriteSongs();
});

final allAlbumsProvider = FutureProvider((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.getAllAlbums();
});

final allArtistsProvider = FutureProvider((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.getAllArtists();
});

// ─── Playlists ────────────────────────────────────────────────

final playlistsProvider = FutureProvider((ref) async {
  final repo = ref.watch(playlistRepositoryProvider);
  return repo.getAllPlaylists();
});

// ─── Search ───────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.searchSongs(query);
});

// ─── Lyrics ───────────────────────────────────────────────────

final currentSongLyricsProvider = FutureProvider<List<LyricLine>>((ref) async {
  final currentSong = ref.watch(currentSongProvider);
  if (currentSong == null) return [];
  try {
    final lrcPath = currentSong.filePath
        .replaceAll(RegExp(r'\.(mp3|m4a|flac|ogg|wav|opus)$'), '.lrc');
    return await LrcParser.parseFile(lrcPath);
  } catch (e) {
    return [];
  }
});

// ─── Media Scanner State ──────────────────────────────────────

final isScanningProvider = StateProvider<bool>((ref) => false);

final hasMediaProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.hasMedia();
});

final refreshMediaProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.refreshMediaLibrary();
});

/// Force-refresh all data by invalidating all providers.
void refreshAllData(WidgetRef ref) {
  ref.invalidate(allSongsProvider);
  ref.invalidate(recentlyAddedProvider);
  ref.invalidate(mostPlayedProvider);
  ref.invalidate(recentlyPlayedProvider);
  ref.invalidate(favoriteSongsProvider);
  ref.invalidate(allAlbumsProvider);
  ref.invalidate(allArtistsProvider);
  ref.invalidate(playlistsProvider);
  ref.invalidate(hasMediaProvider);
}
