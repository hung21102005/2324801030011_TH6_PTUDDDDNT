import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User? user;
  final String displayName;
  final String email;
  final bool isGuest;

  const Authenticated({
    this.user,
    required this.displayName,
    required this.email,
    this.isGuest = false,
  });

  String get avatarInitial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

  @override
  List<Object?> get props => [user?.uid, displayName, email, isGuest];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
