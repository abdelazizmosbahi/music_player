import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/duration_formatter.dart';
import '../../shared_widgets/album_art_display.dart';
import '../../data/datasources/lyrics_parser.dart';
import '../../data/models/lyric_line.dart';
import '../../providers/media_provider.dart';
import '../../services/audio_handler.dart';
import '../../services/lyrics_sync_service.dart';
import '../../data/models/song.dart';
import '../../data/repositories/media_repository.dart';
import '../lyrics/lyrics_screen.dart';
import '../queue/queue_screen.dart';
import '../sleep_timer/sleep_timer_screen.dart';

// ─── Album Art + Lyrics Line (self-contained, no parent rebuild) ───

class _AlbumArtWithLyrics extends ConsumerStatefulWidget {
  final Song song;
  final double artSize;
  const _AlbumArtWithLyrics({required this.song, required this.artSize});

  @override
  ConsumerState<_AlbumArtWithLyrics> createState() => _AlbumArtWithLyricsState();
}

class _AlbumArtWithLyricsState extends ConsumerState<_AlbumArtWithLyrics> {
  final LyricsSyncService _lyricsSync = LyricsSyncService();

  @override
  void dispose() {
    _lyricsSync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(currentSongLyricsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Center(
            child: KeyedSubtree(
              key: ValueKey('art_${widget.song.id}'),
              child: Hero(
                tag: 'album_art_${widget.song.id}',
                child: AlbumArtDisplay(
                  songId: int.tryParse(widget.song.id),
                  title: widget.song.title,
                  size: widget.artSize,
                  borderRadius: 20,
                ),
              ),
            ),
          ),
        ),
        lyricsAsync.when(
          data: (lyrics) {
            if (lyrics.isEmpty) return const SizedBox(height: 40);
            return _CurrentLyricLine(
              lyrics: lyrics,
              lyricsSync: _lyricsSync,
            );
          },
          loading: () => const SizedBox(height: 40),
          error: (_, __) => const SizedBox(height: 40),
        ),
      ],
    );
  }
}

// ─── Current Lyric Line (listens to position internally) ──────────

class _CurrentLyricLine extends ConsumerStatefulWidget {
  final List<LyricLine> lyrics;
  final LyricsSyncService lyricsSync;
  const _CurrentLyricLine({
    required this.lyrics,
    required this.lyricsSync,
  });

  @override
  ConsumerState<_CurrentLyricLine> createState() => _CurrentLyricLineState();
}

class _CurrentLyricLineState extends ConsumerState<_CurrentLyricLine> {
  @override
  void initState() {
    super.initState();
    widget.lyricsSync.setLyrics(widget.lyrics);
  }

  @override
  void didUpdateWidget(covariant _CurrentLyricLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics != widget.lyrics) {
      widget.lyricsSync.setLyrics(widget.lyrics);
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(playerPositionProvider);
    final position = positionAsync.valueOrNull ?? Duration.zero;
    widget.lyricsSync.updatePosition(position);
    final idx = widget.lyricsSync.currentLineIndex;

    final text = (idx >= 0 && idx < widget.lyrics.length)
        ? widget.lyrics[idx].text
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const LyricsScreen(),
        ));
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        alignment: Alignment.center,
        child: Text(
          text.isNotEmpty ? text : 'Tap for lyrics',
          style: AppTextStyles.bodyMedium.copyWith(
            color: text.isNotEmpty
                ? AppColors.textPrimary
                : AppColors.textTertiary.withOpacity(0.5),
            fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── Main Now Playing Screen ─────────────────────────────────────

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final isPlaying = isPlayingAsync.valueOrNull ?? false;
    final positionAsync = ref.watch(playerPositionProvider);
    final durationAsync = ref.watch(playerDurationProvider);
    final audioService = ref.read(audioServiceProvider);

    final song = currentSong ?? Song(
      id: '0', title: 'No Song Selected', artist: 'Unknown Artist',
      album: '', filePath: '', duration: const Duration(minutes: 3, seconds: 30),
      dateAdded: DateTime.now(),
    );

    final position = positionAsync.valueOrNull ?? Duration.zero;
    final duration = durationAsync.valueOrNull ?? song.duration;

    final bgColor = HSLColor.fromAHSL(1.0, (song.title.hashCode % 360).abs().toDouble(), 0.5, 0.2).toColor();

    final sliderPosition = _isDragging
        ? Duration(milliseconds: (_dragValue * duration.inMilliseconds).toInt())
        : position;

    final progress = duration.inMilliseconds > 0
        ? (sliderPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final double artSize = MediaQuery.of(context).size.width * 0.65;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor.withOpacity(0.5), AppColors.surfaceElevated, AppColors.background],
            stops: const [0.0, 0.35, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, song),
              const SizedBox(height: 8),
              // Album art + live lyrics line — self-contained, won't flash
              Expanded(
                flex: 5,
                child: _AlbumArtWithLyrics(song: song, artSize: artSize),
              ),
              Expanded(flex: 2, child: _buildSongInfo(song)),
              _buildProgressBar(sliderPosition, duration, progress, audioService),
              Expanded(flex: 2, child: _buildControls(isPlaying, audioService)),
              _buildBottomActions(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          ),
          Flexible(
            child: Column(
              children: [
                Text('PLAYING FROM', style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary, letterSpacing: 1.2,
                )),
                const SizedBox(height: 2),
                Text(
                  song.album.isNotEmpty ? song.album : 'Local Library',
                  style: AppTextStyles.labelLarge,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showMoreOptions(song),
            icon: const Icon(Icons.more_vert_rounded, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, style: AppTextStyles.nowPlayingTitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(song.artist, style: AppTextStyles.nowPlayingArtist,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          _FavoriteButton(songId: song.id),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildProgressBar(Duration position, Duration duration, double progress, audioService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.textPrimary,
              inactiveTrackColor: AppColors.textTertiary.withOpacity(0.2),
              thumbColor: AppColors.textPrimary,
              overlayColor: AppColors.accent.withOpacity(0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                setState(() { _isDragging = true; _dragValue = value; });
              },
              onChangeStart: (_) => setState(() => _isDragging = true),
              onChangeEnd: (value) {
                setState(() => _isDragging = false);
                final pos = Duration(milliseconds: (value * duration.inMilliseconds).toInt());
                audioService.seek(pos);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DurationFormatter.format(position), style: AppTextStyles.bodySmallSecondary),
                Text(DurationFormatter.format(duration), style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildControls(bool isPlaying, audioService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.shuffle_rounded,
            isActive: ref.watch(shuffleEnabledProvider).valueOrNull ?? false,
            size: 22,
            onTap: () => audioService.toggleShuffle(),
          ),
          _ControlButton(
            icon: Icons.skip_previous_rounded,
            size: 32,
            onTap: () => audioService.skipToPrevious(),
          ),
          _MainPlayButton(
            isPlaying: isPlaying,
            onTap: () => audioService.togglePlayPause(),
          ),
          _ControlButton(
            icon: Icons.skip_next_rounded,
            size: 32,
            onTap: () => audioService.skipToNext(),
          ),
          _ControlButton(
            icon: _repeatIcon(ref.watch(repeatModeProvider).valueOrNull ?? TrackRepeatMode.off),
            isActive: (ref.watch(repeatModeProvider).valueOrNull ?? TrackRepeatMode.off) != TrackRepeatMode.off,
            size: 22,
            onTap: () => audioService.cycleRepeat(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }

  IconData _repeatIcon(TrackRepeatMode mode) {
    switch (mode) {
      case TrackRepeatMode.one: return Icons.repeat_one_rounded;
      case TrackRepeatMode.all: return Icons.repeat_rounded;
      case TrackRepeatMode.off: return Icons.repeat_rounded;
    }
  }

  Widget _buildBottomActions() {
    final song = ref.watch(currentSongProvider).valueOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomAction(icon: Icons.lyrics_rounded, label: 'Lyrics', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LyricsScreen()));
          }),
          _BottomAction(icon: Icons.share_rounded, label: 'Share', onTap: () {
            if (song != null) _shareSong(song);
          }),
          _BottomAction(icon: Icons.queue_music_rounded, label: 'Queue', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QueueScreen()));
          }),
          _BottomAction(icon: Icons.equalizer_rounded, label: 'EQ', onTap: () {
            _showEqualizer();
          }),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 300.ms);
  }

  void _shareSong(Song song) {
    final text = '${song.title} - ${song.artist}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $text'),
        action: SnackBarAction(
          label: 'Copy',
          textColor: AppColors.accent,
          onPressed: () {
            // Copy song info to clipboard would go here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Song info copied')),
            );
          },
        ),
      ),
    );
  }

  void _showEqualizer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Equalizer', style: AppTextStyles.headingMedium),
              ),
              const SizedBox(height: 16),
              _buildEqSlider('Bass', -20, 20),
              _buildEqSlider('Mid', -20, 20),
              _buildEqSlider('Treble', -20, 20),
              _buildEqSlider('Volume', 0, 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEqSlider(String label, double min, double max) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: AppTextStyles.bodySmallSecondary)),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.textTertiary.withOpacity(0.2),
                thumbColor: AppColors.textPrimary,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(value: 0, min: min, max: max, onChanged: (_) {}),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(Song song) {
    final audioService = ref.read(audioServiceProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Add to Queue'),
                onTap: () {
                  audioService.addToQueue(song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "${song.title}" to queue')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: const Text('Play Next'),
                onTap: () {
                  audioService.addPlayNext(song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${song.title}" will play next')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_rounded),
                title: const Text('Sleep Timer'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SleepTimerScreen(),
                  ));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit Song Info'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSongInfo(song);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSongInfo(Song song) {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist);
    final albumController = TextEditingController(text: song.album);
    final genreController = TextEditingController(text: song.genre);
    final yearController = TextEditingController(
      text: song.year > 0 ? song.year.toString() : '',
    );
    final lyricsController = TextEditingController();
    String? pickedArtPath;
    bool _lyricsLoaded = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Load lyrics lazily
          if (!_lyricsLoaded) {
            _lyricsLoaded = true;
            savedLyricsPath(song.id).then((path) async {
              final file = File(path);
              if (await file.exists()) {
                final content = await file.readAsString();
                if (content.isNotEmpty && lyricsController.text.isEmpty) {
                  setSheetState(() => lyricsController.text = content);
                }
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Edit Song Info', style: AppTextStyles.headingMedium),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover Art
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                  );
                                  if (result != null && result.files.single.path != null) {
                                    setSheetState(() => pickedArtPath = result.files.single.path);
                                  }
                                },
                                child: Container(
                                  width: 120, height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.surface,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: pickedArtPath != null
                                      ? Image.file(File(pickedArtPath!), fit: BoxFit.cover)
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AlbumArtDisplay(
                                              songId: int.tryParse(song.id),
                                              title: song.title,
                                              size: 120,
                                              borderRadius: 12,
                                            ),
                                            Container(
                                              color: Colors.black45,
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                color: Colors.white, size: 28,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'Tap to change cover art',
                                style: AppTextStyles.bodySmallSecondary.copyWith(
                                  color: AppColors.textTertiary),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildEditField(titleController, 'Title'),
                            const SizedBox(height: 12),
                            _buildEditField(artistController, 'Artist'),
                            const SizedBox(height: 12),
                            _buildEditField(albumController, 'Album'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildEditField(genreController, 'Genre')),
                                const SizedBox(width: 12),
                                Expanded(child: _buildEditField(yearController, 'Year',
                                  keyboardType: TextInputType.number)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Lyrics', style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: lyricsController,
                              maxLines: 6,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Paste lyrics (LRC or plain text)',
                                hintStyle: AppTextStyles.bodyMediumSecondary.copyWith(
                                  color: AppColors.textTertiary.withOpacity(0.6)),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.textTertiary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // Save all edits
                                final title = titleController.text.trim();
                                final artist = artistController.text.trim();
                                final album = albumController.text.trim();
                                final genre = genreController.text.trim();
                                final year = int.tryParse(yearController.text.trim()) ?? 0;
                                final lyricsText = lyricsController.text.trim();

                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Title cannot be empty')),
                                  );
                                  return;
                                }

                                // Save cover art to app docs
                                String? savedArtPath;
                                if (pickedArtPath != null) {
                                  final appDir = await getApplicationDocumentsDirectory();
                                  final artDir = Directory('${appDir.path}/cover_art');
                                  if (!await artDir.exists()) await artDir.create(recursive: true);
                                  final ext = pickedArtPath!.split('.').last;
                                  final dest = File('${artDir.path}/song_${song.id}.$ext');
                                  await File(pickedArtPath!).copy(dest.path);
                                  savedArtPath = dest.path;
                                }

                                // Update song model
                                final updated = song.copyWith(
                                  title: title,
                                  artist: artist,
                                  album: album,
                                  genre: genre,
                                  year: year,
                                  albumArtPath: savedArtPath ?? song.albumArtPath,
                                  clearAlbumArt: false,
                                );

                                // Save to DB
                                final repo = ref.read(mediaRepositoryProvider);
                                await repo.updateSong(updated);

                                // Update handler queue
                                ref.read(audioServiceProvider).updateCurrentSongInfo(updated);

                                // Save lyrics if provided
                                if (lyricsText.isNotEmpty) {
                                  final lyrics = LrcParser.autoParse(lyricsText);
                                  if (lyrics.isNotEmpty) {
                                    final path = await savedLyricsPath(song.id);
                                    await LrcParser.saveFile(path, lyrics);
                                    ref.invalidate(currentSongLyricsProvider);
                                  }
                                }

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Song info updated')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmallSecondary,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ─── Favorite Button with persistence ─────────────────────────

class _FavoriteButton extends ConsumerStatefulWidget {
  final String songId;
  const _FavoriteButton({required this.songId});

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final repo = ref.read(favoritesRepositoryProvider);
    final fav = await repo.isFavorite(widget.songId);
    if (mounted) setState(() => _isFav = fav);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: () async {
          final repo = ref.read(favoritesRepositoryProvider);
          final newState = await repo.toggleFavorite(widget.songId);
          setState(() => _isFav = newState);
          _controller.forward(from: 0);
        },
        child: Icon(
          _isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          color: _isFav ? AppColors.accent : AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}

// ─── Main Play Button ─────────────────────────────────────────

class _MainPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  const _MainPlayButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 68, height: 68,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.3),
            blurRadius: 16, spreadRadius: 2,
          )],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: AppColors.background, size: 38,
            key: ValueKey(isPlaying),
          ),
        ),
      ),
    );
  }
}

// ─── Small Control Button ─────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isActive;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, this.size = 24, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: isActive ? AppColors.accent : AppColors.textSecondary, size: size),
    );
  }
}

// ─── Bottom Action ────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BottomAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
