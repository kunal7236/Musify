import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Reusable player control widgets
/// Eliminates duplication in player controls across different screens
class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isPaused;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool hasNext;
  final bool hasPrevious;
  final double iconSize;
  final Color? iconColor;
  final Gradient? gradient;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isPaused,
    this.onPlay,
    this.onPause,
    this.onNext,
    this.onPrevious,
    this.hasNext = false,
    this.hasPrevious = false,
    this.iconSize = AppConstants.playerControlSize,
    this.iconColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        if (onPrevious != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: IconButton(
              iconSize: iconSize * 0.7,
              icon: Icon(
                MdiIcons.skipPrevious,
                color: hasPrevious
                    ? AppColors.accent
                    : AppColors.textSecondary.withOpacity(0.5),
              ),
              onPressed: hasPrevious ? onPrevious : null,
            ),
          ),

        // Play/Pause button
        if (!isPlaying) _buildPlayButton(),
        if (isPlaying) _buildPauseButton(),

        // Next button
        if (onNext != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: IconButton(
              iconSize: iconSize * 0.7,
              icon: Icon(
                MdiIcons.skipNext,
                color: hasNext
                    ? AppColors.accent
                    : AppColors.textSecondary.withOpacity(0.5),
              ),
              onPressed: hasNext ? onNext : null,
            ),
          ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return AppContainerWidgets.gradientButton(
      gradient: gradient ?? AppColors.buttonGradient,
      onPressed: onPlay ?? () {},
      child: Icon(
        MdiIcons.play,
        size: iconSize,
        color: iconColor ?? AppColors.backgroundSecondary,
      ),
    );
  }

  Widget _buildPauseButton() {
    return AppContainerWidgets.gradientButton(
      gradient: gradient ?? AppColors.buttonGradient,
      onPressed: onPause ?? () {},
      child: Icon(
        MdiIcons.pause,
        size: iconSize,
        color: iconColor ?? AppColors.backgroundSecondary,
      ),
    );
  }
}

/// Progress bar widget for audio playback
class PlayerProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<double>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const PlayerProgressBar({
    super.key,
    required this.position,
    required this.duration,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp position to duration to prevent slider errors when song completes
    final clampedPosition = position.inMilliseconds.toDouble().clamp(
          0.0,
          duration.inMilliseconds.toDouble(),
        );

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: AppConstants.progressBarHeight,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: clampedPosition,
            onChanged: onChanged,
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
            activeColor: activeColor ?? AppColors.accent,
            inactiveColor: inactiveColor ?? AppColors.textSecondary,
          ),
        ),
        _buildTimeDisplay(),
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDuration(position),
            style: const TextStyle(
              fontSize: 14.0,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              fontSize: 14.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Mini player widget for bottom navigation
class MiniPlayer extends StatelessWidget {
  final String? title;
  final String? artist;
  final String? imageUrl;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;

  const MiniPlayer({
    super.key,
    this.title,
    this.artist,
    this.imageUrl,
    required this.isPlaying,
    this.onTap,
    this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    if (title == null || imageUrl == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Container(
        height: AppConstants.miniPlayerHeight,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppConstants.buttonBorderRadius),
            topRight: Radius.circular(AppConstants.buttonBorderRadius),
          ),
          color: AppColors.backgroundTertiary,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              child: Row(
                children: [
                  AppImageWidgets.thumbnail(
                    imageUrl: imageUrl!,
                    size: AppConstants.thumbnailSize,
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (artist != null)
                          Text(
                            artist!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onPlayPause,
                    icon: Icon(
                      isPlaying ? MdiIcons.pause : MdiIcons.play,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
