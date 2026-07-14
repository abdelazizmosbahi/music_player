import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/duration_formatter.dart';
import '../../shared_widgets/album_art_display.dart';
import '../../providers/media_provider.dart';
import '../../services/audio_handler.dart';
import '../../data/models/song.dart';
import '../lyrics/lyrics_screen.dart';
import '../queue/queue_screen.dart';

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
              Expanded(
                flex: 5,
                child: Center(
                  child: Hero(
                    tag: 'album_art_${song.id}',
                    child: AlbumArtDisplay(
                      songId: int.tryParse(song.id),
                      title: song.title,
                      size: artSize,
                      borderRadius: 20,
                    ),
                  ),
                ),
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
            isActive: ref.watch(shuffleEnabledProvider),
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
            icon: _repeatIcon(ref.watch(repeatModeProvider)),
            isActive: ref.watch(repeatModeProvider) != TrackRepeatMode.off,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomAction(icon: Icons.lyrics_rounded, label: 'Lyrics', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LyricsScreen()));
          }),
          _BottomAction(icon: Icons.share_rounded, label: 'Share', onTap: () {}),
          _BottomAction(icon: Icons.queue_music_rounded, label: 'Queue', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QueueScreen()));
          }),
          _BottomAction(icon: Icons.equalizer_rounded, label: 'EQ', onTap: () {}),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 300.ms);
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
                onTap: () { audioService.addToQueue(song); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: const Text('Play Next'),
                onTap: () { audioService.addPlayNext(song); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.timer_rounded),
                title: const Text('Sleep Timer'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
