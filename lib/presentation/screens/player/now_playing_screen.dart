import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/player/player_cubit.dart';
import '../../../logic/player/player_state.dart' as p;
import '../../../logic/songs/song_cubit.dart';
import '../../widgets/progress_slider.dart';
import '../../widgets/rotating_disc.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showVinylMode = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, p.PlayerState>(
      builder: (context, state) {
        final currentSong = state.currentSong;
        if (currentSong == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Chưa có bài hát nào được chọn',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final size = MediaQuery.of(context).size;
        final artworkSize = size.width * 0.78;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.playerBackgroundGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Column(
                          children: [
                            Text(
                              'ĐANG PHÁT TỪ DANH SÁCH',
                              style: AppTextStyles.caption.copyWith(
                                letterSpacing: 1.2,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong.album.isNotEmpty
                                  ? currentSong.album
                                  : 'VibeMusic Hits',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            _showVinylMode ? Icons.image : Icons.album,
                            color: _showVinylMode ? AppColors.primary : AppColors.textSecondary,
                          ),
                          tooltip: _showVinylMode ? 'Xem ảnh bìa' : 'Xem đĩa xoay vinyl',
                          onPressed: () {
                            setState(() {
                              _showVinylMode = !_showVinylMode;
                            });
                          },
                        ),
                      ],
                    ),

                    const Spacer(flex: 1),

                    // Center Artwork / Disc with Swipe Gesture
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! < -250) {
                            // Swipe Left -> Next Track
                            context.read<PlayerCubit>().next();
                          } else if (details.primaryVelocity! > 250) {
                            // Swipe Right -> Previous Track
                            context.read<PlayerCubit>().previous();
                          }
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _showVinylMode
                            ? RotatingDisc(
                                key: ValueKey('vinyl_${currentSong.id}'),
                                imageUrl: currentSong.thumbnailUrl,
                                isPlaying: state.isPlaying,
                                size: artworkSize,
                              )
                            : Hero(
                                tag: 'player_artwork_${currentSong.id}',
                                child: Container(
                                  key: ValueKey('cover_${currentSong.id}'),
                                  width: artworkSize,
                                  height: artworkSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        blurRadius: 30,
                                        offset: const Offset(0, 16),
                                      ),
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        blurRadius: 28,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: CachedNetworkImage(
                                      imageUrl: currentSong.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: AppColors.surfaceHighlight,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: AppColors.surfaceHighlight,
                                        child: const Icon(Icons.music_note, size: 64),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Song Info & Heart Action
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong.title,
                                style: AppTextStyles.headingMedium.copyWith(fontSize: 22),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentSong.artist,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Animated Heart Button
                        IconButton(
                          iconSize: 28,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              currentSong.isFavorite ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(currentSong.isFavorite),
                              color: currentSong.isFavorite ? AppColors.favorite : AppColors.textSecondary,
                            ),
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
                        // Add to playlist button
                        IconButton(
                          iconSize: 26,
                          icon: const Icon(Icons.playlist_add, color: AppColors.textSecondary),
                          onPressed: () => _showAddToPlaylistDialog(context, currentSong),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Audio Progress Bar
                    ProgressSlider(
                      position: state.position,
                      bufferedPosition: state.bufferedPosition,
                      totalDuration: state.duration,
                      onSeek: (position) => context.read<PlayerCubit>().seek(position),
                    ),

                    const SizedBox(height: 14),

                    // Controls Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Shuffle
                        IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: state.isShuffle ? AppColors.primary : AppColors.textSecondary,
                            size: 24,
                          ),
                          onPressed: () => context.read<PlayerCubit>().toggleShuffle(),
                        ),

                        // Previous
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous,
                            color: AppColors.textPrimary,
                            size: 38,
                          ),
                          onPressed: () => context.read<PlayerCubit>().previous(),
                        ),

                        // Giant Glow Play / Pause Button
                        GestureDetector(
                          onTap: () => context.read<PlayerCubit>().playPause(),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: state.isBuffering
                                  ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Icon(
                                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.black,
                                      size: 38,
                                    ),
                            ),
                          ),
                        ),

                        // Next
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: AppColors.textPrimary,
                            size: 38,
                          ),
                          onPressed: () => context.read<PlayerCubit>().next(),
                        ),

                        // Repeat
                        IconButton(
                          icon: Icon(
                            state.loopMode == LoopMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                            color: state.loopMode != LoopMode.off
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          onPressed: () => context.read<PlayerCubit>().toggleRepeat(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bottom Queue bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showQueueModal(context, state),
                          icon: const Icon(Icons.queue_music, size: 20, color: AppColors.textSecondary),
                          label: Text(
                            'Danh sách phát (${state.queue.length})',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.speaker_group_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Thiết bị này',
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, dynamic song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final songState = context.read<SongCubit>().state;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thêm vào Playlist', style: AppTextStyles.headingSmall),
              const SizedBox(height: 14),
              if (songState.playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Chưa có playlist nào', style: AppTextStyles.bodyMedium),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: songState.playlists.length,
                    itemBuilder: (ctx, index) {
                      final pl = songState.playlists[index];
                      final alreadyIn = pl.songs.any((s) => s.id == song.id);
                      return ListTile(
                        leading: const Icon(Icons.playlist_play, color: AppColors.primary),
                        title: Text(pl.title, style: AppTextStyles.bodyLarge),
                        subtitle: Text('${pl.songs.length} bài hát', style: AppTextStyles.caption),
                        trailing: alreadyIn
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : const Icon(Icons.add, color: AppColors.textSecondary),
                        onTap: () {
                          if (!alreadyIn) {
                            context.read<SongCubit>().addSongToPlaylist(pl.id, song);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm vào "${pl.title}"'),
                                backgroundColor: AppColors.surfaceLight,
                              ),
                            );
                          }
                          Navigator.pop(bottomSheetContext);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showQueueModal(BuildContext context, p.PlayerState playerState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Danh sách chờ phát', style: AppTextStyles.headingSmall),
                    Text(
                      '${playerState.queue.length} bài hát',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playerState.queue.length,
                  itemBuilder: (ctx, index) {
                    final song = playerState.queue[index];
                    final isCurrent = index == playerState.currentIndex;
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(song.artist, style: AppTextStyles.caption),
                      trailing: isCurrent
                          ? const Icon(Icons.volume_up, color: AppColors.primary)
                          : null,
                      onTap: () {
                        context.read<PlayerCubit>().playSong(song, queue: playerState.queue);
                        Navigator.pop(modalContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
