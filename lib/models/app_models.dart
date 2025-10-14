/// Data models for type-safe state management
/// Following industry standards for immutable data structures

import 'package:flutter/foundation.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String imageUrl;
  final String audioUrl;
  final String albumId;
  final bool hasLyrics;
  final String lyrics;
  final bool has320Quality;
  final Duration? duration;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.imageUrl,
    required this.audioUrl,
    this.albumId = '',
    this.hasLyrics = false,
    this.lyrics = '',
    this.has320Quality = false,
    this.duration,
  });

  /// Create Song from API response data
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: _formatString(json['title'] ?? 'Unknown'),
      artist: _formatString(json['singers'] ?? 'Unknown Artist'),
      album: _formatString(json['album'] ?? 'Unknown Album'),
      imageUrl: _enhanceImageQuality(json['image'] ?? ''),
      audioUrl: '', // Will be set after decryption
      hasLyrics: json['has_lyrics'] == 'true',
      lyrics: json['lyrics'] ?? '',
      has320Quality: json['320kbps'] == 'true',
    );
  }

  /// Create Song from search result
  factory Song.fromSearchResult(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: _formatString(json['title'] ?? 'Unknown'),
      artist: _formatString(json['more_info']?['singers'] ?? 'Unknown Artist'),
      album: _formatString(json['album'] ?? 'Unknown Album'),
      imageUrl: _enhanceImageQuality(json['image'] ?? ''),
      audioUrl: '', // Will be set after fetching details
      hasLyrics: false, // Will be updated after fetching details
      lyrics: '',
      has320Quality: false, // Will be updated after fetching details
    );
  }

  /// Create Song from top songs list
  factory Song.fromTopSong(Map<String, dynamic> json) {
    final artistName = json['more_info']?['artistMap']?['primary_artists']?[0]
            ?['name'] ??
        'Unknown Artist';

    return Song(
      id: json['id'] ?? '',
      title: _formatString(json['title'] ?? 'Unknown'),
      artist: _formatString(artistName),
      album: _formatString(json['album'] ?? 'Unknown Album'),
      imageUrl: _enhanceImageQuality(json['image'] ?? ''),
      audioUrl: '', // Will be set after fetching details
      hasLyrics: false,
      lyrics: '',
      has320Quality: false,
    );
  }

  /// Create a copy of Song with updated fields
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? imageUrl,
    String? audioUrl,
    String? albumId,
    bool? hasLyrics,
    String? lyrics,
    bool? has320Quality,
    Duration? duration,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      albumId: albumId ?? this.albumId,
      hasLyrics: hasLyrics ?? this.hasLyrics,
      lyrics: lyrics ?? this.lyrics,
      has320Quality: has320Quality ?? this.has320Quality,
      duration: duration ?? this.duration,
    );
  }

  /// Helper method to format strings (same as in saavn.dart)
  static String _formatString(String input) {
    return input
        .replaceAll("&quot;", "'")
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'");
  }

  /// Enhance image quality by replacing size parameters with highest quality
  static String _enhanceImageQuality(String imageUrl) {
    if (imageUrl.isEmpty) return imageUrl;

    final originalUrl = imageUrl;

    // Try different resolution patterns for maximum quality
    final enhancedUrl = imageUrl
        .replaceAll('150x150', '500x500')
        .replaceAll('50x50', '500x500')
        .replaceAll('200x200', '500x500')
        .replaceAll('250x250', '500x500')
        .replaceAll('300x300', '500x500');

    // Debug logging to track URL transformations
    if (enhancedUrl != originalUrl) {
      debugPrint('🖼️ Image quality enhanced:');
      debugPrint('   Original: $originalUrl');
      debugPrint('   Enhanced: $enhancedUrl');
    }

    return enhancedUrl;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Song{id: $id, title: $title, artist: $artist}';
  }
}

/// Enum for player states
enum PlaybackState {
  stopped,
  loading,
  playing,
  paused,
  error,
  completed,
}

/// Enum for app states
enum AppLoadingState {
  idle,
  loading,
  success,
  error,
}

/// Error class for better error handling
class AppError {
  final String message;
  final String? details;
  final ErrorType type;

  const AppError({
    required this.message,
    this.details,
    this.type = ErrorType.unknown,
  });

  factory AppError.network(String message, [String? details]) {
    return AppError(
      message: message,
      details: details,
      type: ErrorType.network,
    );
  }

  factory AppError.audio(String message, [String? details]) {
    return AppError(
      message: message,
      details: details,
      type: ErrorType.audio,
    );
  }

  factory AppError.permission(String message, [String? details]) {
    return AppError(
      message: message,
      details: details,
      type: ErrorType.permission,
    );
  }

  @override
  String toString() => message;
}

enum ErrorType {
  network,
  audio,
  permission,
  storage,
  unknown,
}
