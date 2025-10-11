import 'dart:io';
import 'dart:math';

// import 'package:audiotagger/audiotagger.dart';  // Removed due to compatibility issues
// import 'package:audiotagger/models/tag.dart';   // Removed due to compatibility issues
import 'package:audiotags/audiotags.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:Musify/services/audio_player_service.dart';
import 'package:Musify/style/appColors.dart';
import 'package:Musify/ui/aboutPage.dart';
import 'package:permission_handler/permission_handler.dart';

class Musify extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

class AppState extends State<Musify> {
  late final AudioPlayerService _audioService;
  TextEditingController searchBar = TextEditingController();
  bool fetchingSongs = false;
  PlayerState _currentPlayerState = PlayerState.stopped;

  void initState() {
    super.initState();

    // Initialize audio service
    _audioService = AudioPlayerService();
    _initializeAudioService();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xff1c252a),
      statusBarColor: Colors.transparent,
    ));
  }

  @override
  void dispose() {
    // AudioService is a singleton, so we don't dispose it here
    // It will be managed by the service itself
    super.dispose();
  }

  /// Initialize audio service and listen to state changes
  void _initializeAudioService() async {
    try {
      if (!_audioService.isInitialized) {
        await _audioService.initialize();
      }

      // Listen to player state changes for UI updates
      _audioService.stateStream.listen((state) {
        if (mounted) {
          setState(() {
            _currentPlayerState = state;
          });
        }
      });

      // Update current state
      setState(() {
        _currentPlayerState = _audioService.playerState;
      });
    } catch (e) {
      debugPrint('❌ Failed to initialize audio service in HomePage: $e');
    }
  }

  search() async {
    String searchQuery = searchBar.text;
    if (searchQuery.isEmpty) return;
    fetchingSongs = true;
    setState(() {});
    await fetchSongsList(searchQuery);
    fetchingSongs = false;
    setState(() {});
  }

  getSongDetails(String id, var context) async {
    // Show loading indicator
    EasyLoading.show(status: 'Loading song...');

    try {
      await fetchSongDetails(id);
      debugPrint('Fetched song details. URL: $kUrl');

      // Check if we got a valid URL
      if (kUrl.isEmpty || Uri.tryParse(kUrl) == null) {
        throw Exception('Failed to get valid audio URL');
      }

      debugPrint('Valid URL obtained: $kUrl');
    } catch (e) {
      artist = "Unknown";
      debugPrint('Error fetching song details: $e');

      EasyLoading.dismiss();

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading song: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return; // Don't navigate to music player if there's an error
    }

    EasyLoading.dismiss();

    setState(() {
      checker = "Haa";
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => music.AudioApp(),
      ),
    );
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
          debugPrint('✅ Using Downloads/Musify directory: $dlPath');
        } catch (e) {
          debugPrint('❌ Downloads directory failed: $e');

          // Strategy 2: Try app-specific external directory
          try {
            musicDir = await getExternalStorageDirectory();
            if (musicDir != null) {
              dlPath = "${musicDir.path}/Music";
              await Directory(dlPath).create(recursive: true);
              locationDescription = "App Music folder";
              debugPrint('✅ Using app-specific directory: $dlPath');
            } else {
              throw Exception('External storage not available');
            }
          } catch (e2) {
            debugPrint('❌ App-specific directory failed: $e2');

            // Strategy 3: Use internal app directory
            musicDir = await getApplicationDocumentsDirectory();
            dlPath = "${musicDir.path}/Music";
            await Directory(dlPath).create(recursive: true);
            locationDescription = "App Documents folder";
            debugPrint('✅ Using internal app directory: $dlPath');
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
      debugPrint('🎵 Starting audio download...');
      var request = await HttpClient().getUrl(Uri.parse(audioUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      File file = File(filepath);
      await file.writeAsBytes(bytes);
      debugPrint('✅ Audio file saved successfully');

      // Download image file
      debugPrint('🖼️ Starting image download...');
      var request2 = await HttpClient().getUrl(Uri.parse(image));
      var response2 = await request2.close();
      var bytes2 = await consolidateHttpClientResponseBytes(response2);
      File file2 = File(filepath2);
      await file2.writeAsBytes(bytes2);
      debugPrint('✅ Image file saved successfully');

      debugPrint("🏷️ Starting tag editing");

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
        debugPrint("✅ Tags written successfully");
      } catch (e) {
        debugPrint("⚠️ Error writing tags: $e");
        // Continue even if tagging fails
      }

      // Clean up temporary image file
      try {
        if (await file2.exists()) {
          await file2.delete();
          debugPrint('🗑️ Temporary image file cleaned up');
        }
      } catch (e) {
        debugPrint('⚠️ Could not clean up temp file: $e');
      }

      EasyLoading.dismiss();
      debugPrint("🎉 Download completed successfully");

      // Show success message with accessible location
      Fluttertoast.showToast(
          msg:
              "✅ Download Complete!\n📁 Saved to: $locationDescription\n🎵 $filename",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 4,
          backgroundColor: Colors.green[800],
          textColor: Colors.white,
          fontSize: 14.0);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("❌ Download error: $e");

      Fluttertoast.showToast(
          msg:
              "❌ Download Failed!\n${e.toString().contains('Permission') ? 'Storage permission denied' : 'Error: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e}'}",
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff384850),
            Color(0xff263238),
            Color(0xff263238),
          ],
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        //backgroundColor: Color(0xff384850),
        bottomNavigationBar: kUrl != ""
            ? Container(
                height: 75,
                //color: Color(0xff1c252a),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18)),
                    color: Color(0xff1c252a)),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                  child: GestureDetector(
                    onTap: () {
                      checker = "Nahi";
                      if (kUrl != "") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => music.AudioApp()),
                        );
                      }
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
                              checker = "Nahi";
                              if (kUrl != "") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => music.AudioApp()),
                                );
                              }
                            },
                            disabledColor: accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 0.0, top: 7, bottom: 7, right: 15),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                title,
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                artist,
                                style:
                                    TextStyle(color: accentLight, fontSize: 15),
                              )
                            ],
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: _currentPlayerState == PlayerState.playing
                              ? Icon(MdiIcons.pause)
                              : Icon(MdiIcons.playOutline),
                          color: accent,
                          splashColor: Colors.transparent,
                          onPressed: () async {
                            try {
                              if (_currentPlayerState == PlayerState.playing) {
                                // Pause the current playback
                                await _audioService.pause();
                              } else if (_currentPlayerState ==
                                  PlayerState.paused) {
                                // Resume playback
                                await _audioService.resume();
                              } else {
                                // Start playing if stopped
                                if (kUrl.isNotEmpty &&
                                    Uri.tryParse(kUrl) != null) {
                                  await _audioService.play(kUrl);
                                } else {
                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: Invalid audio URL'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('❌ Audio control error: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Audio error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          iconSize: 45,
                        )
                      ],
                    ),
                  ),
                ),
              )
            : SizedBox.shrink(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(top: 30, bottom: 20.0)),
              Center(
                child: Row(children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 42.0),
                      child: Center(
                        child: GradientText(
                          "Musify.",
                          shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
                          gradient: LinearGradient(colors: [
                            Color(0xff4db6ac),
                            Color(0xff61e88a),
                          ]),
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
                  //           color: accent,
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
                      color: accent,
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutPage(),
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
                  color: accent,
                ),
                cursorColor: Colors.green[50],
                decoration: InputDecoration(
                  fillColor: Color(0xff263238),
                  filled: true,
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(100),
                    ),
                    borderSide: BorderSide(
                      color: Color(0xff263238),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(100),
                    ),
                    borderSide: BorderSide(color: accent),
                  ),
                  suffixIcon: IconButton(
                    icon: fetchingSongs
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accent),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.search,
                            color: accent,
                          ),
                    color: accent,
                    onPressed: () {
                      search();
                    },
                  ),
                  border: InputBorder.none,
                  hintText: "Search...",
                  hintStyle: TextStyle(
                    color: accent,
                  ),
                  contentPadding: const EdgeInsets.only(
                    left: 18,
                    right: 20,
                    top: 14,
                    bottom: 14,
                  ),
                ),
              ),
              searchedList.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: searchedList.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 5),
                          child: Card(
                            color: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10.0),
                              onTap: () {
                                getSongDetails(
                                    searchedList[index]["id"], context);
                              },
                              onLongPress: () {
                                topSongs();
                              },
                              splashColor: accent,
                              hoverColor: accent,
                              focusColor: accent,
                              highlightColor: accent,
                              child: Column(
                                children: <Widget>[
                                  ListTile(
                                    leading: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        MdiIcons.musicNoteOutline,
                                        size: 30,
                                        color: accent,
                                      ),
                                    ),
                                    title: Text(
                                      (searchedList[index]['title'])
                                          .toString()
                                          .split("(")[0]
                                          .replaceAll("&quot;", "\"")
                                          .replaceAll("&amp;", "&"),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      searchedList[index]['more_info']
                                          ["singers"],
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    trailing: IconButton(
                                      color: accent,
                                      icon: Icon(MdiIcons.downloadOutline),
                                      onPressed: () => downloadSong(
                                          searchedList[index]["id"]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : FutureBuilder(
                      future: topSongs(),
                      builder: (context, data) {
                        if (data.hasData)
                          return Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 30.0, bottom: 10, left: 8),
                                  child: Text(
                                    "Top 15 Songs",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  //padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                                  height:
                                      MediaQuery.of(context).size.height * 0.22,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: min(
                                        15, (data.data as List?)?.length ?? 0),
                                    itemBuilder: (context, index) {
                                      final List? songList = data.data as List?;
                                      if (songList == null ||
                                          index >= songList.length) {
                                        return Container(); // Return empty container for safety
                                      }

                                      return getTopSong(
                                          songList[index]["image"] ?? "",
                                          songList[index]["title"] ?? "Unknown",
                                          songList[index]["more_info"]
                                                          ?["artistMap"]
                                                      ?["primary_artists"]?[0]
                                                  ?["name"] ??
                                              "Unknown",
                                          songList[index]["id"] ?? "");
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        return Center(
                            child: Padding(
                          padding: const EdgeInsets.all(35.0),
                          child: CircularProgressIndicator(
                            valueColor:
                                new AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ));
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getTopSong(String image, String title, String subtitle, String id) {
    return InkWell(
      onTap: () {
        getSongDetails(id, context);
      },
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.17,
            width: MediaQuery.of(context).size.width * 0.4,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: CachedNetworkImageProvider(image),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            title
                .split("(")[0]
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\""),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
