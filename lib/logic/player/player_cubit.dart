import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../../core/services/audio_player_service.dart';
import '../../data/models/song_model.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayerService _audioService;
  final List<StreamSubscription> _subscriptions = [];

  PlayerCubit(this._audioService) : super(const PlayerState()) {
    _listenToAudioService();
  }

  void _listenToAudioService() {
    // 1. Position and Buffer stream
    _subscriptions.add(
      _audioService.positionDataStream.listen((data) {
        emit(state.copyWith(
          position: data.position,
          bufferedPosition: data.bufferedPosition,
          duration: data.duration,
        ));
      }),
    );

    // 2. Playback state (playing, buffering, completed)
    _subscriptions.add(
      _audioService.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final isBuffering = playerState.processingState == ja.ProcessingState.buffering ||
            playerState.processingState == ja.ProcessingState.loading;

        emit(state.copyWith(
          isPlaying: isPlaying,
          isBuffering: isBuffering,
        ));
      }),
    );

    // 3. Current Song index stream
    _subscriptions.add(
      _audioService.currentIndexStream.listen((index) {
        if (index != null && index >= 0 && index < state.queue.length) {
          emit(state.copyWith(
            currentIndex: index,
            currentSong: state.queue[index],
          ));
        }
      }),
    );

    // 4. Shuffle mode stream
    _subscriptions.add(
      _audioService.shuffleModeEnabledStream.listen((enabled) {
        emit(state.copyWith(isShuffle: enabled));
      }),
    );

    // 5. Repeat mode stream
    _subscriptions.add(
      _audioService.loopModeStream.listen((loopMode) {
        emit(state.copyWith(loopMode: loopMode));
      }),
    );
  }

  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    final effectiveQueue = (queue != null && queue.isNotEmpty)
        ? queue
        : (state.queue.any((s) => s.id == song.id) ? state.queue : [song]);

    final songIndex = effectiveQueue.indexWhere((s) => s.id == song.id);
    final targetIndex = songIndex >= 0 ? songIndex : 0;

    emit(state.copyWith(
      currentSong: song,
      queue: effectiveQueue,
      currentIndex: targetIndex,
      isBuffering: true,
      duration: Duration(seconds: song.duration),
      position: Duration.zero,
      errorMessage: null,
    ));

    try {
      await _audioService.loadQueueAndPlay(effectiveQueue, initialIndex: targetIndex);
    } catch (e) {
      emit(state.copyWith(
        isBuffering: false,
        errorMessage: 'Không thể kết nối luồng phát: $e',
      ));
    }
  }

  Future<void> playPlaylist(List<SongModel> songs, {int startIndex = 0, bool shuffle = false}) async {
    if (songs.isEmpty) return;

    List<SongModel> effectiveSongs = List.from(songs);
    int targetIndex = (startIndex >= 0 && startIndex < effectiveSongs.length) ? startIndex : 0;

    if (shuffle) {
      effectiveSongs.shuffle();
      targetIndex = 0;
    }

    final initialSong = effectiveSongs[targetIndex];
    emit(state.copyWith(
      currentSong: initialSong,
      queue: effectiveSongs,
      currentIndex: targetIndex,
      isShuffle: shuffle,
      isBuffering: true,
      duration: Duration(seconds: initialSong.duration),
      position: Duration.zero,
      errorMessage: null,
    ));

    await _audioService.setShuffle(shuffle);
    try {
      await _audioService.loadQueueAndPlay(effectiveSongs, initialIndex: targetIndex);
    } catch (e) {
      emit(state.copyWith(
        isBuffering: false,
        errorMessage: 'Không thể kết nối luồng phát: $e',
      ));
    }
  }

  Future<void> playPause() async {
    if (state.currentSong == null) {
      if (state.queue.isNotEmpty) {
        await playSong(state.queue.first);
      }
      return;
    }
    await _audioService.togglePlayPause();
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> next() async {
    await _audioService.skipToNext();
  }

  Future<void> previous() async {
    await _audioService.skipToPrevious();
  }

  Future<void> toggleShuffle() async {
    await _audioService.toggleShuffle();
  }

  Future<void> toggleRepeat() async {
    await _audioService.toggleRepeat();
  }

  void updateSongFavoriteStatus(String songId, bool isFavorite) {
    if (state.currentSong?.id == songId) {
      emit(state.copyWith(
        currentSong: state.currentSong?.copyWith(isFavorite: isFavorite),
      ));
    }

    // Also update in queue
    final updatedQueue = state.queue.map((s) {
      if (s.id == songId) {
        return s.copyWith(isFavorite: isFavorite);
      }
      return s;
    }).toList();

    emit(state.copyWith(queue: updatedQueue));
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _audioService.dispose();
    return super.close();
  }
}
