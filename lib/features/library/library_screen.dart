import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'widgets/songs_tab.dart';
import 'widgets/albums_tab.dart';
import 'widgets/artists_tab.dart';
import 'widgets/playlists_tab.dart';

final libraryTabProvider = StateProvider<int>((ref) => 0);

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'Songs'),
    Tab(text: 'Albums'),
    Tab(text: 'Artists'),
    Tab(text: 'Playlists'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      ref.read(libraryTabProvider.notifier).state = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Library', style: AppTextStyles.displaySmall)
                    .animate()
                    .fadeIn(duration: 300.ms),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.sort_rounded, size: 22),
                      tooltip: 'Sort',
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, size: 22),
                      tooltip: 'Create Playlist',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: _tabs,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            labelStyle: AppTextStyles.labelLarge,
            unselectedLabelStyle: AppTextStyles.labelLarge,
            indicatorColor: AppColors.textPrimary,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            dividerHeight: 0,
            splashBorderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SongsTab(),
                AlbumsTab(),
                ArtistsTab(),
                PlaylistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
