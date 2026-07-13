import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmer,
      highlightColor: AppColors.surfaceElevated,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmer,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A shimmer loading card that mimics a song tile.
class ShimmerSongTile extends StatelessWidget {
  const ShimmerSongTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const ShimmerLoading(width: 48, height: 48, borderRadius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(width: 160, height: 14),
                const SizedBox(height: 6),
                const ShimmerLoading(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A shimmer loading grid card for albums.
class ShimmerAlbumCard extends StatelessWidget {
  const ShimmerAlbumCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerLoading(
          width: double.infinity,
          height: 160,
          borderRadius: 8,
        ),
        const SizedBox(height: 8),
        const ShimmerLoading(width: 120, height: 12),
        const SizedBox(height: 4),
        const ShimmerLoading(width: 80, height: 10),
      ],
    );
  }
}
