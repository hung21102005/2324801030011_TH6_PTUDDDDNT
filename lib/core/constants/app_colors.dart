import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF1DB954); // Spotify Neon Green
  static const Color primaryLight = Color(0xFF1ED760);
  static const Color primaryDark = Color(0xFF15883E);
  static const Color accent = Color(0xFFBB86FC); // Subtle Violet Accent

  // Background & Surface (Pure Spotify Dark Style)
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF282828);
  static const Color surfaceHighlight = Color(0xFF333333);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF757575);

  // States & Utility
  static const Color error = Color(0xFFE91E63);
  static const Color favorite = Color(0xFFFF4081);
  static const Color divider = Color(0xFF242424);
  static const Color shimmerBase = Color(0xFF2A2A2A);
  static const Color shimmerHighlight = Color(0xFF3E3E3E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2E2E2E), Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient playerBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFF2E3D30),
      Color(0xFF1A211B),
      Color(0xFF121212),
      Color(0xFF121212),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
