import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/song_model.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final bool isCurrentSong;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onMoreTap;

  const SongTile({
    super.key,
    required this.song,
    this.isCurrentSong = false,
    this.isPlaying = false,
    required this.onTap,
    this.onFavoriteTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.surfaceLight.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Artwork Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CachedNetworkImage(
                        imageUrl: song.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      ),
                    ),
                    if (isCurrentSong)
                      Container(
                        width: 54,
                        height: 54,
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Center(
                          child: isPlaying
                              ? const _EqualizerIndicator()
                              : const Icon(Icons.play_arrow, color: AppColors.primary, size: 26),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Title & Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isCurrentSong ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            song.artist,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (song.genre.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHighlight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              song.genre,
                              style: AppTextStyles.caption.copyWith(fontSize: 9.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Duration
              Text(
                song.durationFormatted,
                style: AppTextStyles.caption,
              ),
              const SizedBox(width: 4),

              // Favorite Icon
              IconButton(
                icon: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: song.isFavorite ? AppColors.favorite : AppColors.textMuted,
                  size: 20,
                ),
                onPressed: onFavoriteTap,
                visualDensity: VisualDensity.compact,
              ),

              // More 3-dots Menu
              if (onMoreTap != null)
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: onMoreTap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Subtle Equalizer Wave Animation
class _EqualizerIndicator extends StatefulWidget {
  const _EqualizerIndicator();

  @override
  State<_EqualizerIndicator> createState() => _EqualizerIndicatorState();
}

class _EqualizerIndicatorState extends State<_EqualizerIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(14 * _anim.value + 4),
            const SizedBox(width: 2.5),
            _bar(18 * (1.0 - _anim.value) + 4),
            const SizedBox(width: 2.5),
            _bar(12 * _anim.value + 6),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3.2,
      height: height.clamp(4.0, 20.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
