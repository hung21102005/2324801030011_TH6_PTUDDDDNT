import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/song_model.dart';

class PlayerState extends Equatable {
  final SongModel? currentSong;
  final List<SongModel> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final bool isShuffle;
  final LoopMode loopMode;
  final String? errorMessage;

  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffle = false,
    this.loopMode = LoopMode.off,
    this.errorMessage,
  });

  bool get hasSong => currentSong != null;

  PlayerState copyWith({
    SongModel? currentSong,
    List<SongModel>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    bool? isShuffle,
    LoopMode? loopMode,
    String? errorMessage,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      isShuffle: isShuffle ?? this.isShuffle,
      loopMode: loopMode ?? this.loopMode,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentSong,
        queue,
        currentIndex,
        isPlaying,
        isBuffering,
        position,
        bufferedPosition,
        duration,
        isShuffle,
        loopMode,
        errorMessage,
      ];
}
