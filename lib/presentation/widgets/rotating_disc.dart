import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RotatingDisc extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;
  final double size;

  const RotatingDisc({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
    this.size = 280,
  });

  @override
  State<RotatingDisc> createState() => _RotatingDiscState();
}

class _RotatingDiscState extends State<RotatingDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RotatingDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFF2B2B2B),
              Color(0xFF151515),
              Color(0xFF0A0A0A),
            ],
            stops: [0.6, 0.85, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 25,
              spreadRadius: 4,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: widget.isPlaying ? 0.25 : 0.05),
              blurRadius: 35,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vinyl grooves simulation
            Container(
              width: widget.size * 0.88,
              height: widget.size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: widget.size * 0.72,
              height: widget.size * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04),
                  width: 1.2,
                ),
              ),
            ),
            // Center Album Art
            ClipOval(
              child: SizedBox(
                width: widget.size * 0.44,
                height: widget.size * 0.44,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceHighlight,
                    child: const Icon(Icons.music_note, color: AppColors.primary),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceHighlight,
                    child: const Icon(Icons.album, color: Colors.white54),
                  ),
                ),
              ),
            ),
            // Center spindle hole
            Container(
              width: widget.size * 0.1,
              height: widget.size * 0.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
