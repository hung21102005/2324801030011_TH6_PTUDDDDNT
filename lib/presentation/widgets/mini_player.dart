import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../logic/player/player_cubit.dart';
import '../../logic/player/player_state.dart';
import '../../logic/songs/song_cubit.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';
import '../screens/player/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        final currentSong = state.currentSong;
        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        final totalDuration = (state.duration > Duration.zero)
            ? state.duration
            : Duration(seconds: currentSong.duration);
        final progress = (totalDuration.inMilliseconds > 0)
            ? (state.position.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const NowPlayingScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;
                  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(position: animation.drive(tween), child: child);
                },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        // Hero Artwork
                        Hero(
                          tag: 'player_artwork_${currentSong.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: CachedNetworkImage(
                                imageUrl: currentSong.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surfaceHighlight,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceHighlight,
                                  child: const Icon(Icons.music_note, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Song Title & Artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentSong.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentSong.artist,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Like Button
                        IconButton(
                          icon: Icon(
                            currentSong.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: currentSong.isFavorite ? AppColors.favorite : AppColors.textSecondary,
                            size: 22,
                          ),
                          onPressed: () {
                            final authState = context.read<AuthCubit>().state;
                            final userId = authState is Authenticated ? (authState.user?.uid ?? authState.email) : null;
                            final playerCubit = context.read<PlayerCubit>();
                            context.read<SongCubit>().toggleFavorite(userId, currentSong).then((newFav) {
                              playerCubit.updateSongFavoriteStatus(currentSong.id, newFav);
                            });
                          },
                        ),

                        // Play / Pause Button with animated state
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: IconButton(
                            icon: state.isBuffering
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Icon(
                                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                            onPressed: () => context.read<PlayerCubit>().playPause(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),

                        // Next Track
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: AppColors.textPrimary, size: 24),
                          onPressed: () => context.read<PlayerCubit>().next(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  // Mini Progress line on the bottom edge
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 2.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
