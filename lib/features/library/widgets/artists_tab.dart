import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/media_provider.dart';
import '../artist_detail_screen.dart';

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(allArtistsProvider);

    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_rounded, size: 48, color: AppColors.textTertiary.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('No artists found', style: AppTextStyles.bodyMediumSecondary),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 140),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              leading: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.card, shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 28),
                ),
              ),
              title: Text(artist.name, style: AppTextStyles.bodyLarge,
                maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${artist.songCount} songs • ${artist.albums.length} albums',
                style: AppTextStyles.bodySmallSecondary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ArtistDetailScreen(artist: artist)),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(child: Text('Error loading artists', style: AppTextStyles.bodyMediumSecondary)),
    );
  }
}
