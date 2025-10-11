import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'package:Musify/style/appColors.dart';
import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/providers/app_state_provider.dart';
import 'package:Musify/models/app_models.dart';

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
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Text('No song is currently loaded'),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff384850),
                Color(0xff263238),
                Color(0xff263238),
              ],
            ),
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
                gradient: LinearGradient(colors: [
                  Color(0xff4db6ac),
                  Color(0xff61e88a),
                ]),
                style: TextStyle(
                  color: accent,
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
                    color: accent,
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
                    RepaintBoundary(
                      child: Container(
                        width: 350,
                        height: 350,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: songInfo['imageUrl']!,
                            fit: BoxFit.cover,
                            memCacheWidth: 500,
                            memCacheHeight: 500,
                            maxWidthDiskCache: 500,
                            maxHeightDiskCache: 500,
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[900],
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(accent),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[900],
                              child: Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
                                color: accentLight,
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
            Slider(
              activeColor: accent,
              inactiveColor: Colors.green[50],
              value: musicPlayer.position.inMilliseconds.toDouble(),
              onChanged: (double value) {
                musicPlayer.seek(Duration(milliseconds: value.round()));
              },
              min: 0.0,
              max: musicPlayer.duration.inMilliseconds.toDouble(),
            ),

          // Time Display
          if (musicPlayer.position.inMilliseconds > 0)
            _buildProgressView(musicPlayer),

          // Play/Pause Button and Lyrics
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!musicPlayer.isPlaying)
                      Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xff4db6ac),
                                Color(0xff61e88a),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(100)),
                        child: IconButton(
                          onPressed: musicPlayer.isPlaying
                              ? null
                              : () {
                                  if (musicPlayer.isPaused) {
                                    musicPlayer.resume();
                                  } else {
                                    // Play current song
                                    if (musicPlayer.currentSong != null) {
                                      musicPlayer
                                          .playSong(musicPlayer.currentSong!);
                                    }
                                  }
                                },
                          iconSize: 40.0,
                          icon: Padding(
                            padding: const EdgeInsets.only(left: 2.2),
                            child: Icon(MdiIcons.playOutline),
                          ),
                          color: Color(0xff263238),
                        ),
                      ),
                    if (musicPlayer.isPlaying)
                      Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xff4db6ac),
                                Color(0xff61e88a),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(100)),
                        child: IconButton(
                          onPressed: musicPlayer.isPlaying
                              ? () => musicPlayer.pause()
                              : null,
                          iconSize: 40.0,
                          icon: Icon(MdiIcons.pause),
                          color: Color(0xff263238),
                        ),
                      )
                  ],
                ),

                // Lyrics Button
                if (appState.showLyrics &&
                    musicPlayer.currentSong?.hasLyrics == true)
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
                        style: TextStyle(color: accent),
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

  Widget _buildProgressView(MusicPlayerProvider musicPlayer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          musicPlayer.positionText,
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        ),
        Spacer(),
        Text(
          musicPlayer.durationText,
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        )
      ],
    );
  }

  void _showLyricsBottomSheet(BuildContext context, Song song) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
              decoration: BoxDecoration(
                  color: Color(0xff212c31),
                  borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18.0),
                      topRight: const Radius.circular(18.0))),
              height: MediaQuery.of(context).size.height * 0.7,
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
                              color: accent,
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
                                  color: accent,
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
                                      color: accentLight,
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
                                style:
                                    TextStyle(color: accentLight, fontSize: 25),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ));
  }
}
