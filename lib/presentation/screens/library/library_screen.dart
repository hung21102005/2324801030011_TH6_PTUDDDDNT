import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/models/song_model.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/player/player_cubit.dart';
import '../../../logic/player/player_state.dart' as p;
import '../../../logic/songs/song_cubit.dart';
import '../../../logic/songs/song_state.dart';
import '../../widgets/song_tile.dart';
import '../playlist/playlist_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Thư viện của bạn', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            tooltip: 'Tạo Playlist mới',
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<SongCubit, SongState>(
        builder: (context, songState) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. Liked Songs Tile
              _buildLikedSongsTile(context, songState.favoriteSongs),
              const SizedBox(height: 24),

              // 2. Playlists Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Playlists của bạn', style: AppTextStyles.headingSmall),
                  TextButton.icon(
                    onPressed: () => _showCreatePlaylistDialog(context),
                    icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                    label: Text(
                      'Tạo mới',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Playlists List
              if (songState.playlists.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.queue_music, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text('Bạn chưa có playlist nào', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Nhấn vào nút "Tạo mới" để bắt đầu tạo danh sách phát của riêng bạn',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...songState.playlists.map((pl) => _buildPlaylistTile(context, pl)),

              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLikedSongsTile(BuildContext context, List<SongModel> favoriteSongs) {
    return InkWell(
      onTap: () {
        _showFavoritesBottomSheet(context, favoriteSongs);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF450AF5).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bài hát đã thích',
                    style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${favoriteSongs.length} bài hát',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (favoriteSongs.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                onPressed: () {
                  context.read<PlayerCubit>().playPlaylist(favoriteSongs);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(BuildContext context, PlaylistModel playlist) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: playlist.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: playlist.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.surfaceHighlight),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceHighlight,
                              child: const Icon(Icons.queue_music, color: Colors.white54),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceHighlight,
                            child: const Icon(Icons.queue_music, color: AppColors.primary),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        playlist.description.isNotEmpty
                            ? playlist.description
                            : '${playlist.songs.length} bài hát',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFavoritesBottomSheet(BuildContext context, List<SongModel> favorites) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bài hát đã thích', style: AppTextStyles.headingSmall),
                      if (favorites.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<PlayerCubit>().playPlaylist(favorites);
                            Navigator.pop(bottomCtx);
                          },
                          icon: const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                          label: const Text('Phát tất cả'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: favorites.isEmpty
                      ? Center(
                          child: Text(
                            'Bạn chưa thích bài hát nào',
                            style: AppTextStyles.bodyMedium,
                          ),
                        )
                      : BlocBuilder<PlayerCubit, p.PlayerState>(
                          builder: (context, playerState) {
                            final authState = context.read<AuthCubit>().state;
                            final userId = authState is Authenticated ? (authState.user?.uid ?? authState.email) : null;

                            return ListView.builder(
                              controller: scrollController,
                              itemCount: favorites.length,
                              itemBuilder: (context, index) {
                                final song = favorites[index];
                                final isCurrent = playerState.currentSong?.id == song.id;

                                return SongTile(
                                  song: song,
                                  isCurrentSong: isCurrent,
                                  isPlaying: isCurrent && playerState.isPlaying,
                                  onTap: () {
                                    context.read<PlayerCubit>().playSong(
                                          song,
                                          queue: favorites,
                                        );
                                  },
                                  onFavoriteTap: () {
                                    final playerCubit = context.read<PlayerCubit>();
                                    context.read<SongCubit>().toggleFavorite(userId, song).then((newFav) {
                                      playerCubit.updateSongFavoriteStatus(song.id, newFav);
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Tạo Playlist Mới', style: AppTextStyles.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Tên Playlist',
                  hintText: 'Nhập tên playlist',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  hintText: 'Mô tả ngắn gọn về danh sách này',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  final authState = context.read<AuthCubit>().state;
                  final userId = authState is Authenticated ? authState.user?.uid : null;
                  context.read<SongCubit>().createPlaylist(
                        userId: userId,
                        title: title,
                        description: descController.text.trim(),
                      );
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }
}
