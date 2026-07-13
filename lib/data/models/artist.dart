import 'album.dart';
import 'song.dart';

class Artist {
  final String id;
  final String name;
  final String? avatarPath;
  final List<Song> songs;

  const Artist({
    required this.id,
    required this.name,
    this.avatarPath,
    this.songs = const [],
  });

  int get songCount => songs.length;

  List<Album> get albums => Album.fromSongs(songs);

  Artist copyWith({
    String? id,
    String? name,
    String? avatarPath,
    bool clearAvatar = false,
    List<Song>? songs,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map, {List<Song> songs = const []}) {
    return Artist(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? 'Unknown Artist',
      avatarPath: map['avatarPath'] as String?,
      songs: songs,
    );
  }

  /// Groups a list of songs into artists.
  static List<Artist> fromSongs(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final song in songs) {
      final key = song.artist.isNotEmpty ? song.artist : 'Unknown Artist';
      map.putIfAbsent(key, () => []).add(song);
    }

    return map.entries.map((entry) {
      final songsList = entry.value;
      return Artist(
        id: entry.key.hashCode.toString(),
        name: entry.key,
        avatarPath: songsList.first.albumArtPath,
        songs: songsList,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
