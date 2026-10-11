import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/models/song_model.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );
}

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _playlist = [];
  int _currentIndex = 0;

  AudioPlayer get player => _player;
  List<SongModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  SongModel? get currentSong =>
      (_playlist.isNotEmpty && _currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  AudioPlayerService() {
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
      }
    });

    // Auto next handling when song ends
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_player.loopMode == LoopMode.off && _currentIndex >= _playlist.length - 1) {
          _player.pause();
          _player.seek(Duration.zero, index: 0);
        }
      }
    });
  }

  Future<void> loadQueueAndPlay(List<SongModel> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    _playlist = List.from(songs);
    _currentIndex = (initialIndex >= 0 && initialIndex < songs.length) ? initialIndex : 0;

    try {
      final audioSources = _playlist.map((song) {
        return AudioSource.uri(
          Uri.parse(song.audioUrl),
          tag: song,
        );
      }).toList();

      await _player.setAudioSources(
        audioSources,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );

      await _player.play();
    } catch (e) {
      // Fallback single audio source if concatenating encounters stream source error
      try {
        final current = _playlist[_currentIndex];
        await _player.setUrl(current.audioUrl);
        await _player.play();
      } catch (innerError) {
        // ignore
      }
    }
  }

  Future<void> play() async => await _player.play();

  Future<void> pause() async => await _player.pause();

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_playlist.isNotEmpty) {
      // Loop to beginning if playlist allows
      await _player.seek(Duration.zero, index: 0);
      await _player.play();
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_player.position.inSeconds > 3) {
      // Replay current song from start if played > 3 seconds
      await _player.seek(Duration.zero);
    } else if (_playlist.isNotEmpty) {
      await _player.seek(Duration.zero, index: _playlist.length - 1);
    }
  }

  Future<void> toggleShuffle() async {
    final enable = !_player.shuffleModeEnabled;
    if (enable) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enable);
  }

  Future<void> toggleRepeat() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
