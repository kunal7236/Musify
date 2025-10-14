import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:audio_service/audio_service.dart';

import 'package:Musify/ui/homePage.dart';
import 'package:Musify/services/audio_player_service.dart';
import 'package:Musify/services/background_audio_handler.dart';
import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/providers/search_provider.dart';
import 'package:Musify/providers/app_state_provider.dart';

// Global audio handler instance
late MusifyAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio_service with custom handler
  debugPrint('🎵 Initializing audio_service...');
  try {
    audioHandler = await AudioService.init(
      builder: () => MusifyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.gokadzev.musify.channel.audio',
        androidNotificationChannelName: 'Musify Audio',
        androidNotificationChannelDescription: 'Music playback controls',
        androidStopForegroundOnPause:
            false, // Don't stop service when paused - allows background playback
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    debugPrint('✅ audio_service initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Failed to initialize audio_service: $e');
    debugPrint('⚠️ Background playback will not be available');
  }

  runApp(const MusifyApp());
}

class MusifyApp extends StatefulWidget {
  const MusifyApp({super.key});

  @override
  _MusifyAppState createState() => _MusifyAppState();
}

class _MusifyAppState extends State<MusifyApp> with WidgetsBindingObserver {
  late final AudioPlayerService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = AudioPlayerService();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App is in background - audio_service handles background playback
        debugPrint('🎵 App backgrounded - audio continues via audio_service');
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground
        debugPrint('🎵 App resumed - audio ready');
        break;
      case AppLifecycleState.detached:
        // App is being terminated - cleanup audio resources
        _audioService.dispose();
        debugPrint('🧹 AudioPlayerService disposed - app terminated');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// AppStateProvider - Global app state, theme, preferences
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
        ),

        /// MusicPlayerProvider - Audio playback state and controls
        ChangeNotifierProvider(
          create: (_) => MusicPlayerProvider(),
        ),

        /// SearchProvider - Search state, results, and top songs
        ChangeNotifierProvider(
          create: (_) => SearchProvider(),
        ),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Musify',
            theme: appState.getLightThemeData(),
            darkTheme: appState.getDarkThemeData(),
            themeMode: appState.themeMode,
            home: const Musify(),
            builder: EasyLoading.init(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
