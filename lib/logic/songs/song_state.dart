import 'package:equatable/equatable.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';

class SongState extends Equatable {
  final List<SongModel> trendingSongs;
  final List<SongModel> recommendedSongs;
  final List<SongModel> allSongs;
  final List<SongModel> searchResults;
  final List<SongModel> favoriteSongs;
  final List<PlaylistModel> playlists;
  final String selectedGenre;
  final String searchQuery;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;

  const SongState({
    this.trendingSongs = const [],
    this.recommendedSongs = const [],
    this.allSongs = const [],
    this.searchResults = const [],
    this.favoriteSongs = const [],
    this.playlists = const [],
    this.selectedGenre = 'Tất cả',
    this.searchQuery = '',
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
  });

  bool get hasActiveSearch => searchQuery.trim().isNotEmpty || selectedGenre != 'Tất cả';

  SongState copyWith({
    List<SongModel>? trendingSongs,
    List<SongModel>? recommendedSongs,
    List<SongModel>? allSongs,
    List<SongModel>? searchResults,
    List<SongModel>? favoriteSongs,
    List<PlaylistModel>? playlists,
    String? selectedGenre,
    String? searchQuery,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
  }) {
    return SongState(
      trendingSongs: trendingSongs ?? this.trendingSongs,
      recommendedSongs: recommendedSongs ?? this.recommendedSongs,
      allSongs: allSongs ?? this.allSongs,
      searchResults: searchResults ?? this.searchResults,
      favoriteSongs: favoriteSongs ?? this.favoriteSongs,
      playlists: playlists ?? this.playlists,
      selectedGenre: selectedGenre ?? this.selectedGenre,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        trendingSongs,
        recommendedSongs,
        allSongs,
        searchResults,
        favoriteSongs,
        playlists,
        selectedGenre,
        searchQuery,
        isLoading,
        isSearching,
        errorMessage,
      ];
}
