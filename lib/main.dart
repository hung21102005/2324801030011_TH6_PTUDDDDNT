import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/services/audio_player_service.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/song_repository.dart';
import 'logic/auth/auth_cubit.dart';
import 'logic/auth/auth_state.dart';
import 'logic/player/player_cubit.dart';
import 'logic/songs/song_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay to match dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase with fallback tolerance
  await FirebaseService.initialize();

  // Create singletons / services
  final audioService = AudioPlayerService();
  final authRepository = AuthRepository();
  final songRepository = SongRepository();

  runApp(
    VibeMusicApp(
      audioService: audioService,
      authRepository: authRepository,
      songRepository: songRepository,
    ),
  );
}

class VibeMusicApp extends StatelessWidget {
  final AudioPlayerService audioService;
  final AuthRepository authRepository;
  final SongRepository songRepository;

  const VibeMusicApp({
    super.key,
    required this.audioService,
    required this.authRepository,
    required this.songRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(authRepository),
        ),
        BlocProvider<PlayerCubit>(
          create: (_) => PlayerCubit(audioService),
        ),
        BlocProvider<SongCubit>(
          create: (_) => SongCubit(songRepository)..loadAllData(authRepository.currentUser?.uid),
        ),
      ],
      child: MaterialApp(
        title: 'VibeMusic - Nghe Nhạc Online',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Refresh song lists & personal playlists for this authenticated user
          context.read<SongCubit>().loadAllData(state.user?.uid ?? state.email);
        } else if (state is Unauthenticated) {
          // Clear previous user's favorite songs and playlists
          context.read<SongCubit>().clearUserData();
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const MainNavigationScreen();
        } else if (state is AuthLoading && state is! Authenticated) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
