/// Application-wide constants
/// Centralizes magic numbers, strings, and configuration values
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Metadata
  static const String appName = 'Musify';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);
  static const int maxSearchResults = 50;
  static const int maxTopSongs = 20;

  // UI Constants
  static const double defaultPadding = 12.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 20.0;
  static const double borderRadius = 8.0;
  static const double buttonBorderRadius = 18.0;
  static const double cardBorderRadius = 10.0;

  // Player Configuration
  static const double playerControlSize = 40.0;
  static const double albumArtSize = 350.0;
  static const double miniPlayerHeight = 75.0;
  static const double progressBarHeight = 4.0;

  // Image Configuration
  static const double thumbnailSize = 60.0;
  static const int imageCacheWidth = 500;
  static const int imageCacheHeight = 500;
  static const int thumbnailCacheSize = 150;

  // Audio Configuration
  static const double defaultVolume = 1.0;
  static const double volumeStep = 0.1;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Error Messages
  static const String noInternetError = 'No internet connection';
  static const String songLoadError = 'Failed to load song';
  static const String searchError = 'Search failed';
  static const String permissionError = 'Permission denied';

  // Success Messages
  static const String downloadSuccess = 'Downloaded successfully';
  static const String songAddedSuccess = 'Song added to playlist';

  // File Paths
  static const String downloadFolderName = 'Musify';
  static const String cacheFileName = 'musify_cache';

  // Feature Flags
  static const bool enableLyrics = true;
  static const bool enableDownload = true;
  static const bool enableNotifications = true;
  static const bool enableAnalytics = false;
}
