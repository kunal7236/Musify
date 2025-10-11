import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:Musify/ui/homePage.dart';
import 'package:Musify/services/audio_player_service.dart';
import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/providers/search_provider.dart';
import 'package:Musify/providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the AudioPlayerService at app startup for optimal performance
  try {
    final audioService = AudioPlayerService();
    await audioService.initialize();
    debugPrint('✅ AudioPlayerService initialized at app startup');
  } catch (e) {
    debugPrint('⚠️ Failed to initialize AudioPlayerService at startup: $e');
    // Continue app startup even if audio service fails to initialize
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
        // App is in background - pause audio if playing
        if (_audioService.isPlaying) {
          _audioService.pause();
          debugPrint('🎵 Audio paused - app backgrounded');
        }
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground - audio will be controlled by user
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
