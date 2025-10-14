import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:Musify/models/app_models.dart';
import 'package:Musify/API/saavn.dart' as saavn_api;

/// Helper function to parse search results in background isolate
List<Song> _parseSearchResults(List<dynamic> rawResults) {
  return rawResults
      .map((json) => Song.fromSearchResult(json as Map<String, dynamic>))
      .toList();
}

/// Helper function to parse top songs in background isolate
List<Song> _parseTopSongs(List<dynamic> rawSongs) {
  return rawSongs
      .map((json) => Song.fromTopSong(json as Map<String, dynamic>))
      .toList();
}

/// SearchProvider following industry standards for state management
/// Manages search state, results, loading states, and top songs
/// Uses Provider pattern with ChangeNotifier for reactive UI updates
class SearchProvider extends ChangeNotifier {
  // Private fields
  List<Song> _searchResults = [];
  List<Song> _topSongs = [];
  String _searchQuery = '';
  AppLoadingState _searchLoadingState = AppLoadingState.idle;
  AppLoadingState _topSongsLoadingState = AppLoadingState.idle;
  AppError? _searchError;
  AppError? _topSongsError;
  Timer? _searchDebounceTimer;

  // Search configuration
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);
  static const int _maxSearchResults = 50;

  /// Constructor
  SearchProvider() {
    // Delay top songs loading to avoid blocking UI during app startup
    // Use 2 second delay to let the UI fully render and settle
    Future.delayed(const Duration(milliseconds: 2000), () {
      _loadTopSongs();
    });
  }

  // Public getters
  List<Song> get searchResults => List.unmodifiable(_searchResults);
  List<Song> get topSongs => List.unmodifiable(_topSongs);
  String get searchQuery => _searchQuery;
  AppLoadingState get searchLoadingState => _searchLoadingState;
  AppLoadingState get topSongsLoadingState => _topSongsLoadingState;
  AppError? get searchError => _searchError;
  AppError? get topSongsError => _topSongsError;

  // Computed properties
  bool get isSearching => _searchLoadingState == AppLoadingState.loading;
  bool get isLoadingTopSongs =>
      _topSongsLoadingState == AppLoadingState.loading;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get hasTopSongs => _topSongs.isNotEmpty;
  bool get hasSearchError => _searchError != null;
  bool get hasTopSongsError => _topSongsError != null;
  bool get showSearchResults => _searchQuery.isNotEmpty && hasSearchResults;
  bool get showTopSongs => _searchQuery.isEmpty && hasTopSongs;

  /// Search for songs with debouncing
  Future<void> searchSongs(String query) async {
    // Cancel previous search timer
    _searchDebounceTimer?.cancel();

    // Update query immediately for UI
    _searchQuery = query.trim();

    // Clear results if query is empty
    if (_searchQuery.isEmpty) {
      _clearSearchResults();
      return;
    }

    // Set loading state immediately
    _searchLoadingState = AppLoadingState.loading;
    _clearSearchError();
    notifyListeners();

    // Debounce search requests
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      _performSearch(_searchQuery);
    });
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    try {
      debugPrint('🔍 Searching for: $query');

      // Call the existing API function
      List<dynamic> rawResults = await saavn_api.fetchSongsList(query);

      // Parse JSON in background isolate to avoid blocking UI
      List<Song> songs = await compute(
        _parseSearchResults,
        rawResults.take(_maxSearchResults).toList(),
      );

      // Update state
      _searchResults = songs;
      _searchLoadingState = AppLoadingState.success;
      _clearSearchError();

      debugPrint('✅ Search completed: ${songs.length} results');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Search failed: $e');
      _searchLoadingState = AppLoadingState.error;
      _setSearchError(AppError.network('Search failed', e.toString()));
    }
  }

  /// Load top songs
  Future<void> _loadTopSongs() async {
    try {
      debugPrint('🎵 Loading top songs...');

      _topSongsLoadingState = AppLoadingState.loading;
      _clearTopSongsError();
      notifyListeners();

      // Call the existing API function
      List<dynamic> rawTopSongs = await saavn_api.topSongs();

      // Parse JSON in background isolate to avoid blocking UI
      List<Song> songs = await compute(_parseTopSongs, rawTopSongs);

      // Update state
      _topSongs = songs;
      _topSongsLoadingState = AppLoadingState.success;
      _clearTopSongsError();

      debugPrint('✅ Top songs loaded: ${songs.length} songs');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load top songs: $e');
      _topSongsLoadingState = AppLoadingState.error;
      _setTopSongsError(
          AppError.network('Failed to load top songs', e.toString()));
    }
  }

  /// Refresh top songs (pull to refresh)
  Future<void> refreshTopSongs() async {
    await _loadTopSongs();
  }

  /// Clear search results
  void clearSearch() {
    _searchQuery = '';
    _clearSearchResults();
  }

  /// Clear search results (private)
  void _clearSearchResults() {
    _searchResults = [];
    _searchLoadingState = AppLoadingState.idle;
    _clearSearchError();
    notifyListeners();
  }

  /// Get song details (for playing)
  Future<Song?> getSongDetails(Song song) async {
    try {
      debugPrint('🎵 Getting details for song: ${song.title}');

      // Call the existing API function to get full song details
      bool success = await saavn_api.fetchSongDetails(song.id);

      if (!success) {
        throw Exception('Failed to fetch song details');
      }

      // Create updated song with audio URL from global variables
      // Note: This uses the existing global variables temporarily
      // until we fully refactor the API layer
      Song updatedSong = song.copyWith(
        audioUrl: saavn_api.kUrl,
        albumId: saavn_api.albumId,
        lyrics: saavn_api.lyrics,
        hasLyrics: saavn_api.has_lyrics == 'true',
        has320Quality: saavn_api.has_320 == 'true',
      );

      debugPrint('✅ Song details obtained: ${updatedSong.audioUrl}');
      return updatedSong;
    } catch (e) {
      debugPrint('❌ Failed to get song details: $e');
      return null;
    }
  }

  /// Search and get song ready for playing
  Future<Song?> searchAndPrepareSong(String songId) async {
    // Find song in current results
    Song? song = _findSongById(songId);

    if (song == null) {
      debugPrint('⚠️ Song not found in current results: $songId');
      return null;
    }

    // Get full details with audio URL
    return await getSongDetails(song);
  }

  /// Find song by ID in current results
  Song? _findSongById(String songId) {
    // Search in search results first
    for (Song song in _searchResults) {
      if (song.id == songId) {
        return song;
      }
    }

    // Search in top songs
    for (Song song in _topSongs) {
      if (song.id == songId) {
        return song;
      }
    }

    return null;
  }

  /// Get filtered search results
  List<Song> getFilteredResults({String? artistFilter, String? albumFilter}) {
    List<Song> results = _searchResults;

    if (artistFilter != null && artistFilter.isNotEmpty) {
      results = results
          .where((song) =>
              song.artist.toLowerCase().contains(artistFilter.toLowerCase()))
          .toList();
    }

    if (albumFilter != null && albumFilter.isNotEmpty) {
      results = results
          .where((song) =>
              song.album.toLowerCase().contains(albumFilter.toLowerCase()))
          .toList();
    }

    return results;
  }

  /// Get search suggestions (based on current results)
  List<String> getSearchSuggestions() {
    Set<String> suggestions = {};

    // Add artist names
    for (Song song in _searchResults) {
      suggestions.add(song.artist);
    }

    // Add album names
    for (Song song in _searchResults) {
      if (song.album.isNotEmpty && song.album != 'Unknown Album') {
        suggestions.add(song.album);
      }
    }

    return suggestions.take(10).toList();
  }

  /// Clear search error
  void _clearSearchError() {
    if (_searchError != null) {
      _searchError = null;
      notifyListeners();
    }
  }

  /// Set search error
  void _setSearchError(AppError error) {
    _searchError = error;
    notifyListeners();
  }

  /// Clear top songs error
  void _clearTopSongsError() {
    if (_topSongsError != null) {
      _topSongsError = null;
      notifyListeners();
    }
  }

  /// Set top songs error
  void _setTopSongsError(AppError error) {
    _topSongsError = error;
    notifyListeners();
  }

  /// Retry failed operations
  Future<void> retrySearch() async {
    if (_searchQuery.isNotEmpty) {
      await _performSearch(_searchQuery);
    }
  }

  Future<void> retryTopSongs() async {
    await _loadTopSongs();
  }

  /// Update search query without triggering search (for UI)
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Get popular artists from top songs
  List<String> getPopularArtists() {
    Set<String> artists = {};
    for (Song song in _topSongs) {
      if (song.artist.isNotEmpty && song.artist != 'Unknown Artist') {
        artists.add(song.artist);
      }
    }
    return artists.take(10).toList();
  }

  /// Cleanup resources
  @override
  void dispose() {
    debugPrint('🧹 Disposing SearchProvider...');
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// Debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'searchQuery': _searchQuery,
      'searchResultsCount': _searchResults.length,
      'topSongsCount': _topSongs.length,
      'searchLoadingState': _searchLoadingState.toString(),
      'topSongsLoadingState': _topSongsLoadingState.toString(),
      'hasSearchError': _searchError != null,
      'hasTopSongsError': _topSongsError != null,
      'searchError': _searchError?.toString(),
      'topSongsError': _topSongsError?.toString(),
    };
  }
}
