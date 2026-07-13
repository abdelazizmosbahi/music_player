import '../datasources/database_helper.dart';
import '../models/song.dart';

class FavoritesRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Toggles the favorite status of a song. Returns the new state.
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

  /// Returns true if the song is favorited.
  Future<bool> isFavorite(String songId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT isFavorite FROM songs WHERE id = ?',
      [songId],
    );
    if (result.isEmpty) return false;
    return (result.first['isFavorite'] as int) == 1;
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

  /// Returns the count of favorite songs.
  Future<int> getFavoriteCount() async {
    return _db.count('songs', where: 'isFavorite = ?', whereArgs: [1]);
  }

  /// Removes all favorites (does not delete songs).
  Future<void> clearAllFavorites() async {
    final db = await _db.database;
    await db.rawUpdate('UPDATE songs SET isFavorite = 0');
  }
}
