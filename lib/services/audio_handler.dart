import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/song.dart';

class LocalWaveAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final List<Song> _queue = [];
  int _currentIndex = -1;
  bool _shuffleEnabled = false;
  TrackRepeatMode _repeatMode = TrackRepeatMode.off;
  final bool _isStub;

  /// Broadcast streams for reactive shuffle/repeat state.
  final StreamController<bool> _shuffleController = StreamController<bool>.broadcast();
  final StreamController<TrackRepeatMode> _repeatController = StreamController<TrackRepeatMode>.broadcast();
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<TrackRepeatMode> get repeatStream => _repeatController.stream;

  AudioPlayer get player => _player;
  List<Song> get songQueue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;

  LocalWaveAudioHandler() : _isStub = false {
    _init();
  }

  /// Stub handler — does nothing. Used when AudioService.init fails.
  LocalWaveAudioHandler.stub() : _isStub = true;

  void _init() {
    // Emit initial state so StreamProviders get a value immediately
    _shuffleController.add(_shuffleEnabled);
    _repeatController.add(_repeatMode);

    // Listen to player state changes and broadcast them
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (duration != null) {
        final currentMediaItem = mediaItem.value;
        if (currentMediaItem != null) {
          mediaItem.add(currentMediaItem.copyWith(duration: duration));
        }
      }
    });

    // Handle song completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onSongComplete();
      }
    });
  }

  /// Maps just_audio PlaybackState to audio_service PlaybackState.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Converts a Song to a MediaItem for audio_service.
  MediaItem _songToMediaItem(Song song) {
    final artUri = song.id.isNotEmpty
        ? Uri.parse('content://media/external/audio/media/${song.id}/albumart')
        : null;
    return MediaItem(
      id: song.filePath,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: artUri,
      extras: {
        'id': song.id,
        'filePath': song.filePath,
        'albumArtPath': song.albumArtPath,
      },
    );
  }

  // ─── Public API ─────────────────────────────────────────────

  /// Sets the queue and optionally starts playing from a given index.
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue.clear();
    _queue.addAll(songs);
    _currentIndex = startIndex.clamp(0, songs.length - 1);

    // Update the audio_service queue
    final mediaItems = songs.map(_songToMediaItem).toList();
    queue.add(mediaItems);

    await _playCurrent();
  }

  /// Plays a single song, replacing the queue with all provided songs.
  Future<void> playSong(Song song, {List<Song>? fromList}) async {
    final songs = fromList ?? [song];
    final index = songs.indexWhere((s) => s.id == song.id);

    await setQueue(songs, startIndex: index >= 0 ? index : 0);
  }

  /// Adds a song to play next in the queue.
  Future<void> addPlayNext(Song song) async {
    final insertIndex = _currentIndex + 1;
    _queue.insert(insertIndex, song);

    final mediaItems = _queue.map(_songToMediaItem).toList();
    queue.add(mediaItems);
  }

  /// Adds a song to the end of the queue.
  Future<void> addToQueue(Song song) async {
    _queue.add(song);
    final mediaItems = _queue.map(_songToMediaItem).toList();
    queue.add(mediaItems);
  }

  /// Removes a song from the queue at the given index.
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _currentIndex >= _queue.length) {
      _currentIndex = _queue.length - 1;
    }

    final mediaItems = _queue.map(_songToMediaItem).toList();
    queue.add(mediaItems);
  }

  /// Reorders a song within the queue.
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;

    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    // Update current index
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    final mediaItems = _queue.map(_songToMediaItem).toList();
    queue.add(mediaItems);
  }

  /// Clears the queue and stops playback.
  Future<void> clearQueue() async {
    _queue.clear();
    _currentIndex = -1;
    await _player.stop();
    queue.add(<MediaItem>[]);
    mediaItem.add(null);
  }

  // ─── AudioHandler overrides ─────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_repeatMode == TrackRepeatMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _playCurrent();
    } else if (_repeatMode == TrackRepeatMode.all) {
      _currentIndex = 0;
      await _playCurrent();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      await _playCurrent();
    } else if (_repeatMode == TrackRepeatMode.all) {
      _currentIndex = _queue.length - 1;
      await _playCurrent();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      await _playCurrent();
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleEnabled = shuffleMode == AudioServiceShuffleMode.all;
    _player.setShuffleModeEnabled(_shuffleEnabled);
    _shuffleController.add(_shuffleEnabled);
  }

  /// Cycles through repeat modes: off -> all -> one -> off.
  void cycleTrackRepeatMode() {
    switch (_repeatMode) {
      case TrackRepeatMode.off:
        _repeatMode = TrackRepeatMode.all;
        _player.setLoopMode(LoopMode.all);
        break;
      case TrackRepeatMode.all:
        _repeatMode = TrackRepeatMode.one;
        _player.setLoopMode(LoopMode.one);
        break;
      case TrackRepeatMode.one:
        _repeatMode = TrackRepeatMode.off;
        _player.setLoopMode(LoopMode.off);
        break;
    }
    _repeatController.add(_repeatMode);
  }

  TrackRepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;

  // ─── Private helpers ────────────────────────────────────────

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    final song = _queue[_currentIndex];
    mediaItem.add(_songToMediaItem(song));

    try {
      await _player.setFilePath(song.filePath);
      await _player.play();
    } catch (e) {
      // If the file can't be played, try to skip to next
      if (_currentIndex < _queue.length - 1) {
        await skipToNext();
      }
    }
  }

  void _onSongComplete() {
    if (_repeatMode == TrackRepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else {
      skipToNext();
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  @override
  Future<void> onCustomAction(String name, dynamic args) async {
    switch (name) {
      case 'setShuffleMode':
        final enabled = (args as Map<String, dynamic>)['enabled'] as bool;
        await setShuffleMode(enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
        break;
      case 'cycleRepeatMode':
        cycleTrackRepeatMode();
        break;
      case 'addPlayNext':
        final song = (args as Map<String, dynamic>)['song'] as Song;
        await addPlayNext(song);
        break;
      case 'addToQueue':
        final song = (args as Map<String, dynamic>)['song'] as Song;
        await addToQueue(song);
        break;
      case 'updateSongInfo':
        final updated = (args as Map<String, dynamic>)['song'] as Song;
        _updateSongInQueue(updated);
        break;
    }
  }

  /// Updates a song's metadata in the in-memory queue and refreshes media item.
  void _updateSongInQueue(Song updated) {
    if (_currentIndex >= 0 && _currentIndex < _queue.length && _queue[_currentIndex].id == updated.id) {
      _queue[_currentIndex] = updated;
      mediaItem.add(_songToMediaItem(updated));
    } else {
      for (int i = 0; i < _queue.length; i++) {
        if (_queue[i].id == updated.id) {
          _queue[i] = updated;
          break;
        }
      }
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Represents the repeat mode.
enum TrackRepeatMode { off, all, one }
