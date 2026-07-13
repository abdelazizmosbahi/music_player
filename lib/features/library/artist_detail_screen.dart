import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/artist.dart';
import '../../providers/media_provider.dart';
import '../../shared_widgets/song_tile.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(artist.name, style: AppTextStyles.headingMedium,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            actions: [
              IconButton(
                onPressed: () => ref.read(audioServiceProvider).playPlaylist(artist.songs),
                icon: const Icon(Icons.shuffle_rounded),
              ),
              IconButton(
                onPressed: () => ref.read(audioServiceProvider).playAll(artist.songs),
                icon: const Icon(Icons.play_circle_filled_rounded),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _buildStat('${artist.songCount}', 'Songs'),
                  const SizedBox(width: 24),
                  _buildStat('${artist.albums.length}', 'Albums'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Popular Songs', style: AppTextStyles.headingSmall),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return SongTile(
                  song: artist.songs[index],
                  index: index,
                  showIndex: true,
                  onTap: () {
                    ref.read(audioServiceProvider).playSong(
                      artist.songs[index],
                      fromList: artist.songs,
                    );
                  },
                );
              },
              childCount: artist.songs.length,
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
          colors: [AppColors.accent.withOpacity(0.25), AppColors.background],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              color: AppColors.card, shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.accent.withOpacity(0.4), AppColors.card],
              ),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 60),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.headingMedium),
        Text(label, style: AppTextStyles.bodySmallSecondary),
      ],
    );
  }
}
