import 'package:flutter_test/flutter_test.dart';
import 'package:ung_dung_nghe_nhac_online/core/constants/app_constants.dart';
import 'package:ung_dung_nghe_nhac_online/data/models/song_model.dart';

void main() {
  group('SongModel Tests', () {
    test('SongModel formatting and properties test', () {
      const song = SongModel(
        id: 'test_1',
        title: 'Test Song',
        artist: 'Test Artist',
        audioUrl: 'https://example.com/audio.mp3',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        duration: 215,
        genre: 'Pop',
      );

      expect(song.durationFormatted, '03:35');
      expect(song.title, 'Test Song');
      expect(AppConstants.mockSongs.length, 8);
    });

    test('SongModel.fromMap handles num duration', () {
      final map = {
        'id': 's1',
        'title': 'Song 1',
        'artist': 'Artist 1',
        'duration': 300,
      };
      final song = SongModel.fromMap(map);
      expect(song.duration, 300);
      expect(song.durationFormatted, '05:00');
    });

    test('SongModel.fromMap handles String duration gracefully', () {
      final map = {
        'id': 's2',
        'title': 'Song 2',
        'artist': 'Artist 2',
        'duration': '256',
      };
      final song = SongModel.fromMap(map);
      expect(song.duration, 256);
      expect(song.durationFormatted, '04:16');
    });

    test('SongModel.fromMap handles missing/null duration', () {
      final map = {
        'id': 's3',
        'title': 'Song 3',
        'artist': 'Artist 3',
      };
      final song = SongModel.fromMap(map);
      expect(song.duration, 0);
      expect(song.durationFormatted, '00:00');
    });
  });
}
