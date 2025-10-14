import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import 'package:Musify/music.dart' as music;
import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/providers/search_provider.dart';
import 'package:Musify/models/app_models.dart';
import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/shared/widgets/widgets.dart';

// Modular imports
import 'package:Musify/features/home/home.dart';
import 'package:Musify/features/player/player.dart';
import 'package:Musify/features/download/download.dart';
import 'package:Musify/features/search/widgets/search_results_list.dart'
    as custom_search;

class Musify extends StatefulWidget {
  const Musify({super.key});

  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

class AppState extends State<Musify> {
  TextEditingController searchBar = TextEditingController();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.backgroundSecondary,
      statusBarColor: Colors.transparent,
    ));
  }

  @override
  void dispose() {
    searchBar.dispose();
    super.dispose();
  }

  // Search functionality
  Future<void> search() async {
    String searchQuery = searchBar.text;
    if (searchQuery.isEmpty) return;

    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    await searchProvider.searchSongs(searchQuery);
  }

  // Get song details and play
  Future<void> getSongDetails(String id, var context) async {
    try {
      debugPrint('🎵 getSongDetails called with ID: $id');

      final searchProvider =
          Provider.of<SearchProvider>(context, listen: false);
      final musicPlayer =
          Provider.of<MusicPlayerProvider>(context, listen: false);

      // Show loading indicator while fetching song details
      EasyLoading.show(status: 'Loading song...');

      // Get song details with audio URL
      Song? song = await searchProvider.searchAndPrepareSong(id);

      if (song == null) {
        throw Exception('Song not found or unable to get audio URL');
      }

      debugPrint('✅ Song details fetched successfully');

      // Dismiss loading before starting playback
      // The bottom player will show loading state during playback initialization
      EasyLoading.dismiss();
      debugPrint('✅ EasyLoading dismissed');

      // Set current song and start playing
      // DON'T await - let playback happen in background
      // The playSong method sets loading state immediately for UI feedback
      musicPlayer.playSong(song);

      debugPrint('🎵 Song playback initiated, navigating to player...');

      // Small delay to ensure EasyLoading is fully dismissed and playSong sets state
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to music player immediately
      // Don't wait for playback to start - the player screen will show loading state
      if (context.mounted) {
        debugPrint('🎵 Context mounted, pushing music player route...');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              debugPrint('🎵 Music player builder called');
              return const music.AudioApp();
            },
          ),
        ).then((value) {
          debugPrint('✅ Music player route completed/popped');
        });
        debugPrint('✅ Navigation push called');
      } else {
        debugPrint('⚠️ Context not mounted, skipping navigation');
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('Error getting song details: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load song: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Download functionality using the modular service
  Future<void> downloadSong(String id) async {
    await DownloadService.downloadSong(id);
  }

  // Load top songs (called automatically by SearchProvider constructor)
  Future<void> topSongs() async {
    // Top songs are loaded automatically when SearchProvider is initialized
    // This method is kept for compatibility but doesn't need to do anything
  }

  // Clear search
  void clearSearch() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.clearSearch();
    searchBar.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            bottomNavigationBar: const BottomPlayer(),
            body: Column(
              children: <Widget>[
                // Fixed header and search bar
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Home header with logo and settings
                      HomeHeader(
                        searchController: searchBar,
                        onClearSearch: clearSearch,
                      ),

                      // Search bar
                      SearchBarWidget(
                        controller: searchBar,
                        onSearch: search,
                      ),
                    ],
                  ),
                ),

                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Consumer<SearchProvider>(
                      builder: (context, searchProvider, child) {
                        // Show search results if there's a search query and results
                        if (searchProvider.showSearchResults) {
                          return custom_search.SearchResultsList(
                            onSongTap: getSongDetails,
                            onDownload: downloadSong,
                            onLongPress: topSongs,
                          );
                        }
                        // Show top songs if no search query
                        else if (searchProvider.showTopSongs) {
                          return TopSongsGrid(
                            onSongTap: getSongDetails,
                            onDownload: downloadSong,
                          );
                        }
                        // Show loading indicator when searching or loading top songs
                        else if (searchProvider.isSearching ||
                            searchProvider.isLoadingTopSongs) {
                          // Show skeleton grid for top songs loading
                          if (searchProvider.isLoadingTopSongs) {
                            return TopSongsGridSkeleton(itemCount: 6);
                          }
                          // Show search results skeleton for search
                          else {
                            return SearchResultsListSkeleton(itemCount: 5);
                          }
                        }
                        // Default empty state
                        else {
                          return Container(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.music_note,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Search for songs or browse top tracks',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
