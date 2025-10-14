import 'package:flutter/material.dart';
import 'package:Musify/models/app_models.dart';

/// AppStateProvider following industry standards for global app state management
/// Manages theme, settings, navigation state, and app-wide configurations
/// Uses Provider pattern with ChangeNotifier for reactive UI updates
class AppStateProvider extends ChangeNotifier {
  // Private fields
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isFirstLaunch = true;
  String _appVersion = '2.1.0';
  bool _isDeveloperMode = false;
  AppError? _globalError;
  bool _isNetworkAvailable = true;
  Map<String, dynamic> _userPreferences = {};

  // Audio quality preferences
  bool _preferHighQuality = true;
  bool _autoPlayNext = false;
  double _defaultVolume = 1.0;

  // Download preferences
  String _downloadQuality = '320'; // '96', '160', '320'
  bool _downloadOverWifiOnly = true;
  String _downloadPath = '';

  // UI preferences
  bool _showLyrics = true;
  bool _enableAnimations = true;
  Color _accentColor = const Color(0xff61e88a);

  /// Constructor
  AppStateProvider() {
    // Load preferences asynchronously to avoid blocking UI
    Future.microtask(() => _loadPreferences());
  }

  // Public getters
  ThemeMode get themeMode => _themeMode;
  bool get isFirstLaunch => _isFirstLaunch;
  String get appVersion => _appVersion;
  bool get isDeveloperMode => _isDeveloperMode;
  AppError? get globalError => _globalError;
  bool get isNetworkAvailable => _isNetworkAvailable;
  Map<String, dynamic> get userPreferences =>
      Map.unmodifiable(_userPreferences);

  // Audio preferences
  bool get preferHighQuality => _preferHighQuality;
  bool get autoPlayNext => _autoPlayNext;
  double get defaultVolume => _defaultVolume;

  // Download preferences
  String get downloadQuality => _downloadQuality;
  bool get downloadOverWifiOnly => _downloadOverWifiOnly;
  String get downloadPath => _downloadPath;

  // UI preferences
  bool get showLyrics => _showLyrics;
  bool get enableAnimations => _enableAnimations;
  Color get accentColor => _accentColor;

  // Computed properties
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get hasGlobalError => _globalError != null;
  String get downloadQualityDisplay => '${_downloadQuality}kbps';

  /// Load user preferences (in a real app, this would come from SharedPreferences)
  Future<void> _loadPreferences() async {
    try {
      debugPrint('📱 Loading user preferences...');

      // Simulate loading from persistent storage
      // In a real implementation, use SharedPreferences or secure storage
      // Reduced delay to 10ms to minimize startup blocking
      await Future.delayed(const Duration(milliseconds: 10));

      // Default preferences loaded
      debugPrint('✅ User preferences loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load preferences: $e');
      _setGlobalError(AppError(
        message: 'Failed to load user preferences',
        details: e.toString(),
      ));
    }
  }

  /// Save user preferences
  Future<void> _savePreferences() async {
    try {
      // In a real implementation, save to SharedPreferences
      await Future.delayed(Duration(milliseconds: 50));
      debugPrint('✅ User preferences saved');
    } catch (e) {
      debugPrint('❌ Failed to save preferences: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _savePreferences();
      notifyListeners();
      debugPrint('🎨 Theme mode changed to: $mode');
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Set first launch completed
  Future<void> setFirstLaunchCompleted() async {
    if (_isFirstLaunch) {
      _isFirstLaunch = false;
      await _savePreferences();
      notifyListeners();
      debugPrint('📱 First launch completed');
    }
  }

  /// Toggle developer mode
  Future<void> toggleDeveloperMode() async {
    _isDeveloperMode = !_isDeveloperMode;
    await _savePreferences();
    notifyListeners();
    debugPrint('🔧 Developer mode: $_isDeveloperMode');
  }

  /// Set network availability
  void setNetworkAvailability(bool isAvailable) {
    if (_isNetworkAvailable != isAvailable) {
      _isNetworkAvailable = isAvailable;
      notifyListeners();
      debugPrint('🌐 Network available: $isAvailable');
    }
  }

  /// Set global error
  void _setGlobalError(AppError error) {
    _globalError = error;
    notifyListeners();
    debugPrint('🚨 Global error set: ${error.message}');
  }

  /// Clear global error
  void clearGlobalError() {
    if (_globalError != null) {
      _globalError = null;
      notifyListeners();
      debugPrint('✅ Global error cleared');
    }
  }

  /// Audio preference setters
  Future<void> setPreferHighQuality(bool prefer) async {
    if (_preferHighQuality != prefer) {
      _preferHighQuality = prefer;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> setAutoPlayNext(bool autoPlay) async {
    if (_autoPlayNext != autoPlay) {
      _autoPlayNext = autoPlay;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> setDefaultVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);
    if (_defaultVolume != volume) {
      _defaultVolume = volume;
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Download preference setters
  Future<void> setDownloadQuality(String quality) async {
    if (['96', '160', '320'].contains(quality) && _downloadQuality != quality) {
      _downloadQuality = quality;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> setDownloadOverWifiOnly(bool wifiOnly) async {
    if (_downloadOverWifiOnly != wifiOnly) {
      _downloadOverWifiOnly = wifiOnly;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> setDownloadPath(String path) async {
    if (_downloadPath != path) {
      _downloadPath = path;
      await _savePreferences();
      notifyListeners();
    }
  }

  /// UI preference setters
  Future<void> setShowLyrics(bool show) async {
    if (_showLyrics != show) {
      _showLyrics = show;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> setEnableAnimations(bool enable) async {
    if (_enableAnimations != enable) {
      _enableAnimations = enable;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> setAccentColor(Color color) async {
    if (_accentColor != color) {
      _accentColor = color;
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Get user preference by key
  T? getUserPreference<T>(String key, [T? defaultValue]) {
    return _userPreferences[key] as T? ?? defaultValue;
  }

  /// Set user preference
  Future<void> setUserPreference<T>(String key, T value) async {
    _userPreferences[key] = value;
    await _savePreferences();
    notifyListeners();
  }

  /// Remove user preference
  Future<void> removeUserPreference(String key) async {
    if (_userPreferences.containsKey(key)) {
      _userPreferences.remove(key);
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.dark;
    _preferHighQuality = true;
    _autoPlayNext = false;
    _defaultVolume = 1.0;
    _downloadQuality = '320';
    _downloadOverWifiOnly = true;
    _downloadPath = '';
    _showLyrics = true;
    _enableAnimations = true;
    _accentColor = const Color(0xff61e88a);
    _userPreferences.clear();

    await _savePreferences();
    notifyListeners();
    debugPrint('🔄 Preferences reset to defaults');
  }

  /// Get theme data based on current settings
  ThemeData getLightThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: Brightness.light,
      ),
      fontFamily: "DMSans",
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  ThemeData getDarkThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: Brightness.dark,
      ),
      fontFamily: "DMSans",
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      canvasColor: Colors.transparent,
    );
  }

  /// Get app info
  Map<String, String> getAppInfo() {
    return {
      'version': _appVersion,
      'name': 'Musify',
      'description': 'Music Streaming and Downloading app made in Flutter!',
    };
  }

  /// Performance monitoring
  Map<String, dynamic> getPerformanceInfo() {
    return {
      'enableAnimations': _enableAnimations,
      'preferHighQuality': _preferHighQuality,
      'isDeveloperMode': _isDeveloperMode,
    };
  }

  /// Debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'themeMode': _themeMode.toString(),
      'isFirstLaunch': _isFirstLaunch,
      'appVersion': _appVersion,
      'isDeveloperMode': _isDeveloperMode,
      'isNetworkAvailable': _isNetworkAvailable,
      'preferHighQuality': _preferHighQuality,
      'autoPlayNext': _autoPlayNext,
      'downloadQuality': _downloadQuality,
      'downloadOverWifiOnly': _downloadOverWifiOnly,
      'showLyrics': _showLyrics,
      'enableAnimations': _enableAnimations,
      'accentColor': _accentColor.toString(),
      'hasGlobalError': _globalError != null,
      'globalError': _globalError?.toString(),
      'userPreferencesCount': _userPreferences.length,
    };
  }

  /// Cleanup resources
  @override
  void dispose() {
    debugPrint('🧹 Disposing AppStateProvider...');
    super.dispose();
  }
}
