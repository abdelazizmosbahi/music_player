class PlaybackHistory {
  final String songId;
  final DateTime playedAt;
  final int playCount;

  const PlaybackHistory({
    required this.songId,
    required this.playedAt,
    this.playCount = 1,
  });

  PlaybackHistory copyWith({
    String? songId,
    DateTime? playedAt,
    int? playCount,
  }) {
    return PlaybackHistory(
      songId: songId ?? this.songId,
      playedAt: playedAt ?? this.playedAt,
      playCount: playCount ?? this.playCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'songId': songId,
      'playedAt': playedAt.toIso8601String(),
      'playCount': playCount,
    };
  }

  factory PlaybackHistory.fromMap(Map<String, dynamic> map) {
    return PlaybackHistory(
      songId: map['songId'] as String,
      playedAt: DateTime.tryParse(map['playedAt'] as String? ?? '') ?? DateTime.now(),
      playCount: (map['playCount'] as int?) ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackHistory &&
          runtimeType == other.runtimeType &&
          songId == other.songId;

  @override
  int get hashCode => songId.hashCode;
}
