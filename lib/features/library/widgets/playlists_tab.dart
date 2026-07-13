import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/media_provider.dart';
import '../../../data/models/playlist.dart';
import '../playlist_detail_screen.dart';
import '../widgets/create_playlist_dialog.dart';

class PlaylistsTab extends ConsumerWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final favoriteAsync = ref.watch(favoriteSongsProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        const SizedBox(height: 8),

        // Create Playlist
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.card, borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, color: AppColors.accent, size: 28),
            ),
          ),
          title: Text('Create Playlist',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.accent)),
          onTap: () => CreatePlaylistDialog.show(
            context,
            onCreate: (name, desc) async {
              final repo = ref.read(playlistRepositoryProvider);
              await repo.createPlaylist(name: name, description: desc);
              ref.invalidate(playlistsProvider);
            },
          ),
        ),

        // Smart Playlists
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Smart Playlists', style: AppTextStyles.headingSmallSecondary),
        ),

        _SmartPlaylistTile(
          title: 'Liked Songs',
          icon: Icons.favorite_rounded,
          color: AppColors.accent,
          songCount: favoriteAsync.valueOrNull?.length ?? 0,
          onTap: () {},
        ),
        _SmartPlaylistTile(
          title: 'Recently Added',
          icon: Icons.access_time_rounded,
          color: const Color(0xFF509BF5),
          songCount: 0,
          onTap: () {},
        ),
        _SmartPlaylistTile(
          title: 'Most Played',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFFFF9800),
          songCount: 0,
          onTap: () {},
        ),

        // User Playlists
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Your Playlists', style: AppTextStyles.headingSmallSecondary),
        ),

        playlistsAsync.when(
          data: (playlists) {
            if (playlists.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No playlists yet. Create one above!',
                  style: AppTextStyles.bodySmallSecondary),
              );
            }
            return Column(
              children: playlists.map((playlist) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  leading: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.card, borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.queue_music_rounded, color: AppColors.textTertiary, size: 28),
                    ),
                  ),
                  title: Text(playlist.name, style: AppTextStyles.bodyLarge,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${playlist.songCount} songs',
                    style: AppTextStyles.bodySmallSecondary),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textTertiary),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Rename')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete',
                        style: TextStyle(color: AppColors.error))),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final repo = ref.read(playlistRepositoryProvider);
                        await repo.deletePlaylist(playlist.id);
                        ref.invalidate(playlistsProvider);
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(playlist: playlist)),
                    );
                  },
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SmartPlaylistTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int songCount;
  final VoidCallback onTap;

  const _SmartPlaylistTile({
    required this.title, required this.icon, required this.color,
    required this.songCount, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Icon(icon, color: color, size: 28)),
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text('$songCount songs', style: AppTextStyles.bodySmallSecondary),
      onTap: onTap,
    );
  }
}
