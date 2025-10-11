import 'package:flutter/material.dart';
import 'package:Musify/style/appColors.dart';
import 'package:Musify/ui/homePage.dart';
import 'package:Musify/services/audio_player_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/services.dart';

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

  runApp(MusifyApp());
}

class MusifyApp extends StatefulWidget {
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
    return MaterialApp(
      title: 'Musify',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
          ),
        ),
        fontFamily: "DMSans",
        colorScheme: ColorScheme.fromSeed(seedColor: accent),
        primaryColor: accent,
        canvasColor: Colors.transparent,
      ),
      home: Musify(),
      builder: EasyLoading.init(),
      debugShowCheckedModeBanner: false,
    );
  }
}
