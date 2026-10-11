import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../core/services/firebase_service.dart';

class AuthRepository {
  final FirebaseAuth? _auth = FirebaseService.auth;
  final FirebaseFirestore? _firestore = FirebaseService.firestore;

  // Stream of authenticated Firebase user
  Stream<User?> get authStateChanges {
    if (_auth != null) {
      return _auth.authStateChanges();
    }
    // Fallback stream if Firebase not initialized
    return Stream.value(null);
  }

  User? get currentUser => _auth?.currentUser;

  Future<User?> signInWithEmail(String email, String password) async {
    final trimmedEmail = email.trim();
    if (_auth != null) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: password.trim(),
        );
        return credential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'configuration-not-found' &&
            (e.message == null || !e.message!.contains('CONFIGURATION_NOT_FOUND'))) {
          throw _handleAuthException(e);
        }
      }
    }

    // Fallback if Firebase Auth is not configured on console
    if (_firestore != null) {
      try {
        final doc = await _firestore.collection('users').doc(trimmedEmail).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(trimmedEmail).set({
            'id': trimmedEmail,
            'email': trimmedEmail,
            'displayName': trimmedEmail.split('@').first,
            'favoriteSongIds': [],
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}
    }
    return null;
  }

  Future<User?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final trimmedEmail = email.trim();
    final trimmedName = displayName.trim();

    User? user;
    if (_auth != null) {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: trimmedEmail,
          password: password.trim(),
        );
        user = credential.user;
        if (user != null) {
          await user.updateDisplayName(trimmedName);
        }
      } on FirebaseAuthException catch (e) {
        // If CONFIGURATION_NOT_FOUND (app not added to console or auth not enabled),
        // we continue to create the user profile in Firestore
        if (e.code != 'configuration-not-found' &&
            (e.message == null || !e.message!.contains('CONFIGURATION_NOT_FOUND'))) {
          throw _handleAuthException(e);
        }
      }
    }

    // ALWAYS write new user to Firestore collection 'users'
    // so every registered account appears in the Firebase console
    final docId = user?.uid ?? trimmedEmail;
    if (_firestore != null) {
      try {
        final userModel = UserModel(
          id: docId,
          email: trimmedEmail,
          displayName: trimmedName,
          favoriteSongIds: const [],
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(docId).set(
              userModel.toMap(),
              SetOptions(merge: true),
            );
      } catch (_) {}
    }

    return user;
  }

  Future<User?> signInAnonymously() async {
    if (_auth == null) {
      return null;
    }
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    if (_auth != null) {
      await _auth.signOut();
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    if (e.code == 'configuration-not-found' ||
        (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND'))) {
      return 'Dịch vụ Email/Password chưa được kích hoạt trên Firebase Console. Vui lòng vào Firebase Console > Authentication > Sign-in method để bật.';
    }
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu hoặc thông tin đăng nhập không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng bởi một tài khoản khác.';
      case 'invalid-email':
        return 'Địa chỉ email không đúng định dạng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu, vui lòng chọn ít nhất 6 ký tự.';
      case 'operation-not-allowed':
        return 'Đăng nhập ẩn danh hoặc Email/Password chưa được bật trên Firebase Console.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối Internet.';
      default:
        return e.message ?? 'Đã xảy ra lỗi xác thực. Vui lòng thử lại.';
    }
  }
}
