import 'song.dart';

class Album {
  final String id;
  final String title;
  final String artist;
  final String? albumArtPath;
  final List<Song> songs;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArtPath,
    this.songs = const [],
  });

  int get songCount => songs.length;

  Duration get totalDuration {
    return songs.fold(Duration.zero, (sum, song) => sum + song.duration);
  }

  Album copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArtPath,
    bool clearAlbumArt = false,
    List<Song>? songs,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtPath: clearAlbumArt ? null : (albumArtPath ?? this.albumArtPath),
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumArtPath': albumArtPath,
    };
  }

  factory Album.fromMap(Map<String, dynamic> map, {List<Song> songs = const []}) {
    return Album(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? 'Unknown Album',
      artist: (map['artist'] as String?) ?? 'Unknown Artist',
      albumArtPath: map['albumArtPath'] as String?,
      songs: songs,
    );
  }

  /// Groups a list of songs into albums.
  static List<Album> fromSongs(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final song in songs) {
      final key = '${song.album}|${song.artist}';
      map.putIfAbsent(key, () => []).add(song);
    }

    return map.entries.map((entry) {
      final songsList = entry.value;
      final first = songsList.first;
      return Album(
        id: first.album.isNotEmpty ? first.album.hashCode.toString() : 'unknown',
        title: first.album.isNotEmpty ? first.album : 'Unknown Album',
        artist: first.artist,
        albumArtPath: first.albumArtPath,
        songs: songsList,
      );
    }).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
