import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/song.dart';
import '../../providers/media_provider.dart';
import '../../shared_widgets/mini_player.dart';
import '../../shared_widgets/album_art_placeholder.dart';
import '../../shared_widgets/song_tile.dart';
import '../settings/settings_screen.dart';
import '../sleep_timer/sleep_timer_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = _getGreeting(hour);
    final allSongsAsync = ref.watch(allSongsProvider);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(refreshMediaProvider.future);
          ref.invalidate(allSongsProvider);
          ref.invalidate(recentlyPlayedProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: AppTextStyles.displaySmall,
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          'Your music, your way',
                          style: AppTextStyles.bodyMediumSecondary,
                        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                      icon: const Icon(Icons.settings_rounded, size: 24),
                    ),
                  ],
                ),
              ),
            ),

            // Recently Played Section
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'Recently Played'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: recentlyPlayedAsync.when(
                  data: (songs) => songs.isEmpty
                      ? _buildEmptyHorizontal('No recently played songs')
                      : _RecentlyPlayedSongs(songs: songs),
                  loading: () => _buildLoadingHorizontal(),
                  error: (_, __) => _buildEmptyHorizontal('Could not load'),
                ),
              ),
            ),

            // Quick Actions Grid
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'Quick Access'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QuickActionsGrid(),
              ),
            ),

            // All Songs Section
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'All Songs'),
            ),

            // Song list
            allSongsAsync.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return SongTile(
                        song: songs[index],
                        index: index,
                        showIndex: true,
                        onTap: () {
                          ref.read(audioServiceProvider).playSong(
                            songs[index],
                            fromList: songs,
                          );
                        },
                      );
                    },
                    childCount: songs.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _buildEmptyState(),
              ),
            ),

            // Bottom padding for mini player
            const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
          ],
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off_rounded,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Music Found',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to scan for music\non your device.',
            style: AppTextStyles.bodySmallSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHorizontal(String message) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodySmallSecondary,
      ),
    );
  }

  Widget _buildLoadingHorizontal() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accent),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headingMedium),
        ],
      ),
    );
  }
}

class _RecentlyPlayedSongs extends ConsumerWidget {
  final List<Song> songs;

  const _RecentlyPlayedSongs({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () {
              ref.read(audioServiceProvider).playSong(song, fromList: songs);
            },
                    child: Column(
                      children: [
                        AlbumArtPlaceholder(
                          size: 140,
                          title: song.title,
                          songId: int.tryParse(song.id),
                          borderRadius: BorderRadius.circular(12),
                        ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 140,
                  child: Text(
                    song.title,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      ('Liked Songs', Icons.favorite_rounded, AppColors.accent),
      ('Recently Added', Icons.access_time_rounded, const Color(0xFF509BF5)),
      ('Artists', Icons.person_rounded, const Color(0xFFE91E63)),
      ('Albums', Icons.album_rounded, const Color(0xFFFF9800)),
      ('Playlists', Icons.queue_music_rounded, const Color(0xFF9C27B0)),
      ('Sleep Timer', Icons.nightlight_round, const Color(0xFF00BCD4)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (title, icon, color) = items[index];
        return GestureDetector(
          onTap: () {
            switch (index) {
              case 5:
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SleepTimerScreen()),
                );
                break;
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}
