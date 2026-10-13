import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  final Random _random = Random();
  StreamSubscription? _playerStateSubscription;

  List<SongModel> _playlist = [];
  int _currentIndex = 0;

  final BehaviorSubject<int?> _currentIndexSubject = BehaviorSubject<int?>.seeded(null);
  final BehaviorSubject<bool> _shuffleSubject = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<LoopMode> _loopModeSubject = BehaviorSubject<LoopMode>.seeded(LoopMode.off);

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
  Stream<int?> get currentIndexStream => _currentIndexSubject.stream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<LoopMode> get loopModeStream => _loopModeSubject.stream;
  Stream<bool> get shuffleModeEnabledStream => _shuffleSubject.stream;

  AudioPlayerService() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompleted();
      }
    });
  }

  Future<void> _handleTrackCompleted() async {
    final loopMode = _loopModeSubject.value;
    if (loopMode == LoopMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (loopMode == LoopMode.all) {
      await skipToNext();
    } else {
      // LoopMode.off
      if (_currentIndex < _playlist.length - 1) {
        await skipToNext();
      } else {
        // End of playlist
        await _player.pause();
        await _player.seek(Duration.zero);
      }
    }
  }

  Future<void> loadQueueAndPlay(List<SongModel> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    _playlist = List.from(songs);
    _currentIndex = (initialIndex >= 0 && initialIndex < songs.length) ? initialIndex : 0;
    _currentIndexSubject.add(_currentIndex);

    await _playCurrentTrack();
  }

  Future<void> _playCurrentTrack() async {
    if (_playlist.isEmpty || _currentIndex < 0 || _currentIndex >= _playlist.length) return;

    final song = _playlist[_currentIndex];
    _currentIndexSubject.add(_currentIndex);

    try {
      await _player.stop();
      await _player.setUrl(song.audioUrl);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing ${song.title} (${song.audioUrl}): $e');
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
    if (_playlist.isEmpty) return;

    if (_shuffleSubject.value && _playlist.length > 1) {
      int nextIndex;
      do {
        nextIndex = _random.nextInt(_playlist.length);
      } while (nextIndex == _currentIndex);
      _currentIndex = nextIndex;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }

    await _playCurrentTrack();
  }

  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await _playCurrentTrack();
  }

  Future<void> setShuffle(bool enable) async {
    _shuffleSubject.add(enable);
  }

  Future<void> toggleShuffle() async {
    _shuffleSubject.add(!_shuffleSubject.value);
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _loopModeSubject.add(mode);
  }

  Future<void> toggleRepeat() async {
    switch (_loopModeSubject.value) {
      case LoopMode.off:
        _loopModeSubject.add(LoopMode.all);
        break;
      case LoopMode.all:
        _loopModeSubject.add(LoopMode.one);
        break;
      case LoopMode.one:
        _loopModeSubject.add(LoopMode.off);
        break;
    }
  }

  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _currentIndexSubject.close();
    await _shuffleSubject.close();
    await _loopModeSubject.close();
    await _player.dispose();
  }
}
