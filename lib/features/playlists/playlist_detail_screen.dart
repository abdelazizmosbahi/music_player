import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../providers/media_provider.dart';
import '../../shared_widgets/song_tile.dart';
import '../../shared_widgets/album_art_placeholder.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final repo = ref.read(playlistRepositoryProvider);
    final songs = await repo.getPlaylistSongs(widget.playlist.id);
    if (mounted) setState(() { _songs = songs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260, pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(widget.playlist.name, style: AppTextStyles.headingMedium,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            actions: [
              if (_songs.isNotEmpty) ...[
                IconButton(
                  onPressed: () => ref.read(audioServiceProvider).playPlaylist(_songs),
                  icon: const Icon(Icons.shuffle_rounded),
                ),
                IconButton(
                  onPressed: () => ref.read(audioServiceProvider).playAll(_songs),
                  icon: const Icon(Icons.play_circle_filled_rounded),
                ),
              ],
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('${_songs.length} songs', style: AppTextStyles.bodySmallSecondary),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            )
          else if (_songs.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SongTile(
                    song: _songs[index], index: index, showIndex: true,
                    onTap: () {
                      ref.read(audioServiceProvider).playSong(
                        _songs[index], fromList: _songs,
                      );
                    },
                    onMoreTap: () => _showSongOptions(_songs[index]),
                  );
                },
                childCount: _songs.length,
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
          colors: [AppColors.accent.withOpacity(0.3), AppColors.background],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            AlbumArtPlaceholder(
              size: 160, title: widget.playlist.name,
              borderRadius: BorderRadius.circular(12), icon: Icons.queue_music_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_rounded, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Songs Yet', style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Add songs from your library\nto this playlist.',
            style: AppTextStyles.bodySmallSecondary, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showSongOptions(Song song) {
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
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Play'),
                onTap: () {
                  ref.read(audioServiceProvider).playSong(song, fromList: _songs);
                  Navigator.pop(context);
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
                leading: const Icon(Icons.delete_rounded, color: AppColors.error),
                title: const Text('Remove from Playlist',
                  style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final repo = ref.read(playlistRepositoryProvider);
                  await repo.removeSongFromPlaylist(widget.playlist.id, song.id);
                  _loadSongs();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
