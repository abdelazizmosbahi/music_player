import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/song.dart';
import '../data/repositories/media_repository.dart';
import 'audio_handler.dart';

class AudioPlayerService {
  final LocalWaveAudioHandler _audioHandler;
  final MediaRepository _mediaRepository = MediaRepository();

  AudioPlayerService(this._audioHandler);

  AudioPlayer get player => _audioHandler.player;

  // ─── Streams ────────────────────────────────────────────────

  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration> get durationStream => player.durationStream.map((d) => d ?? Duration.zero);
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<bool> get playingStream => player.playingStream;
  Stream<ProcessingState> get processingStateStream => player.processingStateStream;

  Duration get position => player.position;
  Duration get duration => player.duration ?? Duration.zero;
  bool get isPlaying => player.playing;

  // ─── Current State ──────────────────────────────────────────

  Song? get currentSong => _audioHandler.currentSong;
  List<Song> get queue => _audioHandler.songQueue;
  int get currentIndex => _audioHandler.currentIndex;
  TrackRepeatMode get repeatMode => _audioHandler.repeatMode;
  bool get shuffleEnabled => _audioHandler.shuffleEnabled;

  // ─── Playback Controls ─────────────────────────────────────

  Future<void> play() => _audioHandler.play();
  Future<void> pause() => _audioHandler.pause();
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() => _audioHandler.stop();
  Future<void> seek(Duration position) => _audioHandler.seek(position);
  Future<void> skipToNext() => _audioHandler.skipToNext();
  Future<void> skipToPrevious() => _audioHandler.skipToPrevious();

  /// Seeks forward or backward by [duration] (default 10 seconds).
  void seekRelative(Duration offset) {
    final newPosition = player.position + offset;
    final clamped = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    seek(clamped);
  }

  // ─── Queue Management ──────────────────────────────────────

  /// Plays a song from a list of songs.
  Future<void> playSong(Song song, {List<Song>? fromList}) async {
    await _audioHandler.playSong(song, fromList: fromList);
    await _mediaRepository.recordPlayback(song.id);
  }

  /// Plays all songs starting from the given index.
  Future<void> playAll(List<Song> songs, {int startIndex = 0}) async {
    await _audioHandler.setQueue(songs, startIndex: startIndex);
    if (songs.isNotEmpty) {
      await _mediaRepository.recordPlayback(songs[startIndex].id);
    }
  }

  /// Plays a list of songs in order.
  Future<void> playPlaylist(List<Song> songs) async {
    await _audioHandler.setQueue(songs, startIndex: 0);
    if (songs.isNotEmpty) {
      await _mediaRepository.recordPlayback(songs.first.id);
    }
  }

  Future<void> addPlayNext(Song song) =>
      _audioHandler.customAction('addPlayNext', {'song': song});

  Future<void> addToQueue(Song song) =>
      _audioHandler.customAction('addToQueue', {'song': song});

  Future<void> removeFromQueue(int index) =>
      _audioHandler.removeFromQueue(index);

  Future<void> reorderQueue(int oldIndex, int newIndex) =>
      _audioHandler.reorderQueue(oldIndex, newIndex);

  Future<void> clearQueue() => _audioHandler.clearQueue();

  // ─── Shuffle & Repeat ───────────────────────────────────────

  void toggleShuffle() {
    final newMode = !shuffleEnabled;
    _audioHandler.customAction('setShuffleMode', {'enabled': newMode});
  }

  void cycleRepeat() {
    _audioHandler.customAction('cycleRepeatMode', null);
  }

  // ─── Helpers ────────────────────────────────────────────────

  /// Returns the progress as a value between 0.0 and 1.0.
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Sets the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    await player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Sets the playback speed (0.5 to 2.0).
  Future<void> setSpeed(double speed) async {
    await player.setSpeed(speed.clamp(0.5, 2.0));
  }

  /// Disposes the player service.
  Future<void> dispose() async {
    await _audioHandler.dispose();
  }
}
