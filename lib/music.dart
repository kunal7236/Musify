import 'package:flutter/material.dart';

// New modular imports
import 'package:Musify/features/player/player.dart';

String status = 'hidden';

typedef void OnError(Exception exception);

class AudioApp extends StatefulWidget {
  const AudioApp({super.key});

  @override
  AudioAppState createState() => AudioAppState();
}

class AudioAppState extends State<AudioApp> {
  @override
  Widget build(BuildContext context) {
    return const MusicPlayerLayout();
  }
}