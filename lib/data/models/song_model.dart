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
    return SongModel(
      id: docId ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? 'Không tên',
      artist: map['artist'] as String? ?? 'Nghệ sĩ ẩn danh',
      audioUrl: map['audioUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      genre: map['genre'] as String? ?? 'Khác',
      album: map['album'] as String? ?? '',
      isFavorite: map['isFavorite'] as bool? ?? false,
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
