import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:Musify/models/app_models.dart';
import 'package:Musify/services/audio_player_service.dart';

/// MusicPlayerProvider following industry standards for state management
/// Manages audio playback state, current song, and player controls
/// Uses Provider pattern with ChangeNotifier for reactive UI updates
class MusicPlayerProvider extends ChangeNotifier {
  // Private fields
  late final AudioPlayerService _audioService;
  Song? _currentSong;
  PlaybackState _playbackState = PlaybackState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  AppError? _error;
  bool _isInitialized = false;
  double _volume = 1.0;
  bool _isMuted = false;

  // Stream subscriptions for cleanup
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<String>? _errorSubscription;

  // Throttling for position updates to reduce UI redraws
  DateTime _lastPositionUpdate = DateTime.now();

  /// Constructor
  MusicPlayerProvider() {
    _audioService = AudioPlayerService();
    // Delay initialization to avoid race condition with JustAudioBackground.init()
    Future.microtask(() => _initializeService());
  }

  // Public getters
  Song? get currentSong => _currentSong;
  PlaybackState get playbackState => _playbackState;
  Duration get position => _position;
  Duration get duration => _duration;
  AppError? get error => _error;
  bool get isInitialized => _isInitialized;
  double get volume => _volume;
  bool get isMuted => _isMuted;

  // Computed properties
  bool get isPlaying => _playbackState == PlaybackState.playing;
  bool get isPaused => _playbackState == PlaybackState.paused;
  bool get isLoading => _playbackState == PlaybackState.loading;
  bool get isError => _playbackState == PlaybackState.error;
  bool get isStopped => _playbackState == PlaybackState.stopped;
  bool get hasCurrentSong => _currentSong != null;

  String get positionText => _formatDuration(_position);
  String get durationText => _formatDuration(_duration);
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  /// Initialize the audio service and set up listeners
  Future<void> _initializeService() async {
    try {
      debugPrint('🎵 Initializing MusicPlayerProvider...');

      // Initialize audio service
      if (!_audioService.isInitialized) {
        await _audioService.initialize();
      }

      // Set up stream listeners
      _setupStreamListeners();

      // Update initial state
      _playbackState = _mapPlayerState(_audioService.playerState);
      _position = _audioService.position;
      _duration = _audioService.duration;
      _isInitialized = true;

      debugPrint('✅ MusicPlayerProvider initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize MusicPlayerProvider: $e');
      _setError(
          AppError.audio('Failed to initialize audio player', e.toString()));
    }
  }

  /// Set up stream listeners for reactive updates
  void _setupStreamListeners() {
    _stateSubscription = _audioService.stateStream.listen(
      (PlayerState state) {
        _playbackState = _mapPlayerState(state);
        _clearError(); // Clear error on successful state change
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Player state stream error: $error');
        _setError(AppError.audio('Player state error', error.toString()));
      },
    );

    _positionSubscription = _audioService.positionStream.listen(
      (Duration position) {
        _position = position;

        // Throttle position updates to max once per 200ms to reduce UI redraws
        final now = DateTime.now();
        if (now.difference(_lastPositionUpdate).inMilliseconds >= 200) {
          _lastPositionUpdate = now;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('❌ Position stream error: $error');
      },
    );

    _durationSubscription = _audioService.durationStream.listen(
      (Duration duration) {
        _duration = duration;
        // Update current song with duration if available
        if (_currentSong != null && _currentSong!.duration == null) {
          _currentSong = _currentSong!.copyWith(duration: duration);
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Duration stream error: $error');
      },
    );

    _errorSubscription = _audioService.errorStream.listen(
      (String error) {
        _setError(AppError.audio('Audio playback error', error));
      },
    );
  }

  /// Play a song
  Future<void> playSong(Song song) async {
    try {
      debugPrint('🎵 Playing song: ${song.title} by ${song.artist}');

      // Set loading state temporarily until audio handler starts
      // This provides immediate UI feedback
      _playbackState = PlaybackState.loading;
      _currentSong = song;
      _clearError();
      notifyListeners();

      // Validate audio URL
      if (song.audioUrl.isEmpty || Uri.tryParse(song.audioUrl) == null) {
        throw Exception('Invalid audio URL for song: ${song.title}');
      }

      // Play the song using audio service with metadata for background playback
      final success = await _audioService.play(
        song.audioUrl,
        title: song.title,
        artist: song.artist,
        album: song.album,
        artworkUrl: song.imageUrl,
        songId: song.id,
      );

      if (!success) {
        throw Exception('Failed to start playback');
      }

      debugPrint('✅ Song playback started successfully');
      // Note: The actual playing state will be set by the stream listener
    } catch (e) {
      debugPrint('❌ Failed to play song: $e');
      _playbackState = PlaybackState.error;
      _setError(AppError.audio('Failed to play ${song.title}', e.toString()));
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      final success = await _audioService.pause();
      if (!success) {
        debugPrint('⚠️ Pause operation failed');
      }
    } catch (e) {
      debugPrint('❌ Failed to pause: $e');
      _setError(AppError.audio('Failed to pause playback', e.toString()));
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      final success = await _audioService.resume();
      if (!success) {
        debugPrint('⚠️ Resume operation failed');
      }
    } catch (e) {
      debugPrint('❌ Failed to resume: $e');
      _setError(AppError.audio('Failed to resume playback', e.toString()));
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      final success = await _audioService.stop();
      if (!success) {
        debugPrint('⚠️ Stop operation failed');
      }
      // Don't clear current song on stop, just reset position
      _position = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to stop: $e');
      _setError(AppError.audio('Failed to stop playback', e.toString()));
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      // Validate position
      if (position.isNegative || position > _duration) {
        debugPrint('⚠️ Invalid seek position: $position');
        return;
      }

      final success = await _audioService.seek(position);
      if (!success) {
        debugPrint('⚠️ Seek operation failed');
      }
    } catch (e) {
      debugPrint('❌ Failed to seek: $e');
      _setError(AppError.audio('Failed to seek to position', e.toString()));
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      volume = volume.clamp(0.0, 1.0);
      final success = await _audioService.setVolume(volume);

      if (success) {
        _volume = volume;
        _isMuted = volume == 0.0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Failed to set volume: $e');
      _setError(AppError.audio('Failed to adjust volume', e.toString()));
    }
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    if (_isMuted) {
      await setVolume(_volume > 0 ? _volume : 1.0);
    } else {
      await setVolume(0.0);
    }
  }

  /// Clear current song
  void clearCurrentSong() {
    _currentSong = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Set error
  void _setError(AppError error) {
    _error = error;
    _playbackState = PlaybackState.error;
    notifyListeners();
  }

  /// Map just_audio PlayerState to our PlaybackState
  PlaybackState _mapPlayerState(PlayerState playerState) {
    // just_audio PlayerState has: playing (bool) and processingState (ProcessingState enum)
    if (playerState.processingState == ProcessingState.loading ||
        playerState.processingState == ProcessingState.buffering) {
      return PlaybackState.loading;
    } else if (playerState.processingState == ProcessingState.completed) {
      return PlaybackState.completed;
    } else if (playerState.playing) {
      return PlaybackState.playing;
    } else if (playerState.processingState == ProcessingState.ready) {
      return PlaybackState.paused;
    } else {
      return PlaybackState.stopped;
    }
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else if (isPaused) {
      await resume();
    } else if (_currentSong != null) {
      await playSong(_currentSong!);
    }
  }

  /// Get current song info for UI
  Map<String, String> getCurrentSongInfo() {
    if (_currentSong == null) {
      return {
        'title': 'No song selected',
        'artist': '',
        'album': '',
        'imageUrl': '',
      };
    }

    return {
      'title': _currentSong!.title,
      'artist': _currentSong!.artist,
      'album': _currentSong!.album,
      'imageUrl': _currentSong!.imageUrl,
    };
  }

  /// Cleanup resources
  @override
  void dispose() {
    debugPrint('🧹 Disposing MusicPlayerProvider...');

    // Cancel stream subscriptions
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _errorSubscription?.cancel();

    // Note: Don't dispose AudioPlayerService as it's a singleton
    // It will be managed by the service itself

    super.dispose();
  }

  /// Debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'playbackState': _playbackState.toString(),
      'currentSong': _currentSong?.title ?? 'None',
      'position': positionText,
      'duration': durationText,
      'progress': progress,
      'volume': _volume,
      'isMuted': _isMuted,
      'hasError': _error != null,
      'error': _error?.toString(),
    };
  }
}
