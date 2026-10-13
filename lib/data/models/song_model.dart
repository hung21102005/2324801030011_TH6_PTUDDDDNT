import 'package:equatable/equatable.dart';

class SongModel extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String thumbnailUrl;
  final int duration; // in seconds
  final String genre;
  final String album;
  final bool isFavorite;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.genre,
    this.album = '',
    this.isFavorite = false,
  });

  String get durationFormatted {
    final minutes = (duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    String? thumbnailUrl,
    int? duration,
    String? genre,
    String? album,
    bool? isFavorite,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      album: album ?? this.album,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'genre': genre,
      'album': album,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    int parsedDuration = 0;
    final rawDuration = map['duration'];
    if (rawDuration is num) {
      parsedDuration = rawDuration.toInt();
    } else if (rawDuration is String) {
      parsedDuration = int.tryParse(rawDuration) ?? 0;
    }

    return SongModel(
      id: docId ?? (map['id']?.toString() ?? ''),
      title: map['title']?.toString() ?? 'Không tên',
      artist: map['artist']?.toString() ?? 'Nghệ sĩ ẩn danh',
      audioUrl: map['audioUrl']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? '',
      duration: parsedDuration,
      genre: map['genre']?.toString() ?? 'Khác',
      album: map['album']?.toString() ?? '',
      isFavorite: map['isFavorite'] == true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        audioUrl,
        thumbnailUrl,
        duration,
        genre,
        album,
        isFavorite,
      ];
}
