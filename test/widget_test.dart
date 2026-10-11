import 'package:flutter_test/flutter_test.dart';
import 'package:ung_dung_nghe_nhac_online/core/constants/app_constants.dart';
import 'package:ung_dung_nghe_nhac_online/data/models/song_model.dart';

void main() {
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
    expect(AppConstants.mockSongs.isNotEmpty, true);
  });
}
