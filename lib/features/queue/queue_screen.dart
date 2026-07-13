import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/song.dart';
import '../../providers/media_provider.dart';
import '../../shared_widgets/album_art_placeholder.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider);
    final currentIndex = ref.watch(queueIndexProvider);
    final audioService = ref.read(audioServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Queue'),
        centerTitle: true,
        actions: [
          if (queue.isNotEmpty)
            TextButton(
              onPressed: () => audioService.clearQueue(),
              child: Text('Clear', style: AppTextStyles.labelMedium.copyWith(color: AppColors.accent)),
            ),
        ],
      ),
      body: queue.isEmpty ? _buildEmpty() : _buildQueueList(queue, currentIndex, audioService, ref),
    );
  }

  Widget _buildQueueList(List<Song> queue, int currentIndex, audioService, WidgetRef ref) {
    return Column(
      children: [
        // Now Playing
        if (queue.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('Now Playing', style: AppTextStyles.headingSmall),
                const SizedBox(width: 8),
                Text('1 song', style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ),
          _QueueTile(
            song: queue[currentIndex],
            isPlaying: true,
            index: currentIndex,
            onRemove: null,
            onTap: () {},
          ),
        ],
        // Up Next
        if (queue.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('Up Next', style: AppTextStyles.headingSmall),
                const SizedBox(width: 8),
                Text('${queue.length - 1} songs', style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 140),
              itemCount: queue.length - 1,
              onReorder: (oldIndex, newIndex) {
                audioService.reorderQueue(oldIndex + currentIndex + 1, newIndex + currentIndex + 1);
              },
              itemBuilder: (context, index) {
                final songIndex = index < currentIndex ? index : index + 1;
                if (songIndex >= queue.length) return const SizedBox.shrink();
                return _QueueTile(
                  key: ValueKey('${queue[songIndex].id}_$index'),
                  song: queue[songIndex],
                  index: songIndex,
                  onTap: () => audioService.playSong(queue[songIndex], fromList: queue),
                  onRemove: () => audioService.removeFromQueue(songIndex),
                );
              },
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music_rounded, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Queue is Empty', style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Songs you add to the queue\nwill appear here.', style: AppTextStyles.bodySmallSecondary, textAlign: TextAlign.center),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _QueueTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _QueueTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    required this.index,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key ?? ValueKey(song.id),
      direction: onRemove != null ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) => onRemove?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withOpacity(0.8),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: isPlaying
            ? const Icon(Icons.equalizer_rounded, color: AppColors.accent, size: 24)
            : AlbumArtPlaceholder(
                size: 44, title: song.title, borderRadius: BorderRadius.circular(6)),
        title: Text(
          song.title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isPlaying ? AppColors.accent : AppColors.textPrimary,
            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(song.artist, style: AppTextStyles.bodySmallSecondary,
          maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: onRemove != null
            ? IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary))
            : ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle_rounded, color: AppColors.textTertiary, size: 20)),
        onTap: onTap,
      ),
    );
  }
}
