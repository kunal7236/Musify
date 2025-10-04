import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:gradient_widgets/gradient_widgets.dart';  // Temporarily disabled
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:Musify/style/appColors.dart';

import 'API/saavn.dart';

String status = 'hidden';
AudioPlayer? audioPlayer;
PlayerState? playerState;

typedef void OnError(Exception exception);

class AudioApp extends StatefulWidget {
  @override
  AudioAppState createState() => AudioAppState();
}

class AudioAppState extends State<AudioApp> {
  Duration? duration;
  Duration? position;

  get isPlaying => playerState == PlayerState.playing;

  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription? _audioPlayerStateSubscription;

  @override
  void initState() {
    super.initState();

    initAudioPlayer();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _audioPlayerStateSubscription?.cancel();
    audioPlayer?.dispose();
    super.dispose();
  }

  void initAudioPlayer() {
    // Dispose previous instance if it exists
    if (audioPlayer != null) {
      _positionSubscription?.cancel();
      _audioPlayerStateSubscription?.cancel();
      audioPlayer!.dispose().catchError((e) {
        debugPrint('Error disposing previous AudioPlayer: $e');
      });
      audioPlayer = null;
    }

    // Always create a fresh AudioPlayer instance for each new song
    audioPlayer = AudioPlayer();
    debugPrint('✅ Created fresh AudioPlayer instance');

    setState(() {
      if (checker == "Haa") {
        stop();
        play();
      }
      if (checker == "Nahi") {
        if (playerState == PlayerState.playing) {
          play();
        } else {
          //Using (Hack) Play() here Else UI glitch is being caused, Will try to find better solution.
          play();
          pause();
        }
      }
    });

    _positionSubscription = audioPlayer!.onPositionChanged.listen((p) {
      if (mounted) setState(() => position = p);
    });

    _audioPlayerStateSubscription =
        audioPlayer!.onPlayerStateChanged.listen((s) {
      if (s == PlayerState.playing) {
        // Get duration when playing starts
        audioPlayer!.getDuration().then((d) {
          if (mounted && d != null) setState(() => duration = d);
        });
      } else if (s == PlayerState.stopped) {
        onComplete();
        if (mounted)
          setState(() {
            position = duration;
          });
      }
    }, onError: (msg) {
      debugPrint('AudioPlayer error: $msg');
      if (mounted)
        setState(() {
          playerState = PlayerState.stopped;
          duration = Duration(seconds: 0);
          position = Duration(seconds: 0);
        });
    });
  }

  Future play() async {
    // Ensure we have a valid AudioPlayer instance - create fresh one if needed
    if (audioPlayer == null) {
      debugPrint('🔄 AudioPlayer was null, creating fresh instance...');
      initAudioPlayer();
      // Wait a moment for initialization
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Check if kUrl is valid before trying to play
    if (kUrl.isEmpty || Uri.tryParse(kUrl) == null) {
      debugPrint('❌ Cannot play: Invalid or empty URL - $kUrl');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Unable to play song. Invalid audio URL.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      debugPrint('🎵 Attempting to play URL: $kUrl');

      // Stop any previous playback first
      if (playerState == PlayerState.playing) {
        await audioPlayer!.stop();
      }

      await audioPlayer!.play(UrlSource(kUrl));
      if (mounted)
        setState(() {
          playerState = PlayerState.playing;
        });
      debugPrint('✅ Successfully started playing');
    } catch (e) {
      debugPrint('❌ Error playing audio: $e');
      // If we get a disposed player error, create a fresh instance and retry
      if (e.toString().contains('disposed') ||
          e.toString().contains('created')) {
        debugPrint(
            '🔄 Player was disposed, creating fresh instance and retrying...');
        initAudioPlayer();
        await Future.delayed(Duration(milliseconds: 200));
        try {
          await audioPlayer!.play(UrlSource(kUrl));
          if (mounted)
            setState(() {
              playerState = PlayerState.playing;
            });
          debugPrint('✅ Successfully started playing after recreating player');
        } catch (retryError) {
          debugPrint('❌ Retry failed: $retryError');
          // Show error to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing song: $retryError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing song: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future pause() async {
    await audioPlayer!.pause();
    setState(() {
      playerState = PlayerState.paused;
    });
  }

  Future stop() async {
    try {
      if (audioPlayer != null) {
        await audioPlayer!.stop();
        if (mounted)
          setState(() {
            playerState = PlayerState.stopped;
            position = Duration();
          });
        debugPrint('✅ Successfully stopped playback');
      }
    } catch (e) {
      debugPrint('⚠️ Error stopping audio: $e');
      // Even if stop fails, update the UI state
      if (mounted)
        setState(() {
          playerState = PlayerState.stopped;
          position = Duration();
        });
    }
  }

  Future mute(bool muted) async {
    await audioPlayer!.setVolume(muted ? 0.0 : 1.0);
    if (mounted)
      setState(() {
        isMuted = muted;
      });
  }

  void onComplete() {
    if (mounted) setState(() => playerState = PlayerState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff384850),
            Color(0xff263238),
            Color(0xff263238),
            //Color(0xff61e88a),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          //backgroundColor: Color(0xff384850),
          centerTitle: true,
          title: Text(
            "Now Playing",
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
                Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    shape: BoxShape.rectangle,
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: CachedNetworkImageProvider(image),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 35.0, bottom: 35),
                  child: Column(
                    children: <Widget>[
                      Text(
                        title,
                        textScaleFactor: 2.5,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          album + "  |  " + artist,
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
                Material(child: _buildPlayer()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.only(top: 15.0, left: 16, right: 16, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (duration != null)
              Slider(
                  activeColor: accent,
                  inactiveColor: Colors.green[50],
                  value: position?.inMilliseconds.toDouble() ?? 0.0,
                  onChanged: (double value) {
                    audioPlayer!.seek(Duration(milliseconds: value.round()));
                  },
                  min: 0.0,
                  max: duration?.inMilliseconds.toDouble() ?? 0.0),
            if (position != null) _buildProgressView(),
            Padding(
              padding: const EdgeInsets.only(top: 18.0),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isPlaying
                          ? Container()
                          : Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff4db6ac),
                                      //Color(0xff00c754),
                                      Color(0xff61e88a),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(100)),
                              child: IconButton(
                                onPressed: isPlaying ? null : () => play(),
                                iconSize: 40.0,
                                icon: Padding(
                                  padding: const EdgeInsets.only(left: 2.2),
                                  child: Icon(MdiIcons.playOutline),
                                ),
                                color: Color(0xff263238),
                              ),
                            ),
                      isPlaying
                          ? Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff4db6ac),
                                      //Color(0xff00c754),
                                      Color(0xff61e88a),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(100)),
                              child: IconButton(
                                onPressed: isPlaying ? () => pause() : null,
                                iconSize: 40.0,
                                icon: Icon(MdiIcons.pause),
                                color: Color(0xff263238),
                              ),
                            )
                          : Container()
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Builder(builder: (context) {
                      return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0))),
                          onPressed: () {
                            showBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                      decoration: BoxDecoration(
                                          color: Color(0xff212c31),
                                          borderRadius: BorderRadius.only(
                                              topLeft:
                                                  const Radius.circular(18.0),
                                              topRight:
                                                  const Radius.circular(18.0))),
                                      height: 400,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10.0),
                                            child: Row(
                                              children: <Widget>[
                                                IconButton(
                                                    icon: Icon(
                                                      Icons.arrow_back_ios,
                                                      color: accent,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => {
                                                          Navigator.pop(context)
                                                        }),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 42.0),
                                                    child: Center(
                                                      child: Text(
                                                        "Lyrics",
                                                        style: TextStyle(
                                                          color: accent,
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          has_lyrics != "false"
                                              ? Expanded(
                                                  flex: 1,
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6.0),
                                                      child: Center(
                                                        child:
                                                            SingleChildScrollView(
                                                          child: Text(
                                                            lyrics,
                                                            style: TextStyle(
                                                              fontSize: 16.0,
                                                              color:
                                                                  accentLight,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      )),
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 120.0),
                                                  child: Center(
                                                    child: Container(
                                                      child: Text(
                                                        "No Lyrics available ;(",
                                                        style: TextStyle(
                                                            color: accentLight,
                                                            fontSize: 25),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ));
                          },
                          child: Text(
                            "Lyrics",
                            style: TextStyle(color: accent),
                          ));
                    }),
                  )
                ],
              ),
            ),
          ],
        ),
      );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          position != null
              ? "${positionText ?? ''} ".replaceFirst("0:0", "0")
              : duration != null
                  ? durationText
                  : '',
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        ),
        Spacer(),
        Text(
          position != null
              ? "${durationText ?? ''}".replaceAll("0:", "")
              : duration != null
                  ? durationText
                  : '',
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        )
      ]);
}
