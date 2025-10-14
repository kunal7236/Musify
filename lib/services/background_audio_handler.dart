import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// Background Audio Handler using audio_service
/// Enables background playback and lock screen media controls
/// Integrates with just_audio for audio playback
class MusifyAudioHandler extends BaseAudioHandler with SeekHandler {
  // Audio player instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State management
  MediaItem? _currentMediaItem;
  bool _isInitialized = false;

  // Stream subscriptions for cleanup
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  /// Constructor
  MusifyAudioHandler() {
    _init();
  }

  /// Initialize the audio handler
  Future<void> _init() async {
    try {
      debugPrint('🎵 Initializing MusifyAudioHandler...');

      // Set up stream listeners
      _setupAudioPlayerListeners();

      _isInitialized = true;
      debugPrint('✅ MusifyAudioHandler initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize MusifyAudioHandler: $e');
    }
  }

  /// Set up audio player stream listeners
  void _setupAudioPlayerListeners() {
    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (playerState) {
        _updatePlaybackState(playerState);
      },
      onError: (error) {
        debugPrint('❌ Player state stream error: $error');
        _broadcastError(error.toString());
      },
    );

    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen(
      (position) {
        // Don't update position if song is completed
        if (_audioPlayer.processingState != ProcessingState.completed) {
          playbackState.add(playbackState.value.copyWith(
            updatePosition: position,
          ));
        }
      },
      onError: (error) {
        debugPrint('❌ Position stream error: $error');
      },
    );

    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen(
      (duration) {
        if (duration != null && _currentMediaItem != null) {
          // Update media item with actual duration
          mediaItem.add(_currentMediaItem!.copyWith(duration: duration));
        }
      },
      onError: (error) {
        debugPrint('❌ Duration stream error: $error');
      },
    );
  }

  /// Update playback state based on player state
  void _updatePlaybackState(PlayerState playerState) {
    final processingState = _mapProcessingState(playerState.processingState);
    final playing = playerState.playing;

    // When song completes, set position to duration to stop slider movement
    final position = playerState.processingState == ProcessingState.completed
        ? (_audioPlayer.duration ?? _audioPlayer.position)
        : _audioPlayer.position;

    playbackState.add(
      PlaybackState(
        controls: _getControls(playing, playerState.processingState),
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: processingState,
        playing: playing,
        updatePosition: position,
        bufferedPosition: _audioPlayer.bufferedPosition,
        speed: _audioPlayer.speed,
      ),
    );
  }

  /// Map just_audio ProcessingState to audio_service AudioProcessingState
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        return AudioProcessingState.idle;
    }
  }

  /// Get media controls based on current state
  List<MediaControl> _getControls(
      bool playing, ProcessingState processingState) {
    // When song completes, show play button (not pause)
    final isCompleted = processingState == ProcessingState.completed;

    return [
      const MediaControl(
        androidIcon: 'drawable/ic_action_skip_previous',
        label: 'Previous',
        action: MediaAction.skipToPrevious,
      ),
      if (playing && !isCompleted)
        const MediaControl(
          androidIcon: 'drawable/ic_action_pause',
          label: 'Pause',
          action: MediaAction.pause,
        )
      else
        const MediaControl(
          androidIcon: 'drawable/ic_action_play_arrow',
          label: 'Play',
          action: MediaAction.play,
        ),
      const MediaControl(
        androidIcon: 'drawable/ic_action_skip_next',
        label: 'Next',
        action: MediaAction.skipToNext,
      ),
      const MediaControl(
        androidIcon: 'drawable/ic_action_stop',
        label: 'Stop',
        action: MediaAction.stop,
      ),
    ];
  }

  /// Broadcast error to UI
  void _broadcastError(String error) {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: error,
      ),
    );
  }

  // ========== Audio Service API Implementation ==========

  @override
  Future<void> play() async {
    try {
      debugPrint('▶️ Play command received');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('❌ Play failed: $e');
      _broadcastError('Failed to play: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      debugPrint('⏸️ Pause command received');
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('❌ Pause failed: $e');
      _broadcastError('Failed to pause: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      debugPrint('⏹️ Stop command received');
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);

      // Update playback state to stopped
      playbackState.add(
        PlaybackState(
          controls: _getControls(false, ProcessingState.idle),
          processingState: AudioProcessingState.idle,
          playing: false,
        ),
      );
    } catch (e) {
      debugPrint('❌ Stop failed: $e');
      _broadcastError('Failed to stop: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      debugPrint('🎯 Seek to: $position');
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('❌ Seek failed: $e');
      _broadcastError('Failed to seek: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('⏭️ Skip to next (not implemented yet)');
    // TODO: Implement playlist functionality
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('⏮️ Skip to previous (not implemented yet)');
    // TODO: Implement playlist functionality
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      debugPrint('🏃 Set speed to: $speed');
      await _audioPlayer.setSpeed(speed);
    } catch (e) {
      debugPrint('❌ Set speed failed: $e');
      _broadcastError('Failed to set speed: $e');
    }
  }

  /// Custom method: Play from URL with media item information
  Future<void> playFromUrl(String url, MediaItem item) async {
    try {
      debugPrint('🎵 Playing from URL: $url');
      debugPrint('📀 Media: ${item.title} by ${item.artist}');

      // Update current media item
      _currentMediaItem = item;
      mediaItem.add(item);

      // Set audio source and play
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      debugPrint('✅ Playback started successfully');
    } catch (e) {
      debugPrint('❌ Failed to play from URL: $e');
      _broadcastError('Failed to play: $e');
      rethrow;
    }
  }

  /// Custom method: Set volume
  Future<void> setVolume(double volume) async {
    try {
      volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(volume);
      debugPrint('🔊 Volume set to: $volume');
    } catch (e) {
      debugPrint('❌ Set volume failed: $e');
    }
  }

  /// Get current position
  Duration get position => _audioPlayer.position;

  /// Get current duration
  Duration? get duration => _audioPlayer.duration;

  /// Get audio player instance (for advanced use cases)
  AudioPlayer get audioPlayer => _audioPlayer;

  /// Check if handler is initialized
  bool get isInitialized => _isInitialized;

  /// Cleanup resources
  Future<void> dispose() async {
    try {
      debugPrint('🧹 Disposing MusifyAudioHandler...');

      // Cancel subscriptions
      await _playerStateSubscription?.cancel();
      await _positionSubscription?.cancel();
      await _durationSubscription?.cancel();

      // Stop and dispose audio player
      await _audioPlayer.stop();
      await _audioPlayer.dispose();

      _isInitialized = false;
      debugPrint('✅ MusifyAudioHandler disposed');
    } catch (e) {
      debugPrint('❌ Error disposing MusifyAudioHandler: $e');
    }
  }
}

/// Helper function to create MediaItem from Song
MediaItem createMediaItem({
  required String id,
  required String title,
  required String artist,
  required String album,
  String? artUri,
  Duration? duration,
}) {
  return MediaItem(
    id: id,
    title: title,
    artist: artist,
    album: album,
    artUri: artUri != null && artUri.isNotEmpty ? Uri.parse(artUri) : null,
    duration: duration,
    playable: true,
  );
}
