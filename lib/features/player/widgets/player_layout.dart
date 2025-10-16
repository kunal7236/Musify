import 'package:flutter/material.dart';
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/providers/app_state_provider.dart';
import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/features/player/player.dart';

class MusicPlayerLayout extends StatelessWidget {
  const MusicPlayerLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions using MediaQuery for responsive layout
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700; // Phones with small screens

    return Consumer2<MusicPlayerProvider, AppStateProvider>(
      builder: (context, musicPlayer, appState, child) {
        final currentSong = musicPlayer.currentSong;
        final songInfo = musicPlayer.getCurrentSongInfo();

        if (currentSong == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('No Song Selected'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Text('No song is currently loaded'),
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: GradientText(
                "Now Playing",
                shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
                gradient: AppColors.accentGradient,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 32,
                    color: AppColors.accent,
                  ),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate responsive spacing
                  final availableHeight = constraints.maxHeight;
                  final topSpacing = isSmallScreen ? 10.0 : 35.0;

                  return SingleChildScrollView(
                    // Enable scrolling on very small screens
                    physics: isSmallScreen
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: availableHeight,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: topSpacing),

                          // Album Art with responsive size
                          Center(
                            child: MusicPlayerAlbumArt(
                              imageUrl: songInfo['imageUrl']!,
                            ),
                          ),

                          // Song Info
                          MusicPlayerSongInfo(
                            title: songInfo['title']!,
                            artist: songInfo['artist']!,
                            album: songInfo['album']!,
                          ),

                          // Responsive spacing instead of Spacer
                          SizedBox(
                            height: isSmallScreen
                                ? 20.0
                                : (availableHeight * 0.05).clamp(20.0, 50.0),
                          ),

                          // Player Controls
                          Material(
                            child: _buildPlayer(
                              context,
                              musicPlayer,
                              appState,
                              screenHeight,
                              screenWidth,
                              isSmallScreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayer(
    BuildContext context,
    MusicPlayerProvider musicPlayer,
    AppStateProvider appState,
    double screenHeight,
    double screenWidth,
    bool isSmallScreen,
  ) {
    // Responsive padding and spacing
    final horizontalPadding = screenWidth * 0.04; // 4% of screen width
    final verticalPadding = isSmallScreen ? 8.0 : 16.0;
    final controlSpacing = isSmallScreen ? 12.0 : 18.0;
    final lyricsButtonTopPadding = isSmallScreen ? 16.0 : 40.0;

    return Container(
      padding: EdgeInsets.only(
        top: 15.0,
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: verticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loop/Repeat Button (above slider)
          Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 4.0 : 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: Icon(
                      musicPlayer.isLoopEnabled
                          ? MdiIcons.repeat
                          : MdiIcons.repeatOff,
                    ),
                    color: musicPlayer.isLoopEnabled
                        ? AppColors.accent
                        : Colors.white54,
                    iconSize: 24,
                    onPressed: () {
                      musicPlayer.toggleLoop();
                      // Show a snackbar with app theme
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                musicPlayer.isLoopEnabled
                                    ? MdiIcons.repeat
                                    : MdiIcons.repeatOff,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  musicPlayer.isLoopEnabled
                                      ? 'Loop ON - Current song will repeat'
                                      : 'Loop OFF - Will play next song',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.backgroundModal,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    tooltip: musicPlayer.isLoopEnabled
                        ? 'Loop: ON (Repeat current song)'
                        : 'Loop: OFF (Play next song)',
                  ),
                ),
              ],
            ),
          ),

          // Progress Slider with loading state
          AnimatedOpacity(
            opacity: musicPlayer.duration.inMilliseconds > 0 ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 300),
            child: PlayerProgressBar(
              position: musicPlayer.position,
              duration: musicPlayer.duration.inMilliseconds > 0
                  ? musicPlayer.duration
                  : const Duration(milliseconds: 1), // Prevent division by zero
              onChanged: musicPlayer.duration.inMilliseconds > 0
                  ? (double value) {
                      musicPlayer.seek(Duration(milliseconds: value.round()));
                    }
                  : null, // Disable interaction when duration is not loaded
            ),
          ),

          // Play/Pause Button and Lyrics
          Padding(
            padding: EdgeInsets.only(top: controlSpacing),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayerControls(
                      isPlaying: musicPlayer.isPlaying,
                      isPaused: musicPlayer.isPaused,
                      hasNext: musicPlayer.hasNextSong,
                      hasPrevious: musicPlayer.hasPreviousSong,
                      onPlay: () {
                        if (musicPlayer.isPaused) {
                          musicPlayer.resume();
                        } else {
                          if (musicPlayer.currentSong != null) {
                            musicPlayer.playSong(musicPlayer.currentSong!);
                          }
                        }
                      },
                      onPause: () => musicPlayer.pause(),
                      onNext: () => musicPlayer.playNext(),
                      onPrevious: () => musicPlayer.playPrevious(),
                      iconSize:
                          isSmallScreen ? 35.0 : 40.0, // Responsive icon size
                    ),
                  ],
                ),

                // Lyrics Button
                if (appState.showLyrics && musicPlayer.currentSong != null)
                  Padding(
                    padding: EdgeInsets.only(top: lyricsButtonTopPadding),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      onPressed: () {
                        LyricsBottomSheet.show(
                            context, musicPlayer.currentSong!);
                      },
                      child: Text(
                        "Lyrics",
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
