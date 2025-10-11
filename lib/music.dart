import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:Musify/style/appColors.dart';
import 'package:Musify/services/audio_player_service.dart';

import 'API/saavn.dart';

String status = 'hidden';
// Removed global AudioPlayer and PlayerState - now managed by AudioPlayerService

typedef void OnError(Exception exception);

class AudioApp extends StatefulWidget {
  @override
  AudioAppState createState() => AudioAppState();
}

class AudioAppState extends State<AudioApp> {
  late final AudioPlayerService _audioService;
  Duration? duration;
  Duration? position;
  PlayerState? playerState;

  // Stream subscriptions for cleanup
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<String>? _errorSubscription;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    _audioService = AudioPlayerService();
    _initializeAudioService();
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    // Note: Don't dispose the service itself as it's a singleton used across the app
    super.dispose();
  }

  /// Initialize the audio service and set up listeners
  void _initializeAudioService() async {
    try {
      // Ensure service is initialized
      if (!_audioService.isInitialized) {
        await _audioService.initialize();
      }

      // Set up stream subscriptions
      _setupStreamListeners();

      // Get current state from service
      setState(() {
        playerState = _audioService.playerState;
        duration = _audioService.duration;
        position = _audioService.position;
      });

      // Handle the checker logic for play/pause state
      if (checker == "Haa") {
        await _handleNewSong();
      } else if (checker == "Nahi") {
        await _handleExistingSong();
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize audio service: $e');
      _showErrorSnackBar('Failed to initialize audio player: $e');
    }
  }

  /// Set up stream listeners for reactive UI updates
  void _setupStreamListeners() {
    _stateSubscription = _audioService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          playerState = state;
        });
      }
    });

    _positionSubscription = _audioService.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          position = pos;
        });
      }
    });

    _durationSubscription = _audioService.durationStream.listen((dur) {
      if (mounted) {
        setState(() {
          duration = dur;
        });
      }
    });

    _errorSubscription = _audioService.errorStream.listen((error) {
      if (mounted) {
        _showErrorSnackBar(error);
      }
    });
  }

  /// Handle playing a new song
  Future<void> _handleNewSong() async {
    try {
      debugPrint('🎵 Playing new song: $kUrl');
      if (kUrl.isNotEmpty) {
        await _audioService.stop();
        await _audioService.play(kUrl);
      }
    } catch (e) {
      debugPrint('❌ Failed to play new song: $e');
      _showErrorSnackBar('Failed to play song: $e');
    }
  }

  /// Handle resuming existing song or UI state
  Future<void> _handleExistingSong() async {
    try {
      if (_audioService.isPlaying) {
        // Song is already playing, just update UI
        debugPrint('🎵 Song already playing, updating UI');
      } else {
        // Start playing the current song
        if (kUrl.isNotEmpty) {
          await _audioService.play(kUrl);
        }
        // Pause immediately for UI consistency (matching original logic)
        await _audioService.pause();
      }
    } catch (e) {
      debugPrint('❌ Failed to handle existing song: $e');
      _showErrorSnackBar('Audio playback error: $e');
    }
  }

  /// Clean up stream subscriptions
  void _cleanupSubscriptions() {
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _errorSubscription?.cancel();
  }

  /// Show error message to user
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Play audio with proper error handling
  Future<void> play() async {
    try {
      // Validate URL before playing
      if (kUrl.isEmpty || Uri.tryParse(kUrl) == null) {
        throw Exception('Invalid or empty audio URL');
      }

      debugPrint('🎵 Playing: $kUrl');
      final success = await _audioService.play(kUrl);

      if (!success) {
        throw Exception('Audio service failed to start playback');
      }
    } catch (e) {
      debugPrint('❌ Play failed: $e');
      _showErrorSnackBar('Error playing song: $e');
    }
  }

  /// Pause audio playback
  Future<void> pause() async {
    try {
      final success = await _audioService.pause();
      if (!success) {
        debugPrint('⚠️ Pause operation failed');
      }
    } catch (e) {
      debugPrint('❌ Pause failed: $e');
      _showErrorSnackBar('Error pausing playback: $e');
    }
  }

  /// Stop audio playback
  Future<void> stop() async {
    try {
      final success = await _audioService.stop();
      if (!success) {
        debugPrint('⚠️ Stop operation failed');
      }
    } catch (e) {
      debugPrint('❌ Stop failed: $e');
      _showErrorSnackBar('Error stopping playback: $e');
    }
  }

  /// Mute/unmute audio
  Future<void> mute(bool muted) async {
    try {
      final volume = muted ? 0.0 : 1.0;
      final success = await _audioService.setVolume(volume);

      if (success && mounted) {
        setState(() {
          isMuted = muted;
        });
      }
    } catch (e) {
      debugPrint('❌ Mute failed: $e');
      _showErrorSnackBar('Error adjusting volume: $e');
    }
  }

  /// Handle seek operations
  Future<void> onSeek(Duration position) async {
    try {
      await _audioService.seek(position);
    } catch (e) {
      debugPrint('❌ Seek failed: $e');
      _showErrorSnackBar('Error seeking: $e');
    }
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

          // AppBar(
          //   backgroundColor: Colors.transparent,
          //   elevation: 0,
          //   //backgroundColor: Color(0xff384850),
          //   centerTitle: true,
          //   title: Text(
          //     "Now Playing",
          //     style: TextStyle(
          //       color: accent,
          //       fontSize: 25,
          //       fontWeight: FontWeight.w700,
          //     ),
          //   ),
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
                      GradientText(
                        title,
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
                      // Text(
                      //   title,
                      //   textScaler: TextScaler.linear(2.5),
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w700,
                      //       color: accent),
                      // ),
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
                    onSeek(Duration(milliseconds: value.round()));
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
