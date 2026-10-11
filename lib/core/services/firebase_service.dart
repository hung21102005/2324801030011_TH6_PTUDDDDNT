import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static FirebaseAuth? get auth => _isInitialized ? FirebaseAuth.instance : null;
  static FirebaseFirestore? get firestore => _isInitialized ? FirebaseFirestore.instance : null;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;
    } catch (e) {
      // In case Firebase setup is not enabled or network fails, app will smoothly fallback
      _isInitialized = false;
    }
  }

  // Firestore Collection References
  static CollectionReference<Map<String, dynamic>>? get songsCollection =>
      _isInitialized ? FirebaseFirestore.instance.collection('songs') : null;

  static CollectionReference<Map<String, dynamic>>? get usersCollection =>
      _isInitialized ? FirebaseFirestore.instance.collection('users') : null;

  static CollectionReference<Map<String, dynamic>>? get playlistsCollection =>
      _isInitialized ? FirebaseFirestore.instance.collection('playlists') : null;
}
