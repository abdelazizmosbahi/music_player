class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final String? albumArtPath;
  final Duration duration;
  final DateTime dateAdded;
  final bool isFavorite;
  final int playCount;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    this.albumArtPath,
    required this.duration,
    required this.dateAdded,
    this.isFavorite = false,
    this.playCount = 0,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    String? albumArtPath,
    bool clearAlbumArt = false,
    Duration? duration,
    DateTime? dateAdded,
    bool? isFavorite,
    int? playCount,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      albumArtPath: clearAlbumArt ? null : (albumArtPath ?? this.albumArtPath),
      duration: duration ?? this.duration,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'filePath': filePath,
      'albumArtPath': albumArtPath,
      'durationMs': duration.inMilliseconds,
      'dateAdded': dateAdded.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'playCount': playCount,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? 'Unknown',
      artist: (map['artist'] as String?) ?? 'Unknown Artist',
      album: (map['album'] as String?) ?? 'Unknown Album',
      filePath: map['filePath'] as String,
      albumArtPath: map['albumArtPath'] as String?,
      duration: Duration(milliseconds: (map['durationMs'] as int?) ?? 0),
      dateAdded: DateTime.tryParse(map['dateAdded'] as String? ?? '') ?? DateTime.now(),
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      playCount: (map['playCount'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';
}
