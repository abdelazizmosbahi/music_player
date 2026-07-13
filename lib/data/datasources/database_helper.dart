import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../core/constants.dart';

class DatabaseHelper {
  static Database? _database;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Songs table
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL DEFAULT 'Unknown Artist',
        album TEXT NOT NULL DEFAULT 'Unknown Album',
        filePath TEXT NOT NULL UNIQUE,
        albumArtPath TEXT,
        durationMs INTEGER NOT NULL DEFAULT 0,
        dateAdded TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        playCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Albums table (denormalized for quick access)
    await db.execute('''
      CREATE TABLE albums (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        albumArtPath TEXT
      )
    ''');

    // Artists table (denormalized)
    await db.execute('''
      CREATE TABLE artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatarPath TEXT
      )
    ''');

    // Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Playlist-Song junction table
    await db.execute('''
      CREATE TABLE playlist_songs (
        playlistId TEXT NOT NULL,
        songId TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (playlistId, songId),
        FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (songId) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    // Playback history table
    await db.execute('''
      CREATE TABLE playback_history (
        songId TEXT NOT NULL,
        playedAt TEXT NOT NULL,
        playCount INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (songId, playedAt),
        FOREIGN KEY (songId) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    // Create indices for faster queries
    await db.execute('CREATE INDEX idx_songs_artist ON songs(artist)');
    await db.execute('CREATE INDEX idx_songs_album ON songs(album)');
    await db.execute('CREATE INDEX idx_songs_favorite ON songs(isFavorite)');
    await db.execute('CREATE INDEX idx_songs_title ON songs(title)');
    await db.execute('CREATE INDEX idx_songs_dateAdded ON songs(dateAdded)');
    await db.execute('CREATE INDEX idx_playlist_songs_playlistId ON playlist_songs(playlistId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  // Generic CRUD helpers

  Future<void> insert(String table, Map<String, dynamic> data, {ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: conflictAlgorithm);
  }

  Future<void> insertAll(String table, List<Map<String, dynamic>> data, {ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) async {
    final db = await database;
    final batch = db.batch();
    for (final item in data) {
      batch.insert(table, item, conflictAlgorithm: conflictAlgorithm);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> query(String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> queryById(String table, String id) async {
    final db = await database;
    final results = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWhere(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
