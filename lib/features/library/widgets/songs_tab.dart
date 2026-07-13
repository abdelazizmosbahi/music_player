import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song.dart';
import '../../../providers/media_provider.dart';
import '../../../shared_widgets/song_tile.dart';

class SongsTab extends ConsumerWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 48,
                  color: AppColors.textTertiary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No songs found',
                  style: AppTextStyles.bodyMediumSecondary,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 140),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return SongTile(
              song: songs[index],
              index: index,
              showIndex: true,
              onTap: () {
                ref.read(audioServiceProvider).playSong(songs[index], fromList: songs);
              },
              onMoreTap: () {
                _showSongOptions(context, songs[index], ref);
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error loading songs',
          style: AppTextStyles.bodyMediumSecondary,
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context, Song song, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.music_note_rounded, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title, style: AppTextStyles.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(song.artist, style: AppTextStyles.bodySmallSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Play'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(audioServiceProvider).playSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Add to Queue'),
                onTap: () {
                  ref.read(audioServiceProvider).addToQueue(song);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  song.isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: song.isFavorite ? AppColors.accent : null,
                ),
                title: Text(song.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () async {
                  Navigator.pop(context);
                  final repo = ref.read(favoritesRepositoryProvider);
                  await repo.toggleFavorite(song.id);
                  ref.invalidate(favoriteSongsProvider);
                  ref.invalidate(allSongsProvider);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
