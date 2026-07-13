import 'package:uuid/uuid.dart';
import '../datasources/database_helper.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  /// Creates a new playlist.
  Future<Playlist> createPlaylist({
    required String name,
    String? description,
  }) async {
    final now = DateTime.now();
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insert('playlists', playlist.toMap());
    return playlist;
  }

  /// Returns all playlists.
  Future<List<Playlist>> getAllPlaylists() async {
    final playlistMaps = await _db.query('playlists', orderBy: 'createdAt DESC');
    final playlists = <Playlist>[];

    for (final map in playlistMaps) {
      final songIds = await getPlaylistSongIds(map['id'] as String);
      playlists.add(Playlist.fromMap(map, songIds: songIds));
    }

    return playlists;
  }

  /// Returns a playlist by its ID.
  Future<Playlist?> getPlaylistById(String id) async {
    final map = await _db.queryById('playlists', id);
    if (map == null) return null;

    final songIds = await getPlaylistSongIds(id);
    return Playlist.fromMap(map, songIds: songIds);
  }

  /// Updates a playlist's metadata.
  Future<void> updatePlaylist(String id, {String? name, String? description}) async {
    final data = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;

    await _db.update('playlists', data, id);
  }

  /// Deletes a playlist and its associations (songs are preserved).
  Future<void> deletePlaylist(String id) async {
    await _db.deleteWhere(
      'playlist_songs',
      where: 'playlistId = ?',
      whereArgs: [id],
    );
    await _db.delete('playlists', id);
  }

  /// Adds a song to a playlist.
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    // Get the current highest position
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT MAX(position) as maxPos FROM playlist_songs WHERE playlistId = ?',
      [playlistId],
    );
    final maxPos = (Sqflite.firstIntValue(result) ?? -1) + 1;

    await _db.insert('playlist_songs', {
      'playlistId': playlistId,
      'songId': songId,
      'position': maxPos,
    });

    // Update the playlist's updatedAt
    await _db.update('playlists', {
      'updatedAt': DateTime.now().toIso8601String(),
    }, playlistId);
  }

  /// Removes a song from a playlist.
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _db.deleteWhere(
      'playlist_songs',
      where: 'playlistId = ? AND songId = ?',
      whereArgs: [playlistId, songId],
    );

    await _db.update('playlists', {
      'updatedAt': DateTime.now().toIso8601String(),
    }, playlistId);
  }

  /// Reorders songs in a playlist.
  Future<void> reorderPlaylist(String playlistId, List<String> songIds) async {
    final db = await _db.database;
    final batch = db.batch();

    for (var i = 0; i < songIds.length; i++) {
      batch.rawUpdate(
        'UPDATE playlist_songs SET position = ? WHERE playlistId = ? AND songId = ?',
        [i, playlistId, songIds[i]],
      );
    }

    await batch.commit(noResult: true);

    await _db.update('playlists', {
      'updatedAt': DateTime.now().toIso8601String(),
    }, playlistId);
  }

  /// Returns the song IDs in a playlist, ordered by position.
  Future<List<String>> getPlaylistSongIds(String playlistId) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      'SELECT songId FROM playlist_songs WHERE playlistId = ? ORDER BY position ASC',
      [playlistId],
    );
    return results.map((r) => r['songId'] as String).toList();
  }

  /// Returns the songs in a playlist.
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.songId
      WHERE ps.playlistId = ?
      ORDER BY ps.position ASC
    ''', [playlistId]);
    return results.map(Song.fromMap).toList();
  }

  /// Checks if a song is in a playlist.
  Future<bool> isSongInPlaylist(String playlistId, String songId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlist_songs WHERE playlistId = ? AND songId = ?',
      [playlistId, songId],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }
}
