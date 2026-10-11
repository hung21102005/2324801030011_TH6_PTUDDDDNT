import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/song_repository.dart';
import 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final SongRepository _songRepository;

  SongCubit(this._songRepository) : super(const SongState());

  void clearUserData() {
    emit(const SongState());
  }

  Future<void> loadAllData(String? userId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final all = await _songRepository.getAllSongs(currentUserId: userId);
      final trending = await _songRepository.getTrendingSongs(currentUserId: userId);
      final recommended = await _songRepository.getRecommendedSongs(currentUserId: userId);
      final favorites = await _songRepository.getFavorites(userId);
      final playlists = await _songRepository.getUserPlaylists(userId);

      emit(state.copyWith(
        allSongs: all,
        trendingSongs: trending,
        recommendedSongs: recommended,
        favoriteSongs: favorites,
        playlists: playlists,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải dữ liệu bài hát: $e',
      ));
    }
  }

  Future<void> search(String query, {String? userId}) async {
    emit(state.copyWith(searchQuery: query, isSearching: true));
    try {
      final results = await _songRepository.searchSongs(
        query,
        genre: state.selectedGenre,
        currentUserId: userId,
      );
      emit(state.copyWith(
        searchResults: results,
        isSearching: false,
      ));
    } catch (_) {
      emit(state.copyWith(isSearching: false));
    }
  }

  Future<void> selectGenre(String genre, {String? userId}) async {
    emit(state.copyWith(selectedGenre: genre, isSearching: true));
    try {
      final results = await _songRepository.searchSongs(
        state.searchQuery,
        genre: genre,
        currentUserId: userId,
      );
      emit(state.copyWith(
        searchResults: results,
        isSearching: false,
      ));
    } catch (_) {
      emit(state.copyWith(isSearching: false));
    }
  }

  Future<bool> toggleFavorite(String? userId, SongModel song) async {
    try {
      final newFav = await _songRepository.toggleFavorite(userId, song);

      // Update in all lists
      final updatedAll = state.allSongs.map((s) => s.id == song.id ? s.copyWith(isFavorite: newFav) : s).toList();
      final updatedTrending = state.trendingSongs.map((s) => s.id == song.id ? s.copyWith(isFavorite: newFav) : s).toList();
      final updatedRecommended = state.recommendedSongs.map((s) => s.id == song.id ? s.copyWith(isFavorite: newFav) : s).toList();
      final updatedSearch = state.searchResults.map((s) => s.id == song.id ? s.copyWith(isFavorite: newFav) : s).toList();

      List<SongModel> updatedFavorites = List.from(state.favoriteSongs);
      if (newFav) {
        if (!updatedFavorites.any((s) => s.id == song.id)) {
          updatedFavorites.insert(0, song.copyWith(isFavorite: true));
        }
      } else {
        updatedFavorites.removeWhere((s) => s.id == song.id);
      }

      emit(state.copyWith(
        allSongs: updatedAll,
        trendingSongs: updatedTrending,
        recommendedSongs: updatedRecommended,
        searchResults: updatedSearch,
        favoriteSongs: updatedFavorites,
      ));

      return newFav;
    } catch (_) {
      return song.isFavorite;
    }
  }

  Future<void> createPlaylist({
    required String? userId,
    required String title,
    String description = '',
  }) async {
    try {
      final newPlaylist = await _songRepository.createPlaylist(
        userId: userId,
        title: title,
        description: description,
      );
      emit(state.copyWith(
        playlists: [newPlaylist, ...state.playlists],
      ));
    } catch (_) {
      // ignore
    }
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    try {
      await _songRepository.addSongToPlaylist(playlistId, song);
      final updatedPlaylists = state.playlists.map((p) {
        if (p.id == playlistId) {
          if (!p.songs.any((s) => s.id == song.id)) {
            return p.copyWith(songs: [...p.songs, song]);
          }
        }
        return p;
      }).toList();

      emit(state.copyWith(playlists: updatedPlaylists));
    } catch (_) {
      // ignore
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _songRepository.removeSongFromPlaylist(playlistId, songId);
      final updatedPlaylists = state.playlists.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(
            songs: p.songs.where((s) => s.id != songId).toList(),
          );
        }
        return p;
      }).toList();

      emit(state.copyWith(playlists: updatedPlaylists));
    } catch (_) {
      // ignore
    }
  }
}
