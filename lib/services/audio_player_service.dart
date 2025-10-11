import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Singleton AudioPlayer service following industry standards for memory management
/// and performance optimization. Prevents memory leaks and ensures proper resource cleanup.
class AudioPlayerService {
  // Singleton pattern implementation
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // Private fields
  AudioPlayer? _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _completionSubscription;

  // State management
  PlayerState _playerState = PlayerState.stopped;
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
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped;

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

      await _createAudioPlayer();
      _isInitialized = true;
      debugPrint('✅ AudioPlayerService initialized successfully');
    } catch (e) {
      debugPrint('❌ AudioPlayerService initialization failed: $e');
      _handleError('Failed to initialize audio player: $e');
    }
  }

  /// Create a new AudioPlayer instance with proper configuration
  Future<void> _createAudioPlayer() async {
    try {
      // Dispose previous instance if exists
      await _disposeCurrentPlayer();

      // Create new player instance
      _audioPlayer = AudioPlayer();

      // Configure player for optimal performance
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer!.setPlayerMode(PlayerMode.mediaPlayer);

      // Set up stream subscriptions with proper error handling
      _setupStreamSubscriptions();

      debugPrint('✅ New AudioPlayer instance created and configured');
    } catch (e) {
      debugPrint('❌ Failed to create AudioPlayer: $e');
      throw Exception('AudioPlayer creation failed: $e');
    }
  }

  /// Set up stream subscriptions for player events
  void _setupStreamSubscriptions() {
    try {
      if (_audioPlayer == null) return;

      // Position updates
      _positionSubscription = _audioPlayer!.onPositionChanged.listen(
        (Duration position) {
          _position = position;
          _positionController.add(position);
        },
        onError: (error) {
          debugPrint('❌ Position stream error: $error');
          _handleError('Position tracking error: $error');
        },
      );

      // Duration updates
      _durationSubscription = _audioPlayer!.onDurationChanged.listen(
        (Duration duration) {
          _duration = duration;
          _durationController.add(duration);
        },
        onError: (error) {
          debugPrint('❌ Duration stream error: $error');
          _handleError('Duration tracking error: $error');
        },
      );

      // Player state changes
      _playerStateSubscription = _audioPlayer!.onPlayerStateChanged.listen(
        (PlayerState state) {
          _playerState = state;
          _stateController.add(state);

          debugPrint('🎵 Player state changed: $state');

          // Handle completion
          if (state == PlayerState.completed) {
            _handleCompletion();
          }
        },
        onError: (error) {
          debugPrint('❌ Player state stream error: $error');
          _handleError('Player state error: $error');
        },
      );

      debugPrint('✅ Stream subscriptions set up successfully');
    } catch (e) {
      debugPrint('❌ Failed to set up stream subscriptions: $e');
      _handleError('Stream setup failed: $e');
    }
  }

  /// Play audio from URL with proper error handling and retry logic
  Future<bool> play(String url) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_audioPlayer == null) {
        throw Exception('AudioPlayer not initialized');
      }

      // Validate URL
      if (url.isEmpty || Uri.tryParse(url) == null) {
        throw Exception('Invalid URL provided: $url');
      }

      debugPrint('🎵 Playing: $url');

      // Stop current playback if any
      if (_playerState == PlayerState.playing) {
        await _audioPlayer!.stop();
      }

      // Update current URL
      _currentUrl = url;

      // Start playback with retry logic
      await _playWithRetry(url);

      return true;
    } catch (e) {
      debugPrint('❌ Play failed: $e');
      _handleError('Playback failed: $e');
      return false;
    }
  }

  /// Play with retry logic for better reliability
  Future<void> _playWithRetry(String url, [int retryCount = 0]) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(milliseconds: 500);

    try {
      await _audioPlayer!.play(UrlSource(url));
      debugPrint('✅ Playback started successfully');
    } catch (e) {
      if (retryCount < maxRetries) {
        debugPrint('🔄 Retry ${retryCount + 1}/$maxRetries after error: $e');
        await Future.delayed(retryDelay);

        // Recreate player if it seems to be in a bad state
        if (e.toString().contains('disposed') ||
            e.toString().contains('created')) {
          await _createAudioPlayer();
        }

        await _playWithRetry(url, retryCount + 1);
      } else {
        throw Exception('Playback failed after $maxRetries attempts: $e');
      }
    }
  }

  /// Pause playback
  Future<bool> pause() async {
    try {
      if (_audioPlayer == null || !isPlaying) {
        debugPrint('⚠️ Cannot pause: player not playing');
        return false;
      }

      await _audioPlayer!.pause();
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
      if (_audioPlayer == null || !isPaused) {
        debugPrint('⚠️ Cannot resume: player not paused');
        return false;
      }

      await _audioPlayer!.resume();
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
      if (_audioPlayer == null) {
        debugPrint('⚠️ Cannot stop: player not initialized');
        return false;
      }

      await _audioPlayer!.stop();
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
      if (_audioPlayer == null) {
        debugPrint('⚠️ Cannot seek: player not initialized');
        return false;
      }

      // Validate position
      if (position.isNegative || position > _duration) {
        debugPrint('⚠️ Invalid seek position: $position');
        return false;
      }

      await _audioPlayer!.seek(position);
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
      if (_audioPlayer == null) {
        debugPrint('⚠️ Cannot set volume: player not initialized');
        return false;
      }

      // Clamp volume to valid range
      volume = volume.clamp(0.0, 1.0);

      await _audioPlayer!.setVolume(volume);
      debugPrint('🔊 Volume set to: $volume');
      return true;
    } catch (e) {
      debugPrint('❌ Set volume failed: $e');
      _handleError('Volume adjustment failed: $e');
      return false;
    }
  }

  /// Handle playback completion
  void _handleCompletion() {
    debugPrint('🏁 Playback completed');
    _position = _duration;
    _positionController.add(_position);
    // Reset state to stopped
    _playerState = PlayerState.stopped;
    _stateController.add(_playerState);
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
      await _playerStateSubscription?.cancel();
      await _completionSubscription?.cancel();

      // Clear subscriptions
      _positionSubscription = null;
      _durationSubscription = null;
      _playerStateSubscription = null;
      _completionSubscription = null;

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
      _playerState = PlayerState.stopped;
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

  /// Force recreate player (for error recovery)
  Future<void> recreatePlayer() async {
    try {
      debugPrint('🔄 Recreating AudioPlayer...');
      await _createAudioPlayer();
      debugPrint('✅ AudioPlayer recreated successfully');
    } catch (e) {
      debugPrint('❌ Failed to recreate AudioPlayer: $e');
      _handleError('Player recreation failed: $e');
    }
  }
}
