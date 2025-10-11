import 'package:flutter/material.dart';
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';
import 'package:provider/provider.dart';

import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/providers/app_state_provider.dart';
import 'package:Musify/models/app_models.dart';

// New modular imports
import 'package:Musify/core/core.dart';
import 'package:Musify/shared/shared.dart';
import 'package:Musify/features/player/player.dart';

String status = 'hidden';
// Removed global AudioPlayer and PlayerState - now managed by AudioPlayerService

typedef void OnError(Exception exception);

class AudioApp extends StatefulWidget {
  const AudioApp({super.key});

  @override
  AudioAppState createState() => AudioAppState();
}

class AudioAppState extends State<AudioApp> {
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
                onPressed: () => AppNavigation.pop(context),
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
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 35.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Album Art
                    AppImageWidgets.albumArt(
                      imageUrl: songInfo['imageUrl']!,
                      width: AppConstants.albumArtSize,
                      height: AppConstants.albumArtSize,
                      backgroundColor: AppColors.backgroundSecondary,
                      accentColor: AppColors.accent,
                    ),

                    // Song Info
                    Padding(
                      padding: const EdgeInsets.only(top: 35.0, bottom: 35),
                      child: Column(
                        children: <Widget>[
                          GradientText(
                            songInfo['title']!,
                            shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
                            gradient: LinearGradient(colors: [
                              Color(0xff4db6ac),
                              Color(0xff61e88a),
                            ]),
                            textScaleFactor: 2.5,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${songInfo['album']!}  |  ${songInfo['artist']!}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Player Controls
                    Material(
                        child: _buildPlayer(context, musicPlayer, appState)),
                  ],
                ),
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
          // Progress Slider
          if (musicPlayer.duration.inMilliseconds > 0)
            PlayerProgressBar(
              position: musicPlayer.position,
              duration: musicPlayer.duration,
              onChanged: (double value) {
                musicPlayer.seek(Duration(milliseconds: value.round()));
              },
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
                              borderRadius: BorderRadius.circular(18.0))),
                      onPressed: () {
                        _showLyricsBottomSheet(
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

  void _showLyricsBottomSheet(BuildContext context, Song song) {
    // Calculate height to start from below play/pause button
    // This positions the modal to cover only the lower portion of the screen
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.5; // Cover bottom 50% of screen

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
              decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18.0),
                      topRight: const Radius.circular(18.0))),
              height: modalHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.accent,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 42.0),
                            child: Center(
                              child: Text(
                                "Lyrics",
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  song.hasLyrics && song.lyrics.isNotEmpty
                      ? Expanded(
                          flex: 1,
                          child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Center(
                                child: SingleChildScrollView(
                                  child: Text(
                                    song.lyrics,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )),
                        )
                      : Expanded(
                          child: Center(
                            child: Container(
                              child: Text(
                                "No Lyrics available ;(",
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 25),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ));
  }
}
