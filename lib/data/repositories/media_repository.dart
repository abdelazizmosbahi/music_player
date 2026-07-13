import 'package:uuid/uuid.dart';
import '../datasources/database_helper.dart';
import '../datasources/local_media_scanner.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';

class MediaRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final LocalMediaScanner _scanner = LocalMediaScanner();
  static const _uuid = Uuid();

  /// Scans device storage and caches all songs in the database.
  Future<List<Song>> refreshMediaLibrary() async {
    final deviceSongs = await _scanner.scanAllSongs();

    if (deviceSongs.isNotEmpty) {
      // Clear existing songs and re-insert
      await _db.clearTable('songs');
      await _db.insertAll(
        'songs',
        deviceSongs.map((s) => s.toMap()).toList(),
      );
    }

    return deviceSongs;
  }

  /// Returns all cached songs from the database.
  Future<List<Song>> getAllSongs() async {
    final maps = await _db.query('songs', orderBy: 'title ASC');
    return maps.map(Song.fromMap).toList();
  }

  /// Returns songs sorted by date added (most recent first).
  Future<List<Song>> getRecentlyAdded({int limit = 20}) async {
    final maps = await _db.query(
      'songs',
      orderBy: 'dateAdded DESC',
      limit: limit,
    );
    return maps.map(Song.fromMap).toList();
  }

  /// Returns songs sorted by play count (most played first).
  Future<List<Song>> getMostPlayed({int limit = 20}) async {
    final maps = await _db.query(
      'songs',
      orderBy: 'playCount DESC',
      limit: limit,
    );
    return maps.map(Song.fromMap).toList();
  }

  /// Searches songs by title, artist, or album.
  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return [];

    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT * FROM songs
      WHERE title LIKE ? OR artist LIKE ? OR album LIKE ?
      ORDER BY title ASC
    ''', ['%$query%', '%$query%', '%$query%']);

    return results.map(Song.fromMap).toList();
  }

  /// Returns a song by its ID.
  Future<Song?> getSongById(String id) async {
    final map = await _db.queryById('songs', id);
    return map != null ? Song.fromMap(map) : null;
  }

  /// Returns a song by its file path.
  Future<Song?> getSongByPath(String path) async {
    final maps = await _db.query(
      'songs',
      where: 'filePath = ?',
      whereArgs: [path],
      limit: 1,
    );
    return maps.isNotEmpty ? Song.fromMap(maps.first) : null;
  }

  /// Increments the play count for a song.
  Future<void> incrementPlayCount(String songId) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE songs SET playCount = playCount + 1 WHERE id = ?',
      [songId],
    );
  }

  /// Toggles the favorite status of a song.
  Future<bool> toggleFavorite(String songId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT isFavorite FROM songs WHERE id = ?',
      [songId],
    );

    if (result.isEmpty) return false;

    final current = (result.first['isFavorite'] as int) == 1;
    final newValue = current ? 0 : 1;

    await db.rawUpdate(
      'UPDATE songs SET isFavorite = ? WHERE id = ?',
      [newValue, songId],
    );

    return !current;
  }

  /// Returns all favorite songs.
  Future<List<Song>> getFavoriteSongs() async {
    final maps = await _db.query(
      'songs',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );
    return maps.map(Song.fromMap).toList();
  }

  /// Returns all albums (grouped from songs).
  Future<List<Album>> getAllAlbums() async {
    final songs = await getAllSongs();
    return Album.fromSongs(songs);
  }

  /// Returns all artists (grouped from songs).
  Future<List<Artist>> getAllArtists() async {
    final songs = await getAllSongs();
    return Artist.fromSongs(songs);
  }

  /// Records a playback in history.
  Future<void> recordPlayback(String songId) async {
    await _db.insert('playback_history', {
      'songId': songId,
      'playedAt': DateTime.now().toIso8601String(),
      'playCount': 1,
    });
    await incrementPlayCount(songId);
  }

  /// Returns recently played songs (unique, most recent first).
  Future<List<Song>> getRecentlyPlayed({int limit = 20}) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playback_history ph ON s.id = ph.songId
      GROUP BY s.id
      ORDER BY MAX(ph.playedAt) DESC
      LIMIT ?
    ''', [limit]);

    return results.map(Song.fromMap).toList();
  }

  /// Returns the total song count.
  Future<int> getSongCount() async {
    return _db.count('songs');
  }

  /// Returns true if the media library has been scanned.
  Future<bool> hasMedia() async {
    final count = await getSongCount();
    return count > 0;
  }
}
