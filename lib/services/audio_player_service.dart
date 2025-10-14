import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:Musify/main.dart' show audioHandler;
import 'package:Musify/services/background_audio_handler.dart'
    show createMediaItem;

/// Singleton AudioPlayer service using audio_service for background playback
/// Provides gapless playback, better buffering, enhanced control, and background audio
class AudioPlayerService {
  // Singleton pattern implementation
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // Private fields
  AudioPlayer? _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  // State management
  PlayerState _playerState = PlayerState(false, ProcessingState.idle);
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _currentUrl = "";
  bool _isInitialized = false;

  // Stream controllers for reactive state management
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Public getters
  PlayerState get playerState => _playerState;
  Duration get duration => _duration;
  Duration get position => _position;
  String get currentUrl => _currentUrl;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _playerState.playing;
  bool get isPaused =>
      !_playerState.playing &&
      _playerState.processingState != ProcessingState.idle;
  bool get isStopped => _playerState.processingState == ProcessingState.idle;

  // Public streams for UI updates
  Stream<PlayerState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// Initialize the audio player service
  /// Should be called once during app startup
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        debugPrint('🎵 AudioPlayerService already initialized');
        return;
      }

      // Set up stream listeners from audio handler
      _setupStreamListenersFromHandler();

      _isInitialized = true;
      debugPrint('✅ AudioPlayerService initialized successfully');
    } catch (e) {
      debugPrint('❌ AudioPlayerService initialization failed: $e');
      _handleError('Failed to initialize audio player: $e');
    }
  }

  /// Set up stream listeners from audio handler
  void _setupStreamListenersFromHandler() {
    try {
      // Listen to playback state from audio handler
      audioHandler.playbackState.listen(
        (PlaybackState state) {
          // Map audio_service AudioProcessingState to just_audio ProcessingState
          ProcessingState processingState;
          switch (state.processingState) {
            case AudioProcessingState.idle:
              processingState = ProcessingState.idle;
              break;
            case AudioProcessingState.loading:
              processingState = ProcessingState.loading;
              break;
            case AudioProcessingState.buffering:
              processingState = ProcessingState.buffering;
              break;
            case AudioProcessingState.ready:
              processingState = ProcessingState.ready;
              break;
            case AudioProcessingState.completed:
              processingState = ProcessingState.completed;
              break;
            case AudioProcessingState.error:
              processingState = ProcessingState.idle;
              if (state.errorMessage != null) {
                _handleError('Playback error: ${state.errorMessage}');
              }
              break;
            default:
              processingState = ProcessingState.idle;
          }

          // Only broadcast if state actually changed
          final newState = PlayerState(state.playing, processingState);
          if (newState.playing != _playerState.playing ||
              newState.processingState != _playerState.processingState) {
            _playerState = newState;
            _stateController.add(_playerState);
            debugPrint(
                '🎵 State changed: playing=${state.playing}, processingState=$processingState');
          }
        },
        onError: (error) {
          debugPrint('❌ Playback state stream error: $error');
          _handleError('Player state error: $error');
        },
      );

      // Get position updates from audio handler's player
      _positionSubscription = audioHandler.audioPlayer.positionStream.listen(
        (Duration position) {
          _position = position;
          _positionController.add(position);
        },
        onError: (error) {
          debugPrint('❌ Position stream error: $error');
        },
      );

      // Get duration updates from audio handler's player
      _durationSubscription = audioHandler.audioPlayer.durationStream.listen(
        (Duration? duration) {
          if (duration != null) {
            _duration = duration;
            _durationController.add(duration);
          }
        },
        onError: (error) {
          debugPrint('❌ Duration stream error: $error');
        },
      );

      debugPrint('✅ Stream subscriptions set up successfully');
    } catch (e) {
      debugPrint('❌ Failed to set up stream subscriptions: $e');
      _handleError('Stream setup failed: $e');
    }
  }

  /// Play audio from URL with proper error handling and retry logic
  Future<bool> play(
    String url, {
    String? title,
    String? artist,
    String? album,
    String? artworkUrl,
    String? songId,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Validate URL
      if (url.isEmpty || Uri.tryParse(url) == null) {
        throw Exception('Invalid URL provided: $url');
      }

      debugPrint('🎵 Playing: $url');

      // Update current URL
      _currentUrl = url;

      // Create media item for notification
      final mediaItem = createMediaItem(
        id: songId ?? url,
        title: title ?? 'Unknown Title',
        artist: artist ?? 'Unknown Artist',
        album: album ?? '',
        artUri: artworkUrl,
      );

      // Play through audio handler for background support
      await audioHandler.playFromUrl(url, mediaItem);

      debugPrint('✅ Playback started with background support');
      return true;
    } catch (e) {
      debugPrint('❌ Play failed: $e');
      _handleError('Playback failed: $e');
      return false;
    }
  }

  /// Pause playback
  Future<bool> pause() async {
    try {
      await audioHandler.pause();
      debugPrint('⏸️ Playback paused');
      return true;
    } catch (e) {
      debugPrint('❌ Pause failed: $e');
      _handleError('Pause failed: $e');
      return false;
    }
  }

  /// Resume playback
  Future<bool> resume() async {
    try {
      await audioHandler.play();
      debugPrint('▶️ Playback resumed');
      return true;
    } catch (e) {
      debugPrint('❌ Resume failed: $e');
      _handleError('Resume failed: $e');
      return false;
    }
  }

  /// Stop playback and reset position
  Future<bool> stop() async {
    try {
      await audioHandler.stop();
      _position = Duration.zero;
      _positionController.add(_position);
      debugPrint('⏹️ Playback stopped');
      return true;
    } catch (e) {
      debugPrint('❌ Stop failed: $e');
      _handleError('Stop failed: $e');
      return false;
    }
  }

  /// Seek to specific position
  Future<bool> seek(Duration position) async {
    try {
      // Validate position
      if (position.isNegative || position > _duration) {
        debugPrint('⚠️ Invalid seek position: $position');
        return false;
      }

      await audioHandler.seek(position);
      debugPrint('🎯 Seeked to: $position');
      return true;
    } catch (e) {
      debugPrint('❌ Seek failed: $e');
      _handleError('Seek failed: $e');
      return false;
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<bool> setVolume(double volume) async {
    try {
      // Clamp volume to valid range
      volume = volume.clamp(0.0, 1.0);

      await audioHandler.setVolume(volume);
      debugPrint('🔊 Volume set to: $volume');
      return true;
    } catch (e) {
      debugPrint('❌ Set volume failed: $e');
      _handleError('Volume adjustment failed: $e');
      return false;
    }
  }

  /// Handle errors and emit them to UI
  void _handleError(String error) {
    debugPrint('🚨 AudioPlayerService error: $error');
    _errorController.add(error);
  }

  /// Dispose current player and subscriptions
  Future<void> _disposeCurrentPlayer() async {
    try {
      // Cancel all subscriptions
      await _positionSubscription?.cancel();
      await _durationSubscription?.cancel();
      await _currentIndexSubscription?.cancel();

      // Clear subscriptions
      _positionSubscription = null;
      _durationSubscription = null;
      _currentIndexSubscription = null;

      // Dispose audio player
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }

      debugPrint('🧹 AudioPlayer and subscriptions disposed');
    } catch (e) {
      debugPrint('⚠️ Error during disposal: $e');
      // Continue with disposal even if there are errors
      _audioPlayer = null;
    }
  }

  /// Complete cleanup - call this when app is terminating
  Future<void> dispose() async {
    try {
      debugPrint('🧹 Disposing AudioPlayerService...');

      // Stop playback first
      await stop();

      // Dispose player and subscriptions
      await _disposeCurrentPlayer();

      // Close stream controllers
      await _stateController.close();
      await _positionController.close();
      await _durationController.close();
      await _errorController.close();

      // Reset state
      _playerState = PlayerState(false, ProcessingState.idle);
      _duration = Duration.zero;
      _position = Duration.zero;
      _currentUrl = "";
      _isInitialized = false;

      debugPrint('✅ AudioPlayerService disposed completely');
    } catch (e) {
      debugPrint('❌ Error during AudioPlayerService disposal: $e');
    }
  }

  /// Get current player instance (for advanced use cases)
  /// Use with caution - prefer using service methods
  AudioPlayer? get audioPlayer => _audioPlayer;
}
