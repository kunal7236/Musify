import 'dart:io';

// import 'package:audiotagger/audiotagger.dart';  // Removed due to compatibility issues
// import 'package:audiotagger/models/tag.dart';   // Removed due to compatibility issues
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:gradient_widgets/gradient_widgets.dart';  // Temporarily disabled
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Musify/API/saavn.dart';
import 'package:Musify/music.dart' as music;
import 'package:Musify/providers/music_player_provider.dart';
import 'package:Musify/providers/search_provider.dart';
import 'package:Musify/models/app_models.dart';
import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/shared/widgets/app_widgets.dart';
import 'package:Musify/ui/aboutPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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

  search() async {
    String searchQuery = searchBar.text;
    if (searchQuery.isEmpty) return;

    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    await searchProvider.searchSongs(searchQuery);
  }

  getSongDetails(String id, var context) async {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final musicPlayer =
        Provider.of<MusicPlayerProvider>(context, listen: false);

    // Show loading indicator
    EasyLoading.show(status: 'Loading song...');

    try {
      // Get song details with audio URL
      Song? song = await searchProvider.searchAndPrepareSong(id);

      if (song == null) {
        EasyLoading.dismiss();
        throw Exception('Failed to load song details');
      }

      // Set the song in music player
      await musicPlayer.playSong(song);

      EasyLoading.dismiss();

      // Navigate to music player
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RepaintBoundary(
            child: const music.AudioApp(),
          ),
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('Error loading song: $e');

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading song: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  downloadSong(id) async {
    String? filepath;
    String? filepath2;

    // Check Android version and request appropriate permissions
    bool permissionGranted = false;

    try {
      // For Android 13+ (API 33+), use media permissions
      if (await Permission.audio.isDenied) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.audio,
          // Permission.manageExternalStorage,
          Permission.storage,
        ].request();

        permissionGranted = statuses[Permission.audio]?.isGranted == true ||
            // statuses[Permission.manageExternalStorage]?.isGranted == true ||
            statuses[Permission.storage]?.isGranted == true;
      } else {
        permissionGranted = await Permission.audio.isGranted ||
            // await Permission.manageExternalStorage.isGranted ||
            await Permission.storage.isGranted;
      }

      // Try to get MANAGE_EXTERNAL_STORAGE for Android 11+ for full access
      if (!permissionGranted && Platform.isAndroid) {
        var manageStorageStatus =
            await Permission.manageExternalStorage.request();
        permissionGranted = manageStorageStatus.isGranted;
      }
    } catch (e) {
      debugPrint('Permission error: $e');
      // Fallback to storage permission
      var storageStatus = await Permission.storage.request();
      permissionGranted = storageStatus.isGranted;
    }

    if (!permissionGranted) {
      Fluttertoast.showToast(
          msg:
              "Storage Permission Required!\nPlease grant storage access to download songs",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 14.0);
      return;
    }

    // Proceed with download
    await fetchSongDetails(id);
    EasyLoading.show(status: 'Downloading $title...');

    try {
      final filename =
          title.replaceAll(RegExp(r'[^\w\s-]'), '').trim() + ".m4a";
      final artname =
          title.replaceAll(RegExp(r'[^\w\s-]'), '').trim() + "_artwork.jpg";

      // Use multiple fallback strategies for file storage
      Directory? musicDir;
      String dlPath;
      String locationDescription;

      if (Platform.isAndroid) {
        // Strategy 1: Try Downloads/Musify directory (most reliable)
        try {
          musicDir = Directory('/storage/emulated/0/Download/Musify');
          if (!await musicDir.exists()) {
            await musicDir.create(recursive: true);
          }
          // Test write access
          final testFile = File('${musicDir.path}/.test');
          await testFile.writeAsString('test');
          await testFile.delete();

          dlPath = musicDir.path;
          locationDescription = "Downloads/Musify folder";
          debugPrint('? Using Downloads/Musify directory: $dlPath');
        } catch (e) {
          debugPrint('? Downloads directory failed: $e');

          // Strategy 2: Try app-specific external directory
          try {
            musicDir = await getExternalStorageDirectory();
            if (musicDir != null) {
              dlPath = "${musicDir.path}/Music";
              await Directory(dlPath).create(recursive: true);
              locationDescription = "App Music folder";
              debugPrint('? Using app-specific directory: $dlPath');
            } else {
              throw Exception('External storage not available');
            }
          } catch (e2) {
            debugPrint('? App-specific directory failed: $e2');

            // Strategy 3: Use internal app directory
            musicDir = await getApplicationDocumentsDirectory();
            dlPath = "${musicDir.path}/Music";
            await Directory(dlPath).create(recursive: true);
            locationDescription = "App Documents folder";
            debugPrint('? Using internal app directory: $dlPath');
          }
        }
      } else {
        // Fallback for other platforms
        musicDir = await getApplicationDocumentsDirectory();
        dlPath = "${musicDir.path}/Music";
        await Directory(dlPath).create(recursive: true);
        locationDescription = "Documents/Music folder";
      }

      filepath = "$dlPath/$filename";
      filepath2 = "$dlPath/$artname";

      debugPrint('Audio path: $filepath');
      debugPrint('Image path: $filepath2');

      // Check if file already exists
      if (await File(filepath).exists()) {
        Fluttertoast.showToast(
            msg: "File already exists!\n$filename",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 14.0);
        EasyLoading.dismiss();
        return;
      }

      // Get the proper audio URL
      String audioUrl = kUrl;
      if (has_320 == "true") {
        audioUrl = rawkUrl.replaceAll("_96.mp4", "_320.mp4");
        final client = http.Client();
        final request = http.Request('HEAD', Uri.parse(audioUrl))
          ..followRedirects = false;
        final response = await client.send(request);
        debugPrint('Response status: ${response.statusCode}');
        audioUrl = (response.headers['location']) ?? audioUrl;
        debugPrint('Raw URL: $rawkUrl');
        debugPrint('Final URL: $audioUrl');

        final request2 = http.Request('HEAD', Uri.parse(audioUrl))
          ..followRedirects = false;
        final response2 = await client.send(request2);
        if (response2.statusCode != 200) {
          audioUrl = audioUrl.replaceAll(".mp4", ".mp3");
        }
        client.close();
      }

      // Download audio file
      debugPrint('?? Starting audio download...');
      var request = await HttpClient().getUrl(Uri.parse(audioUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      File file = File(filepath);
      await file.writeAsBytes(bytes);
      debugPrint('? Audio file saved successfully');

      // Download image file
      debugPrint('??? Starting image download...');
      var request2 = await HttpClient().getUrl(Uri.parse(image));
      var response2 = await request2.close();
      var bytes2 = await consolidateHttpClientResponseBytes(response2);
      File file2 = File(filepath2);
      await file2.writeAsBytes(bytes2);
      debugPrint('? Image file saved successfully');

      debugPrint("??? Starting tag editing");

      // Add metadata tags
      final tag = Tag(
        title: title,
        trackArtist: artist,
        pictures: [
          Picture(
            bytes: Uint8List.fromList(bytes2),
            mimeType: MimeType.jpeg,
            pictureType: PictureType.coverFront,
          ),
        ],
        album: album,
        lyrics: lyrics,
      );

      debugPrint("Setting up Tags");
      try {
        await AudioTags.write(filepath, tag);
        debugPrint("? Tags written successfully");
      } catch (e) {
        debugPrint("?? Error writing tags: $e");
        // Continue even if tagging fails
      }

      // Clean up temporary image file
      try {
        if (await file2.exists()) {
          await file2.delete();
          debugPrint('??? Temporary image file cleaned up');
        }
      } catch (e) {
        debugPrint('?? Could not clean up temp file: $e');
      }

      EasyLoading.dismiss();
      debugPrint("?? Download completed successfully");

      // Show success message with accessible location
      Fluttertoast.showToast(
          msg:
              "? Download Complete!\n?? Saved to: $locationDescription\n?? $filename",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 4,
          backgroundColor: Colors.green[800],
          textColor: Colors.white,
          fontSize: 14.0);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("? Download error: $e");

      Fluttertoast.showToast(
          msg:
              "? Download Failed!\n${e.toString().contains('Permission') ? 'Storage permission denied' : 'Error: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e}'}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 14.0);
    }
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
            //backgroundColor: Color(0xff384850),
            bottomNavigationBar: Consumer<MusicPlayerProvider>(
              builder: (context, musicPlayer, child) {
                return musicPlayer.currentSong != null
                    ? RepaintBoundary(
                        child: Container(
                          height: 75,
                          //color: Color(0xff1c252a),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18)),
                              color: AppColors.backgroundSecondary,
                              border: Border(
                                top: BorderSide(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.3),
                                  width: 1.0,
                                ),
                              )),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RepaintBoundary(
                                            child: const music.AudioApp(),
                                          )),
                                );
                              },
                              child: Row(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8.0,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        MdiIcons.appleKeyboardControl,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  RepaintBoundary(
                                                    child:
                                                        const music.AudioApp(),
                                                  )),
                                        );
                                      },
                                      disabledColor: AppColors.accent,
                                    ),
                                  ),
                                  Container(
                                    width: 60,
                                    height: 60,
                                    padding: const EdgeInsets.only(
                                        left: 0.0,
                                        top: 7,
                                        bottom: 7,
                                        right: 15),
                                    child: AppImageWidgets.albumArt(
                                      imageUrl:
                                          musicPlayer.currentSong?.imageUrl ??
                                              '',
                                      width: 60,
                                      height: 60,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 0.0, left: 8.0, right: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            musicPlayer.currentSong?.title ??
                                                'Unknown',
                                            style: TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            musicPlayer.currentSong?.artist ??
                                                'Unknown Artist',
                                            style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Consumer<MusicPlayerProvider>(
                                    builder: (context, musicPlayer, child) {
                                      return IconButton(
                                        icon: musicPlayer.playbackState ==
                                                PlaybackState.playing
                                            ? Icon(MdiIcons.pause)
                                            : Icon(MdiIcons.playOutline),
                                        color: AppColors.accent,
                                        splashColor: Colors.transparent,
                                        onPressed: () async {
                                          try {
                                            if (musicPlayer.playbackState ==
                                                PlaybackState.playing) {
                                              await musicPlayer.pause();
                                            } else if (musicPlayer
                                                    .playbackState ==
                                                PlaybackState.paused) {
                                              await musicPlayer.resume();
                                            } else if (musicPlayer
                                                    .currentSong !=
                                                null) {
                                              await musicPlayer.playSong(
                                                  musicPlayer.currentSong!);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content:
                                                      Text('No song selected'),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            debugPrint(
                                                '? Audio control error: $e');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('Audio error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        iconSize: 45,
                                      );
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(12.0),
              child: Column(
                children: <Widget>[
                  Padding(padding: EdgeInsets.only(top: 30, bottom: 20.0)),
                  Center(
                    child: Row(children: <Widget>[
                      // Back button when showing search results
                      if (searchProvider.showSearchResults)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 16.0, right: 8.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: AppColors.accent,
                              size: 28,
                            ),
                            onPressed: () {
                              searchProvider.clearSearch();
                              searchBar.clear();
                            },
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: searchProvider.showSearchResults ? 0.0 : 42.0,
                          ),
                          child: Center(
                            child: GradientText(
                              "Musify.",
                              shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
                              gradient: AppColors.buttonGradient,
                              style: TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Expanded(
                      //   child: Padding(
                      //     padding: const EdgeInsets.only(left: 42.0),
                      //     child: Center(
                      //       child: Text(
                      //         "Musify.",
                      //         style: TextStyle(
                      //           fontSize: 35,
                      //           fontWeight: FontWeight.w800,
                      //           color: AppColors.accent,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        child: IconButton(
                          iconSize: 26,
                          alignment: Alignment.center,
                          icon: Icon(MdiIcons.dotsVertical),
                          color: AppColors.accent,
                          onPressed: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutPage(),
                              ),
                            ),
                          },
                        ),
                      )
                    ]),
                  ),
                  Padding(padding: EdgeInsets.only(top: 20)),
                  TextField(
                    onSubmitted: (String value) {
                      search();
                    },
                    controller: searchBar,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.accent,
                    ),
                    cursorColor: Colors.green[50],
                    decoration: InputDecoration(
                      fillColor: AppColors.backgroundSecondary,
                      filled: true,
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(100),
                        ),
                        borderSide: BorderSide(
                          color: AppColors.backgroundSecondary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(100),
                        ),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                      suffixIcon: Consumer<SearchProvider>(
                        builder: (context, searchProvider, child) {
                          return IconButton(
                            icon: searchProvider.isSearching
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.accent),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.search,
                                    color: AppColors.accent,
                                  ),
                            color: AppColors.accent,
                            onPressed: () {
                              search();
                            },
                          );
                        },
                      ),
                      border: InputBorder.none,
                      hintText: "Search...",
                      hintStyle: TextStyle(
                        color: AppColors.accent,
                      ),
                      contentPadding: const EdgeInsets.only(
                        left: 18,
                        right: 20,
                        top: 14,
                        bottom: 14,
                      ),
                    ),
                  ),
                  Consumer<SearchProvider>(
                    builder: (context, searchProvider, child) {
                      // Show search results if there's a search query and results
                      if (searchProvider.showSearchResults) {
                        return RepaintBoundary(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: searchProvider.searchResults.length,
                            itemBuilder: (BuildContext ctxt, int index) {
                              final song = searchProvider.searchResults[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 5, bottom: 5),
                                child: Card(
                                  color: Colors.black12,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  elevation: 0,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10.0),
                                    onTap: () {
                                      getSongDetails(song.id, context);
                                    },
                                    onLongPress: () {
                                      topSongs();
                                    },
                                    splashColor: AppColors.accent,
                                    hoverColor: AppColors.accent,
                                    focusColor: AppColors.accent,
                                    highlightColor: AppColors.accent,
                                    child: Column(
                                      children: <Widget>[
                                        ListTile(
                                          leading: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              MdiIcons.musicNoteOutline,
                                              size: 30,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                          title: Text(
                                            song.title
                                                .split("(")[0]
                                                .replaceAll("&quot;", "\"")
                                                .replaceAll("&amp;", "&"),
                                            style:
                                                TextStyle(color: Colors.white),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            song.artist,
                                            style:
                                                TextStyle(color: Colors.white),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: IconButton(
                                            color: AppColors.accent,
                                            icon:
                                                Icon(MdiIcons.downloadOutline),
                                            onPressed: () =>
                                                downloadSong(song.id),
                                            tooltip: 'Download',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }
                      // Show top songs if no search query
                      else if (searchProvider.showTopSongs) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top 20 Songs Heading
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                bottom: 16.0,
                                top: 8.0,
                              ),
                              child: Text(
                                "Top 20 songs of the week",
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Grid View
                            RepaintBoundary(
                              child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, // 2 columns
                                    crossAxisSpacing: 12.0,
                                    mainAxisSpacing: 12.0,
                                    childAspectRatio:
                                        0.8, // Adjust for card proportions
                                  ),
                                  itemCount: searchProvider.topSongs.length,
                                  itemBuilder: (BuildContext ctxt, int index) {
                                    final song = searchProvider.topSongs[index];
                                    return Card(
                                      color: Colors.black12,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      elevation: 2,
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        onTap: () {
                                          getSongDetails(song.id, context);
                                        },
                                        splashColor: AppColors.accent,
                                        hoverColor: AppColors.accent,
                                        focusColor: AppColors.accent,
                                        highlightColor: AppColors.accent,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            // Album Art Image
                                            Expanded(
                                              flex: 3,
                                              child: Container(
                                                width: double.infinity,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(12.0),
                                                    topRight:
                                                        Radius.circular(12.0),
                                                  ),
                                                  child: song
                                                          .imageUrl.isNotEmpty
                                                      ? AppImageWidgets
                                                          .albumArt(
                                                          imageUrl:
                                                              song.imageUrl,
                                                          width:
                                                              double.infinity,
                                                          height:
                                                              double.infinity,
                                                        )
                                                      : Container(
                                                          color: AppColors
                                                              .backgroundSecondary,
                                                          child: Center(
                                                            child: Icon(
                                                              MdiIcons
                                                                  .musicNoteOutline,
                                                              size: 40,
                                                              color: AppColors
                                                                  .accent,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                            // Song Info
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      song.title
                                                          .split("(")[0]
                                                          .replaceAll(
                                                              "&quot;", "\"")
                                                          .replaceAll(
                                                              "&amp;", "&"),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      song.artist,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Spacer(),
                                                    // Download button
                                                    Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: IconButton(
                                                        color: AppColors.accent,
                                                        icon: Icon(
                                                            MdiIcons
                                                                .downloadOutline,
                                                            size: 20),
                                                        onPressed: () =>
                                                            downloadSong(
                                                                song.id),
                                                        tooltip: 'Download',
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            BoxConstraints(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ],
                        );
                      }
                      // Show loading indicator when searching or loading top songs
                      else if (searchProvider.isSearching ||
                          searchProvider.isLoadingTopSongs) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        );
                      }
                      // Show empty state
                      else {
                        return Center(
                          child: Text(
                            'No songs found',
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
