import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song.dart';
import '../../../providers/media_provider.dart';
import '../../../shared_widgets/song_tile.dart';

class SongsTab extends ConsumerStatefulWidget {
  const SongsTab({super.key});

  @override
  ConsumerState<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<SongsTab> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _sectionOffsets = {};
  String _currentLetter = '';
  bool _isDraggingIndex = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter) {
    final offset = _sectionOffsets[letter];
    if (offset != null && _scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Map<String, List<Song>> _groupByLetter(List<Song> songs) {
    final sorted = List<Song>.from(songs)
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final groups = <String, List<Song>>{};
    for (final song in sorted) {
      final first = song.title[0].toUpperCase();
      final letter = RegExp(r'^[A-Z]$').hasMatch(first) ? first : '#';
      groups.putIfAbsent(letter, () => []).add(song);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note_rounded, size: 48,
                  color: AppColors.textTertiary.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('No songs found', style: AppTextStyles.bodyMediumSecondary),
              ],
            ),
          );
        }

        final grouped = _groupByLetter(songs);
        final letters = grouped.keys.toList();
        final totalItems = songs.length;

        // Pre-calculate offsets after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculateOffsets(grouped, letters);
        });

        return Stack(
          children: [
            // Main list with section headers
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (_isDraggingIndex) return false;
                _updateCurrentLetter();
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 140, right: 28),
                itemCount: totalItems + letters.length, // + section headers
                itemBuilder: (context, flatIndex) {
                  // Calculate which section and which item
                  int remaining = flatIndex;
                  for (final letter in letters) {
                    final headerIdx = 0; // headers count before this
                    if (remaining == 0) {
                      // This is a section header
                      return _buildSectionHeader(letter);
                    }
                    remaining--;
                    final groupSize = grouped[letter]!.length;
                    if (remaining < groupSize) {
                      return SongTile(
                        song: grouped[letter]![remaining],
                        index: _getGlobalIndex(grouped, letters, letter, remaining),
                        showIndex: false,
                        onTap: () {
                          final allSongsSorted = List<Song>.from(songs)
                            ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                          final globalIdx = _getGlobalIndex(grouped, letters, letter, remaining);
                          ref.read(audioServiceProvider).playSong(
                            allSongsSorted[globalIdx],
                            fromList: allSongsSorted,
                          );
                        },
                      );
                    }
                    remaining -= groupSize;
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Alphabet index
            Positioned(
              right: 2,
              top: 0,
              bottom: 0,
              child: _AlphabetIndex(
                letters: letters,
                onLetterTap: (letter) {
                  _scrollToLetter(letter);
                },
                onDragStart: () => _isDraggingIndex = true,
                onDragUpdate: (letter) {
                  _scrollToLetter(letter);
                },
                onDragEnd: () => _isDraggingIndex = false,
                currentLetter: _currentLetter,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => Center(
        child: Text('Error loading songs', style: AppTextStyles.bodyMediumSecondary),
      ),
    );
  }

  void _calculateOffsets(Map<String, List<Song>> grouped, List<String> letters) {
    if (!_scrollController.hasClients) return;
    double offset = 0;
    final itemHeight = 64.0; // approximate song tile height
    final headerHeight = 36.0;
    for (final letter in letters) {
      _sectionOffsets[letter] = offset;
      offset += headerHeight + grouped[letter]!.length * itemHeight;
    }
  }

  void _updateCurrentLetter() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.offset;
    String closest = '';
    double minDist = double.infinity;
    for (final entry in _sectionOffsets.entries) {
      final dist = (entry.value - pos).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = entry.key;
      }
    }
    if (closest.isNotEmpty && closest != _currentLetter) {
      setState(() => _currentLetter = closest);
    }
  }

  int _getGlobalIndex(Map<String, List<Song>> grouped, List<String> letters, String letter, int localIndex) {
    int global = 0;
    for (final l in letters) {
      if (l == letter) return global + localIndex;
      global += grouped[l]!.length;
    }
    return global;
  }

  Widget _buildSectionHeader(String letter) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        letter,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Alphabet Index Widget ──────────────────────────────────

class _AlphabetIndex extends StatelessWidget {
  final List<String> letters;
  final ValueChanged<String> onLetterTap;
  final VoidCallback onDragStart;
  final ValueChanged<String> onDragUpdate;
  final VoidCallback onDragEnd;
  final String currentLetter;

  const _AlphabetIndex({
    required this.letters,
    required this.onLetterTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.currentLetter,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        onDragStart();
        _handleDragUpdate(details.localPosition);
      },
      onVerticalDragUpdate: (details) {
        _handleDragUpdate(details.localPosition);
      },
      onVerticalDragEnd: (_) => onDragEnd(),
      onTapUp: (details) {
        _handleDragUpdate(details.localPosition);
      },
      child: Container(
        width: 22,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(11),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: letters.map((letter) {
            final isActive = letter == currentLetter;
            return SizedBox(
              height: 18,
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                    color: isActive ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleDragUpdate(Offset localPosition) {
    final index = (localPosition.dy / 18).floor().clamp(0, letters.length - 1);
    onDragUpdate(letters[index]);
  }
}
