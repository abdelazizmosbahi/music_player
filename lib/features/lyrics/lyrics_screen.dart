import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/lyric_line.dart';
import '../../providers/media_provider.dart';
import '../../services/lyrics_sync_service.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentLine = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    final targetOffset = (index * 60.0) - 150.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(currentSongLyricsProvider);
    final currentSong = ref.watch(currentSongProvider);
    final positionAsync = ref.watch(playerPositionProvider);
    final lyricsSync = ref.read(lyricsSyncServiceProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceElevated, AppColors.background],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                    ),
                    Column(
                      children: [
                        Text('LYRICS', style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary, letterSpacing: 1.2)),
                        const SizedBox(height: 2),
                        Text(
                          currentSong?.title ?? 'No Song',
                          style: AppTextStyles.labelLarge,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Lyrics content
              Expanded(
                child: lyricsAsync.when(
                  data: (lyrics) {
                    if (lyrics.isEmpty) return _buildNoLyrics();

                    // Listen to position and update lyrics sync
                    return positionAsync.when(
                      data: (position) {
                        lyricsSync.setLyrics(lyrics);
                        lyricsSync.updatePosition(position);
                        final newIndex = lyricsSync.currentLineIndex;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (newIndex != _currentLine && newIndex >= 0) {
                            setState(() => _currentLine = newIndex);
                            _scrollToLine(newIndex);
                          }
                        });

                        return _buildLyricsList(lyrics, newIndex >= 0 ? newIndex : 3);
                      },
                      loading: () => _buildLyricsList(lyrics, -1),
                      error: (_, __) => _buildLyricsList(lyrics, -1),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent)),
                  error: (_, __) => _buildNoLyrics(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsList(List<LyricLine> lyrics, int activeIndex) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final line = lyrics[index];
        final isActive = index == activeIndex;
        final isPast = index < activeIndex;

        return GestureDetector(
          onTap: () {
            setState(() => _currentLine = index);
            _scrollToLine(index);
            // Seek to this line's timestamp
            ref.read(audioServiceProvider).seek(line.timestamp);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: isActive
                  ? AppTextStyles.lyricActive
                  : isPast ? AppTextStyles.lyricPast : AppTextStyles.lyricInactive,
              child: Text(line.text, textAlign: TextAlign.center),
            ),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: (index * 20).clamp(0, 400)),
              duration: 300.ms,
            );
      },
    );
  }

  Widget _buildNoLyrics() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics_outlined, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Lyrics Available', style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Add a .lrc file with the same name\nas the audio file to see lyrics here.',
            style: AppTextStyles.bodySmallSecondary, textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Import Lyrics'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
