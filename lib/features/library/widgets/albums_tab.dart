import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/media_provider.dart';
import '../../../shared_widgets/album_art_placeholder.dart';
import '../album_detail_screen.dart';

class AlbumsTab extends ConsumerWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(allAlbumsProvider);

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.album_rounded, size: 48, color: AppColors.textTertiary.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('No albums found', style: AppTextStyles.bodyMediumSecondary),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.85,
            mainAxisSpacing: 16, crossAxisSpacing: 16,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album)),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AlbumArtPlaceholder(
                      title: album.title,
                      borderRadius: BorderRadius.circular(8),
                      icon: Icons.album_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(album.title, style: AppTextStyles.bodySmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(album.artist, style: AppTextStyles.bodySmallSecondary,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(child: Text('Error loading albums', style: AppTextStyles.bodyMediumSecondary)),
    );
  }
}
