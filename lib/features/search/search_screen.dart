import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants.dart';
import '../../data/models/song.dart';
import '../../providers/media_provider.dart';
import '../../shared_widgets/mini_player.dart';
import '../../shared_widgets/song_tile.dart';
import '../../core/constants.dart';
import '../../data/models/song.dart';
import '../../providers/media_provider.dart';
import '../../shared_widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(AppConstants.keyRecentSearches) ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > AppConstants.maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, AppConstants.maxRecentSearches);
    }
    await prefs.setStringList(AppConstants.keyRecentSearches, _recentSearches);
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return SafeArea(
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (value) {
                setState(() => _query = value);
                ref.read(searchQueryProvider.notifier).state = value;
              },
              onSubmitted: (value) => _saveSearch(value),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search songs, artists, albums...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _query.isEmpty
                ? _buildBrowseView()
                : _buildSearchResults(searchResultsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Recent Searches
        if (_recentSearches.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: AppTextStyles.headingSmall),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(AppConstants.keyRecentSearches);
                  setState(() => _recentSearches.clear());
                },
                child: Text(
                  'Clear',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._recentSearches.map((search) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.history_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
              title: Text(
                search,
                style: AppTextStyles.bodyMedium,
              ),
              trailing: const Icon(
                Icons.north_west,
                color: AppColors.textTertiary,
                size: 16,
              ),
              onTap: () {
                _searchController.text = search;
                setState(() => _query = search);
                ref.read(searchQueryProvider.notifier).state = search;
              },
            );
          }),
        ],

        const SizedBox(height: 24),
        Text('Browse Categories', style: AppTextStyles.headingSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(label: 'All Songs', onTap: () {}),
            _CategoryChip(label: 'Artists', onTap: () {}),
            _CategoryChip(label: 'Albums', onTap: () {}),
            _CategoryChip(label: 'Recently Added', onTap: () {}),
            _CategoryChip(label: 'Most Played', onTap: () {}),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSearchResults(AsyncValue<List<Song>> searchResultsAsync) {
    return searchResultsAsync.when(
      data: (results) {
        if (results.isEmpty && _query.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.textTertiary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No results for "$_query"',
                  style: AppTextStyles.bodyMediumSecondary,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return SongTile(
              song: results[index],
              onTap: () {
                ref.read(audioServiceProvider).playSong(results[index]);
                _saveSearch(_query);
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => Center(
        child: Text('Search error', style: AppTextStyles.bodyMediumSecondary),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      backgroundColor: AppColors.card,
      side: BorderSide.none,
      onPressed: onTap,
    );
  }
}
