import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants.dart';
import '../models/song.dart';

class LocalMediaScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Requests the necessary storage permissions.
  Future<bool> requestPermission() async {
    // Android 13+ uses READ_MEDIA_AUDIO, older versions use READ_EXTERNAL_STORAGE
    final status = await Permission.audio.request();
    if (status.isGranted) return true;

    // Fallback for older Android versions
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Checks if permission is already granted.
  Future<bool> hasPermission() async {
    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) return true;

    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }

  /// Scans the device for all audio files and returns them as Song objects.
  Future<List<Song>> scanAllSongs() async {
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) return [];
    }

    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );

      return songs
          .where((audio) => _isSupportedFormat(audio.data))
          .map(_mapToSong)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Scans for songs by a specific artist.
  Future<List<Song>> scanSongsByArtist(String artistName) async {
    final allSongs = await scanAllSongs();
    return allSongs.where((s) => s.artist == artistName).toList();
  }

  /// Scans for songs in a specific album.
  Future<List<Song>> scanSongsByAlbum(String albumName) async {
    final allSongs = await scanAllSongs();
    return allSongs.where((s) => s.album == albumName).toList();
  }

  /// Gets album art for a specific song.
  Future<String?> getAlbumArt(int songId) async {
    try {
      final art = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
      );
      // on_audio_query returns artwork as bytes, we don't extract path here
      // Album art will be handled via the queryArtwork widget or cached bytes
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Maps an AudioModel from on_audio_query to our Song model.
  Song _mapToSong(AudioModel audio) {
    return Song(
      id: audio.id.toString(),
      title: audio.title.isNotEmpty ? audio.title : 'Unknown',
      artist: audio.artist ?? 'Unknown Artist',
      album: audio.album ?? 'Unknown Album',
      filePath: audio.data,
      duration: Duration(milliseconds: audio.duration ?? 0),
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
        (audio.dateAdded ?? 0) * 1000,
      ),
    );
  }

  /// Checks if a file path has a supported audio extension.
  bool _isSupportedFormat(String path) {
    final lower = path.toLowerCase();
    return AppConstants.supportedExtensions.any(lower.endsWith);
  }
}
