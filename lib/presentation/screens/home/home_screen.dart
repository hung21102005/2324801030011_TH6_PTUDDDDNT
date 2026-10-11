import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/player/player_cubit.dart';
import '../../../logic/player/player_state.dart' as p;
import '../../../logic/songs/song_cubit.dart';
import '../../../logic/songs/song_state.dart';
import '../../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Chào buổi sáng ☀️';
    } else if (hour >= 12 && hour < 18) {
      return 'Chào buổi chiều 🌤️';
    } else {
      return 'Chào buổi tối 🌙';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<SongCubit, SongState>(
          builder: (context, songState) {
            final authState = context.watch<AuthCubit>().state;
            final user = authState is Authenticated ? authState : null;
            final userId = user?.user?.uid ?? user?.email;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await context.read<SongCubit>().loadAllData(userId);
              },
              child: CustomScrollView(
                slivers: [
                  // 1. Header: Greeting & Profile
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.displayName ?? 'Người nghe nhạc',
                                style: AppTextStyles.headingMedium.copyWith(fontSize: 22),
                              ),
                            ],
                          ),
                          // Avatar / Profile Button
                          GestureDetector(
                            onTap: () => _showUserMenu(context, user),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceHighlight,
                                border: Border.all(color: AppColors.primary, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  user?.avatarInitial ?? 'U',
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          context.read<SongCubit>().search(val, userId: userId);
                        },
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Tìm bài hát, nghệ sĩ hoặc thể loại...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<SongCubit>().search('', userId: userId);
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // 3. Genre Chips
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 48,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        scrollDirection: Axis.horizontal,
                        itemCount: AppConstants.musicGenres.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final genre = AppConstants.musicGenres[index];
                          final isSelected = songState.selectedGenre == genre;
                          return ChoiceChip(
                            label: Text(
                              genre,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected ? Colors.black : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceLight,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                context.read<SongCubit>().selectGenre(genre, userId: userId);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // 4. Content Area
                  if (songState.hasActiveSearch)
                    _buildSearchResults(context, songState, userId)
                  else ...[
                    // Trending Horizontal Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Thịnh hành & Mới nhất 🔥', style: AppTextStyles.headingSmall),
                            Text(
                              'Xem thêm',
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 220,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: songState.trendingSongs.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final song = songState.trendingSongs[index];
                            return _buildTrendingCard(context, song, songState.trendingSongs);
                          },
                        ),
                      ),
                    ),

                    // Recommended Vertical List Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Gợi ý cho bạn ✨', style: AppTextStyles.headingSmall),
                            Text(
                              '${songState.recommendedSongs.length} bài hát',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                    BlocBuilder<PlayerCubit, p.PlayerState>(
                      builder: (context, playerState) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = songState.recommendedSongs[index];
                              final isCurrent = playerState.currentSong?.id == song.id;

                              return SongTile(
                                song: song,
                                isCurrentSong: isCurrent,
                                isPlaying: isCurrent && playerState.isPlaying,
                                onTap: () {
                                  context.read<PlayerCubit>().playSong(
                                        song,
                                        queue: songState.recommendedSongs,
                                      );
                                },
                                onFavoriteTap: () {
                                  final playerCubit = context.read<PlayerCubit>();
                                  context.read<SongCubit>().toggleFavorite(userId, song).then((newFav) {
                                    playerCubit.updateSongFavoriteStatus(song.id, newFav);
                                  });
                                },
                                onMoreTap: () => _showSongMenu(context, song),
                              );
                            },
                            childCount: songState.recommendedSongs.length,
                          ),
                        );
                      },
                    ),
                  ],

                  // Bottom padding to avoid overlapping mini player
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, SongModel song, List<SongModel> queue) {
    return BlocBuilder<PlayerCubit, p.PlayerState>(
      builder: (context, playerState) {
        final isCurrent = playerState.currentSong?.id == song.id;
        final isPlaying = isCurrent && playerState.isPlaying;

        return GestureDetector(
          onTap: () {
            context.read<PlayerCubit>().playSong(song, queue: queue);
          },
          child: Container(
            width: 154,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with play button overlay
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: SizedBox(
                        width: 154,
                        height: 135,
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.surfaceLight),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    // Floating Play Button
                    Container(
                      margin: const EdgeInsets.all(8),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, SongState songState, String? userId) {
    if (songState.isSearching) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (songState.searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                ),
                child: const Icon(Icons.search_off, size: 36, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy bài hát nào',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Hãy thử tìm với từ khóa khác hoặc chuyển sang thể loại khác',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return BlocBuilder<PlayerCubit, p.PlayerState>(
      builder: (context, playerState) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = songState.searchResults[index];
              final isCurrent = playerState.currentSong?.id == song.id;

              return SongTile(
                song: song,
                isCurrentSong: isCurrent,
                isPlaying: isCurrent && playerState.isPlaying,
                onTap: () {
                  context.read<PlayerCubit>().playSong(
                        song,
                        queue: songState.searchResults,
                      );
                },
                onFavoriteTap: () {
                  final playerCubit = context.read<PlayerCubit>();
                  context.read<SongCubit>().toggleFavorite(userId, song).then((newFav) {
                    playerCubit.updateSongFavoriteStatus(song.id, newFav);
                  });
                },
                onMoreTap: () => _showSongMenu(context, song),
              );
            },
            childCount: songState.searchResults.length,
          ),
        );
      },
    );
  }

  void _showUserMenu(BuildContext context, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.avatarInitial ?? 'U',
                      style: AppTextStyles.headingMedium.copyWith(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Khách', style: AppTextStyles.bodyLarge),
                        Text(user?.email ?? '', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text('Đăng xuất', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<AuthCubit>().signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSongMenu(BuildContext context, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final songState = context.read<SongCubit>().state;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(song.title, style: AppTextStyles.bodyLarge),
                subtitle: Text(song.artist, style: AppTextStyles.caption),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: AppColors.primary),
                title: Text('Thêm vào Playlist', style: AppTextStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddToPlaylistSheet(context, song, songState.playlists);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistSheet(BuildContext context, SongModel song, List<dynamic> playlists) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chọn Playlist', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Chưa có playlist nào', style: AppTextStyles.bodyMedium)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, i) {
                      final pl = playlists[i];
                      return ListTile(
                        leading: const Icon(Icons.queue_music, color: AppColors.primary),
                        title: Text(pl.title, style: AppTextStyles.bodyLarge),
                        subtitle: Text('${pl.songs.length} bài hát', style: AppTextStyles.caption),
                        onTap: () {
                          context.read<SongCubit>().addSongToPlaylist(pl.id, song);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã thêm bài hát vào "${pl.title}"')),
                          );
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
