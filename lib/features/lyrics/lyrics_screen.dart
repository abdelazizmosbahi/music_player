import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/datasources/lyrics_parser.dart';
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
  final TextEditingController _pasteController = TextEditingController();
  int _currentLine = -1;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _pasteController.dispose();
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

  Future<void> _saveLyrics() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;

    final currentSong = ref.read(currentSongProvider).valueOrNull;
    if (currentSong == null) return;

    setState(() => _isSaving = true);

    try {
      // Auto-detect if LRC or plain text
      final lyrics = LrcParser.autoParse(text);
      if (lyrics.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid lyrics found in input')),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      // Save to app documents dir
      final path = await savedLyricsPath(currentSong.id);
      await LrcParser.saveFile(path, lyrics);

      // Reload lyrics
      ref.invalidate(currentSongLyricsProvider);
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${lyrics.length} lines')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(currentSongLyricsProvider);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
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
              _buildTopBar(context),
              Expanded(
                child: lyricsAsync.when(
                  data: (lyrics) {
                    if (_isEditing) return _buildPasteView();
                    if (lyrics.isEmpty) return _buildNoLyrics();

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

  Widget _buildTopBar(BuildContext context) {
    final lyricsAsync = ref.watch(currentSongLyricsProvider);
    final hasLyrics = lyricsAsync.valueOrNull?.isNotEmpty ?? false;

    return Padding(
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
                ref.watch(currentSongProvider).valueOrNull?.title ?? 'No Song',
                style: AppTextStyles.labelLarge,
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // If editing existing lyrics, pre-populate the controller
              if (hasLyrics && !_isEditing) {
                final existing = lyricsAsync.valueOrNull;
                if (existing != null) {
                  _pasteController.text = LrcParser.toLrc(existing);
                }
              }
              setState(() => _isEditing = true);
            },
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              size: 22,
            ),
            tooltip: _isEditing ? 'Cancel Edit' : (hasLyrics ? 'Edit Lyrics' : 'Add Lyrics'),
          ),
        ],
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

  Widget _buildPasteView() {
    final song = ref.watch(currentSongProvider).valueOrNull;
    final hint = song?.title != null
        ? 'Paste lyrics for "${song!.title}"...\n\nYou can paste:\n  - Plain text (auto-timed every 4s)\n  - LRC format with [MM:SS.xx] timestamps'
        : 'Paste lyrics here...\n\nSupports plain text or LRC format with timestamps';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _pasteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMediumSecondary.copyWith(
                  color: AppColors.textTertiary.withOpacity(0.6)),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _isEditing = false;
                    _pasteController.clear();
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.textTertiary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLyrics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.background),
                        )
                      : const Text('Save Lyrics'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildNoLyrics() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics_outlined, size: 64,
            color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Lyrics Available', style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Paste lyrics directly or add an .lrc file\nwith the same name as the audio.',
            style: AppTextStyles.bodySmallSecondary, textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Paste Lyrics'),
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
