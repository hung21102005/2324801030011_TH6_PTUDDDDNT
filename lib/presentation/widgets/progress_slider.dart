import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ProgressSlider extends StatelessWidget {
  final Duration position;
  final Duration bufferedPosition;
  final Duration totalDuration;
  final ValueChanged<Duration> onSeek;

  const ProgressSlider({
    super.key,
    required this.position,
    required this.bufferedPosition,
    required this.totalDuration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressBar(
      progress: position,
      buffered: bufferedPosition,
      total: totalDuration,
      onSeek: onSeek,
      barHeight: 4.0,
      baseBarColor: Colors.white.withValues(alpha: 0.15),
      bufferedBarColor: Colors.white.withValues(alpha: 0.3),
      progressBarColor: AppColors.primary,
      thumbColor: Colors.white,
      thumbGlowColor: AppColors.primary.withValues(alpha: 0.35),
      thumbRadius: 6.0,
      thumbGlowRadius: 16.0,
      timeLabelLocation: TimeLabelLocation.below,
      timeLabelTextStyle: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      timeLabelPadding: 6.0,
    );
  }
}
