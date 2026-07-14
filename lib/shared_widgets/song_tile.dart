import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/duration_formatter.dart';
import '../data/models/song.dart';
import 'album_art_placeholder.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMoreTap;
  final bool showIndex;
  final int? index;
  final bool isPlaying;
  final bool isCompact;
  final Widget? trailing;

  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onLongPress,
    this.onMoreTap,
    this.showIndex = false,
    this.index,
    this.isPlaying = false,
    this.isCompact = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isCompact ? 4 : 8,
          ),
          child: Row(
            children: [
              // Album art
              if (showIndex && index != null && !isPlaying)
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Text(
                      '${index! + 1}',
                      style: AppTextStyles.bodyMediumSecondary,
                    ),
                  ),
                )
              else
                AlbumArtPlaceholder(
                  size: isCompact ? 40 : 48,
                  title: song.title,
                  songId: int.tryParse(song.id),
                  borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
                ),
              const SizedBox(width: 12),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: isPlaying
                          ? AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            )
                          : AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: AppTextStyles.bodySmallSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Duration or trailing
              if (trailing != null)
                trailing!
              else if (!isCompact)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    DurationFormatter.format(song.duration),
                    style: AppTextStyles.bodySmallSecondary,
                  ),
                ),

              // More button
              if (onMoreTap != null)
                IconButton(
                  onPressed: onMoreTap,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.02, end: 0);
  }
}
