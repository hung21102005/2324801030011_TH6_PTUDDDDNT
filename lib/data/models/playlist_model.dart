import 'package:equatable/equatable.dart';
import 'song_model.dart';

class PlaylistModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final List<SongModel> songs;
  final DateTime createdAt;
  final String userId;

  const PlaylistModel({
    required this.id,
    required this.title,
    this.description = '',
    this.thumbnailUrl = '',
    this.songs = const [],
    required this.createdAt,
    this.userId = '',
  });

  PlaylistModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    List<SongModel>? songs,
    DateTime? createdAt,
    String? userId,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'songIds': songs.map((s) => s.id).toList(),
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory PlaylistModel.fromMap(
    Map<String, dynamic> map, {
    String? docId,
    List<SongModel> allSongs = const [],
  }) {
    final rawSongIds = (map['songIds'] as List<dynamic>?)?.cast<String>() ?? [];
    // Map song IDs to actual songs from the catalog if available
    final matchedSongs = allSongs.where((s) => rawSongIds.contains(s.id)).toList();

    return PlaylistModel(
      id: docId ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? 'Playlist mới',
      description: map['description'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      songs: matchedSongs,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      userId: map['userId'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        thumbnailUrl,
        songs,
        createdAt,
        userId,
      ];
}
