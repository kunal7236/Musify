import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/models/app_models.dart';
import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/shared/widgets/app_widgets.dart';
import 'package:Musify/music.dart' as music;

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, musicPlayer, child) {
        return musicPlayer.currentSong != null
            ? RepaintBoundary(
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    color: AppColors.backgroundSecondary,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                    child: Row(
                      children: <Widget>[
                        // Up arrow button - opens music player
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: IconButton(
                            icon: Icon(
                              MdiIcons.appleKeyboardControl,
                              size: 22,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RepaintBoundary(
                                    child: const music.AudioApp(),
                                  ),
                                ),
                              );
                            },
                            disabledColor: AppColors.accent,
                          ),
                        ),
                        // Album art - also opens music player when tapped
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RepaintBoundary(
                                  child: const music.AudioApp(),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.only(
                              left: 0.0,
                              top: 7,
                              bottom: 7,
                              right: 15,
                            ),
                            child: AppImageWidgets.albumArt(
                              imageUrl: musicPlayer.currentSong?.imageUrl ?? '',
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                        // Song title and artist - tappable to open player
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RepaintBoundary(
                                    child: const music.AudioApp(),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 0.0,
                                left: 8.0,
                                right: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    musicPlayer.currentSong?.title ?? 'Unknown',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    musicPlayer.currentSong?.artist ??
                                        'Unknown Artist',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Play/Pause button - DOES NOT open music player
                        Consumer<MusicPlayerProvider>(
                          builder: (context, musicPlayer, child) {
                            // Show loading indicator while song is loading
                            if (musicPlayer.playbackState ==
                                PlaybackState.loading) {
                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.accent,
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Show play/pause button based on playback state
                            return IconButton(
                              icon: musicPlayer.playbackState ==
                                      PlaybackState.playing
                                  ? Icon(MdiIcons.pause)
                                  : Icon(MdiIcons.playOutline),
                              color: AppColors.accent,
                              splashColor: Colors.transparent,
                              onPressed: () async {
                                try {
                                  if (musicPlayer.playbackState ==
                                      PlaybackState.playing) {
                                    await musicPlayer.pause();
                                  } else if (musicPlayer.playbackState ==
                                      PlaybackState.paused) {
                                    await musicPlayer.resume();
                                  } else if (musicPlayer.currentSong != null) {
                                    await musicPlayer
                                        .playSong(musicPlayer.currentSong!);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('No song selected'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('❌ Audio control error: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Audio error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              iconSize: 45,
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}
