import 'package:flutter/material.dart';
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/providers/app_state_provider.dart';
import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/features/player/widgets/album_art_widget.dart';
import 'package:Musify/features/player/widgets/lyrics_modal.dart';
import 'package:Musify/features/player/player.dart';

class MusicPlayerLayout extends StatelessWidget {
  const MusicPlayerLayout({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  SizedBox(height: 35),

                  // Album Art with fixed constraints
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

                  // Spacer to push controls down
                  Spacer(),

                  // Player Controls
                  Material(
                    child: _buildPlayer(context, musicPlayer, appState),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayer(BuildContext context, MusicPlayerProvider musicPlayer,
      AppStateProvider appState) {
    return Container(
      padding: EdgeInsets.only(top: 15.0, left: 16, right: 16, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loop/Repeat Button (above slider)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
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
                      // Show a snackbar for feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            musicPlayer.isLoopEnabled
                                ? '🔁 Loop ON - Current song will repeat'
                                : '⏭️ Loop OFF - Will play next song',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
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
            padding: const EdgeInsets.only(top: 18.0),
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
                      iconSize: 40.0,
                    ),
                  ],
                ),

                // Lyrics Button
                if (appState.showLyrics && musicPlayer.currentSong != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
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
