import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/player/player_cubit.dart';
import '../../../logic/player/player_state.dart' as p;
import '../../../logic/songs/song_cubit.dart';
import '../../../logic/songs/song_state.dart';
import '../../widgets/song_tile.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Khám phá âm nhạc', style: AppTextStyles.headingMedium),
      ),
      body: BlocBuilder<SongCubit, SongState>(
        builder: (context, songState) {
          final authState = context.read<AuthCubit>().state;
          final userId = authState is Authenticated ? (authState.user?.uid ?? authState.email) : null;

          return BlocBuilder<PlayerCubit, p.PlayerState>(
            builder: (context, playerState) {
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Tất cả bài hát (${songState.allSongs.length})',
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  ...songState.allSongs.map((song) {
                    final isCurrent = playerState.currentSong?.id == song.id;
                    return SongTile(
                      song: song,
                      isCurrentSong: isCurrent,
                      isPlaying: isCurrent && playerState.isPlaying,
                      onTap: () {
                        context.read<PlayerCubit>().playSong(
                              song,
                              queue: songState.allSongs,
                            );
                      },
                      onFavoriteTap: () {
                        final playerCubit = context.read<PlayerCubit>();
                        context.read<SongCubit>().toggleFavorite(userId, song).then((newFav) {
                          playerCubit.updateSongFavoriteStatus(song.id, newFav);
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 100),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
