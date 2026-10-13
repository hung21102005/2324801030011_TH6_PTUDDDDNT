import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class SongRepository {
  final FirebaseFirestore? _firestore = FirebaseService.firestore;

  // In-memory catalog
  List<SongModel> _catalogSongs = List.from(AppConstants.mockSongs);

  // User-isolated favorites map: key is userId / email
  final Map<String, Set<String>> _userFavorites = {};

  // User-isolated playlists map: key is userId / email
  final Map<String, List<PlaylistModel>> _userPlaylists = {};

  // Seed Firestore if empty or missing songs
  Future<void> _seedFirestoreIfEmpty() async {
    if (_firestore == null) return;
    try {
      final snapshot = await _firestore.collection('songs').get();
      final existingIds = snapshot.docs.map((d) => d.id).toSet();

      final batch = _firestore.batch();
      bool hasNew = false;
      for (final song in AppConstants.mockSongs) {
        if (!existingIds.contains(song.id)) {
          final docRef = _firestore.collection('songs').doc(song.id);
          batch.set(docRef, song.toMap());
          hasNew = true;
        }
      }
      if (hasNew) {
        await batch.commit();
      }
    } catch (_) {
      // Permission or network error fallback silently
    }
  }

  // Get all songs
  Future<List<SongModel>> getAllSongs({String? currentUserId}) async {
    if (_firestore != null) {
      try {
        await _seedFirestoreIfEmpty();
        final snapshot = await _firestore.collection('songs').get();
        if (snapshot.docs.isNotEmpty) {
          final songs = snapshot.docs.map((doc) {
            return SongModel.fromMap(doc.data(), doc.id);
          }).toList();
          _catalogSongs = songs;
        }
      } catch (_) {
        // Use local fallback
      }
    }

    // Attach favorite status strictly for currentUserId
    final favIds = await getFavoriteSongIds(currentUserId);
    return _catalogSongs.map((s) => s.copyWith(isFavorite: favIds.contains(s.id))).toList();
  }

  // Get trending songs
  Future<List<SongModel>> getTrendingSongs({String? currentUserId}) async {
    final songs = await getAllSongs(currentUserId: currentUserId);
    return songs.take(5).toList();
  }

  // Get recommended songs
  Future<List<SongModel>> getRecommendedSongs({String? currentUserId}) async {
    final songs = await getAllSongs(currentUserId: currentUserId);
    return songs.skip(2).toList();
  }

  // Search songs by title or artist or genre
  Future<List<SongModel>> searchSongs(String query, {String? genre, String? currentUserId}) async {
    final all = await getAllSongs(currentUserId: currentUserId);
    final trimmed = query.trim().toLowerCase();

    return all.where((song) {
      final matchQuery = trimmed.isEmpty ||
          song.title.toLowerCase().contains(trimmed) ||
          song.artist.toLowerCase().contains(trimmed) ||
          song.album.toLowerCase().contains(trimmed);

      final matchGenre = genre == null ||
          genre == 'Tất cả' ||
          song.genre.toLowerCase().contains(genre.toLowerCase());

      return matchQuery && matchGenre;
    }).toList();
  }

  // Favorite IDs isolated per userId
  Future<Set<String>> getFavoriteSongIds(String? userId) async {
    if (userId == null || userId.isEmpty) {
      return {};
    }

    if (_firestore != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data['favoriteSongIds'] != null) {
            final list = (data['favoriteSongIds'] as List<dynamic>).cast<String>();
            final set = list.toSet();
            _userFavorites[userId] = set;
            return set;
          }
        }
        // User doc has no favorites or does not exist yet: return empty set
        _userFavorites[userId] = {};
        return {};
      } catch (_) {
        // Fallback to local
      }
    }

    return _userFavorites[userId] ?? {};
  }

  // Toggle favorite for a specific user
  Future<bool> toggleFavorite(String? userId, SongModel song) async {
    final key = (userId != null && userId.isNotEmpty) ? userId : 'guest';
    final userFavs = _userFavorites.putIfAbsent(key, () => <String>{});
    final isFav = userFavs.contains(song.id);
    final newFavState = !isFav;

    if (newFavState) {
      userFavs.add(song.id);
    } else {
      userFavs.remove(song.id);
    }

    if (userId != null && userId.isNotEmpty && _firestore != null) {
      try {
        final userRef = _firestore.collection('users').doc(userId);
        if (newFavState) {
          await userRef.set({
            'favoriteSongIds': FieldValue.arrayUnion([song.id]),
          }, SetOptions(merge: true));
        } else {
          await userRef.set({
            'favoriteSongIds': FieldValue.arrayRemove([song.id]),
          }, SetOptions(merge: true));
        }
      } catch (_) {
        // local update suffices
      }
    }

    return newFavState;
  }

  // Get Favorites list
  Future<List<SongModel>> getFavorites(String? userId) async {
    if (userId == null || userId.isEmpty) return [];
    final favIds = await getFavoriteSongIds(userId);
    final all = await getAllSongs(currentUserId: userId);
    return all.where((s) => favIds.contains(s.id)).map((s) => s.copyWith(isFavorite: true)).toList();
  }

  // Get User Playlists strictly for current userId
  Future<List<PlaylistModel>> getUserPlaylists(String? userId) async {
    if (userId == null || userId.isEmpty) return [];

    if (_firestore != null) {
      try {
        final snapshot = await _firestore
            .collection('playlists')
            .where('userId', isEqualTo: userId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final all = await getAllSongs(currentUserId: userId);
          final list = snapshot.docs.map((doc) {
            return PlaylistModel.fromMap(doc.data(), docId: doc.id, allSongs: all);
          }).toList();
          _userPlaylists[userId] = list;
          return list;
        } else {
          _userPlaylists[userId] = [];
          return [];
        }
      } catch (_) {
        // local fallback
      }
    }

    return _userPlaylists[userId] ?? [];
  }

  // Create playlist for current user
  Future<PlaylistModel> createPlaylist({
    required String? userId,
    required String title,
    String description = '',
  }) async {
    final userKey = (userId != null && userId.isNotEmpty) ? userId : 'guest';
    final newPlaylist = PlaylistModel(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      thumbnailUrl: AppConstants.mockSongs.first.thumbnailUrl,
      songs: [],
      createdAt: DateTime.now(),
      userId: userKey,
    );

    final list = _userPlaylists.putIfAbsent(userKey, () => []);
    list.insert(0, newPlaylist);

    if (userId != null && userId.isNotEmpty && _firestore != null) {
      try {
        await _firestore.collection('playlists').doc(newPlaylist.id).set(newPlaylist.toMap());
      } catch (_) {
        // local fallback
      }
    }

    return newPlaylist;
  }

  // Add song to playlist
  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    for (final list in _userPlaylists.values) {
      final index = list.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final current = list[index];
        if (!current.songs.any((s) => s.id == song.id)) {
          final updatedSongs = List<SongModel>.from(current.songs)..add(song);
          list[index] = current.copyWith(
            songs: updatedSongs,
            thumbnailUrl: current.thumbnailUrl.isEmpty ? song.thumbnailUrl : current.thumbnailUrl,
          );
        }
      }
    }

    if (_firestore != null) {
      try {
        await _firestore.collection('playlists').doc(playlistId).update({
          'songIds': FieldValue.arrayUnion([song.id]),
        });
      } catch (_) {
        // fallback
      }
    }
  }

  // Remove song from playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    for (final list in _userPlaylists.values) {
      final index = list.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final current = list[index];
        final updatedSongs = current.songs.where((s) => s.id != songId).toList();
        list[index] = current.copyWith(songs: updatedSongs);
      }
    }

    if (_firestore != null) {
      try {
        await _firestore.collection('playlists').doc(playlistId).update({
          'songIds': FieldValue.arrayRemove([songId]),
        });
      } catch (_) {
        // fallback
      }
    }
  }
}
