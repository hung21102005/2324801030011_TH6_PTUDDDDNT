import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(
          user: user,
          displayName: user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (user.email?.split('@').first ?? 'Người nghe nhạc'),
          email: user.email ?? 'Ẩn danh',
          isGuest: user.isAnonymous,
        ));
      } else {
        if (state is! Authenticated || (state as Authenticated).isGuest == false) {
          emit(Unauthenticated());
        }
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmail(email, password);
      if (user != null) {
        emit(Authenticated(
          user: user,
          displayName: user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (user.email?.split('@').first ?? 'Người nghe nhạc'),
          email: user.email ?? email,
        ));
      } else {
        emit(const AuthError('Đăng nhập không thành công.'));
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('CONFIGURATION_NOT_FOUND') ||
          errorMsg.contains('chưa được kích hoạt')) {
        // Fallback to local session so the user is never blocked
        emit(Authenticated(
          displayName: email.split('@').first,
          email: email,
        ));
      } else {
        emit(AuthError(errorMsg));
      }
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.registerWithEmail(email, password, displayName);
      if (user != null) {
        emit(Authenticated(
          user: user,
          displayName: displayName,
          email: email,
        ));
      } else {
        emit(Authenticated(
          displayName: displayName,
          email: email,
        ));
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('CONFIGURATION_NOT_FOUND') ||
          errorMsg.contains('chưa được kích hoạt')) {
        // Fallback to local session so the user can immediately experience the app
        emit(Authenticated(
          displayName: displayName,
          email: email,
        ));
      } else {
        emit(AuthError(errorMsg));
      }
    }
  }

  Future<void> signInAsGuest() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInAnonymously();
      emit(Authenticated(
        user: user,
        displayName: 'Khách yêu nhạc',
        email: 'khach@vibemusic.app',
        isGuest: true,
      ));
    } catch (_) {
      // Offline guest mode
      emit(const Authenticated(
        displayName: 'Khách yêu nhạc',
        email: 'khach@vibemusic.app',
        isGuest: true,
      ));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    await _authRepository.signOut();
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
