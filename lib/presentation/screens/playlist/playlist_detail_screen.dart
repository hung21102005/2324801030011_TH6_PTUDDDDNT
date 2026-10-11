import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/player/player_cubit.dart';
import '../../../logic/player/player_state.dart' as p;
import '../../../logic/songs/song_cubit.dart';
import '../../../logic/songs/song_state.dart';
import '../../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongCubit, SongState>(
      builder: (context, songState) {
        final playlistIndex = songState.playlists.indexWhere((p) => p.id == playlistId);
        if (playlistIndex == -1) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: const Center(
              child: Text('Không tìm thấy Playlist'),
            ),
          );
        }

        final playlist = songState.playlists[playlistIndex];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Sliver App Bar with Artwork Header
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.surface,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    playlist.title,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black, blurRadius: 10),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (playlist.thumbnailUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: playlist.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.surfaceLight),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.queue_music, size: 72, color: AppColors.textMuted),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.queue_music, size: 72, color: AppColors.textMuted),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.8),
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Playlist Action Bar & Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (playlist.description.isNotEmpty) ...[
                        Text(
                          playlist.description,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.music_note, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${playlist.songs.length} bài hát',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Play All & Shuffle Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: playlist.songs.isEmpty
                                  ? null
                                  : () {
                                      context.read<PlayerCubit>().playPlaylist(
                                            playlist.songs,
                                            startIndex: 0,
                                          );
                                    },
                              icon: const Icon(Icons.play_arrow, color: Colors.black),
                              label: const Text('Phát tất cả'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            onPressed: playlist.songs.isEmpty
                                ? null
                                : () {
                                    context.read<PlayerCubit>().playPlaylist(
                                          playlist.songs,
                                          shuffle: true,
                                        );
                                  },
                            icon: const Icon(Icons.shuffle, color: AppColors.primary),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceLight,
                              padding: const EdgeInsets.all(14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Songs List
              if (playlist.songs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.music_off, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Playlist chưa có bài hát nào',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thêm bài hát từ Trang chủ hoặc Tìm kiếm',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                BlocBuilder<PlayerCubit, p.PlayerState>(
                  builder: (context, playerState) {
                    final authState = context.read<AuthCubit>().state;
                    final userId = authState is Authenticated ? authState.user?.uid : null;

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = playlist.songs[index];
                          final isCurrent = playerState.currentSong?.id == song.id;

                          return SongTile(
                            song: song,
                            isCurrentSong: isCurrent,
                            isPlaying: isCurrent && playerState.isPlaying,
                            onTap: () {
                              context.read<PlayerCubit>().playSong(
                                    song,
                                    queue: playlist.songs,
                                  );
                            },
                            onFavoriteTap: () {
                              final playerCubit = context.read<PlayerCubit>();
                              context.read<SongCubit>().toggleFavorite(userId, song).then((newFav) {
                                playerCubit.updateSongFavoriteStatus(song.id, newFav);
                              });
                            },
                            onMoreTap: () {
                              _showSongOptions(context, song, playlist.id);
                            },
                          );
                        },
                        childCount: playlist.songs.length,
                      ),
                    );
                  },
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, SongModel song, String playlistId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Xóa khỏi Playlist này', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
                onTap: () {
                  context.read<SongCubit>().removeSongFromPlaylist(playlistId, song.id);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
