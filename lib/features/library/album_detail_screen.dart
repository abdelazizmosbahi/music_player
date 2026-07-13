import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/album.dart';
import '../../providers/media_provider.dart';
import '../../shared_widgets/song_tile.dart';
import '../../shared_widgets/album_art_placeholder.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(album.title, style: AppTextStyles.headingMedium,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            actions: [
              IconButton(
                onPressed: () => ref.read(audioServiceProvider).playPlaylist(album.songs),
                icon: const Icon(Icons.shuffle_rounded),
              ),
              IconButton(
                onPressed: () => ref.read(audioServiceProvider).playAll(album.songs),
                icon: const Icon(Icons.play_circle_filled_rounded),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Text(album.artist, style: AppTextStyles.bodyMediumSecondary),
                  const SizedBox(width: 8),
                  Text('•', style: AppTextStyles.bodyMediumSecondary),
                  const SizedBox(width: 8),
                  Text('${album.songCount} songs', style: AppTextStyles.bodyMediumSecondary),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return SongTile(
                  song: album.songs[index],
                  index: index,
                  showIndex: true,
                  onTap: () {
                    ref.read(audioServiceProvider).playSong(
                      album.songs[index],
                      fromList: album.songs,
                    );
                  },
                );
              },
              childCount: album.songs.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppColors.accent.withOpacity(0.2), AppColors.background],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: AlbumArtPlaceholder(
            size: 180, title: album.title,
            borderRadius: BorderRadius.circular(12), icon: Icons.album_rounded,
          ),
        ),
      ),
    );
  }
}
