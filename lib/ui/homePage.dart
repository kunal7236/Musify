import 'dart:io';

// import 'package:audiotagger/audiotagger.dart';  // Removed due to compatibility issues
// import 'package:audiotagger/models/tag.dart';   // Removed due to compatibility issues
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:gradient_widgets/gradient_widgets.dart';  // Temporarily disabled
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Musify/API/saavn.dart';
import 'package:Musify/music.dart' as music;
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
  TextEditingController searchBar = TextEditingController();
  bool fetchingSongs = false;

  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xff1c252a),
      statusBarColor: Colors.transparent,
    ));
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
    var status = await Permission.storage.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      // code of read or write file in external storage (SD card)
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      debugPrint(statuses[Permission.storage].toString());
    }
    status = await Permission.storage.status;
    await fetchSongDetails(id);
    if (status.isGranted) {
      EasyLoading.show(status: 'Downloading $title...');

      final filename = title + ".m4a";
      final artname = title + "_artwork.jpg";
      //Directory appDocDir = await getExternalStorageDirectory();
      Directory? musicDir = await getExternalStorageDirectory();
      String dlPath = "${musicDir?.path}/Music";
      await Directory(dlPath).create(recursive: true);

      await File(dlPath + "/" + filename)
          .create(recursive: true)
          .then((value) => filepath = value.path);
      await File(dlPath + "/" + artname)
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
      debugPrint('Audio path $filepath');
      debugPrint('Image path $filepath2');
      if (has_320 == "true") {
        kUrl = rawkUrl.replaceAll("_96.mp4", "_320.mp4");
        final client = http.Client();
        final request = http.Request('HEAD', Uri.parse(kUrl))
          ..followRedirects = false;
        final response = await client.send(request);
        debugPrint(response.statusCode.toString());
        kUrl = (response.headers['location']) ?? kUrl;
        debugPrint(rawkUrl);
        debugPrint(kUrl);
        final request2 = http.Request('HEAD', Uri.parse(kUrl))
          ..followRedirects = false;
        final response2 = await client.send(request2);
        if (response2.statusCode != 200) {
          kUrl = kUrl.replaceAll(".mp4", ".mp3");
        }
      }
      var request = await HttpClient().getUrl(Uri.parse(kUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      File file = File(filepath!);

      var request2 = await HttpClient().getUrl(Uri.parse(image));
      var response2 = await request2.close();
      var bytes2 = await consolidateHttpClientResponseBytes(response2);
      File file2 = File(filepath2!);

      await file.writeAsBytes(bytes);
      await file2.writeAsBytes(bytes2);
      debugPrint("Started tag editing");

      // TODO: Replace with compatible audio tagging library
      // final tag = Tag(
      //   title: title,
      //   artist: artist,
      //   artwork: filepath2,
      //   album: album,
      //   lyrics: lyrics,
      //   genre: null,
      // );

      debugPrint(
          "Setting up Tags - Temporarily disabled due to compatibility issues");
      // final tagger = Audiotagger();
      // await tagger.writeTags(
      //   path: filepath!,
      //   tag: tag,
      // );
      await Future.delayed(const Duration(seconds: 1), () {});
      EasyLoading.dismiss();

      if (await file2.exists()) {
        await file2.delete();
      }
      debugPrint("Done");
      Fluttertoast.showToast(
          msg: "Download Complete!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
          fontSize: 14.0);
    } else if (status.isDenied || status.isPermanentlyDenied) {
      Fluttertoast.showToast(
          msg: "Storage Permission Denied!\nCan't Download Songs",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
          fontSize: 14.0);
    } else {
      Fluttertoast.showToast(
          msg: "Permission Error!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.values[50],
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
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
                            onPressed: null,
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
                          icon: music.playerState == PlayerState.playing
                              ? Icon(MdiIcons.pause)
                              : Icon(MdiIcons.playOutline),
                          color: accent,
                          splashColor: Colors.transparent,
                          onPressed: () {
                            setState(() {
                              // Ensure audio player is initialized
                              if (music.audioPlayer == null) {
                                music.audioPlayer = AudioPlayer();
                                music.playerState = PlayerState.stopped;
                              }

                              if (music.playerState == PlayerState.playing) {
                                music.audioPlayer?.pause();
                                music.playerState = PlayerState.paused;
                              } else if (music.playerState ==
                                  PlayerState.paused) {
                                // Check if kUrl is valid before playing
                                if (kUrl.isNotEmpty &&
                                    Uri.tryParse(kUrl) != null) {
                                  music.audioPlayer?.play(UrlSource(kUrl));
                                  music.playerState = PlayerState.playing;
                                } else {
                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: Invalid audio URL'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // If stopped, start playing
                                if (kUrl.isNotEmpty &&
                                    Uri.tryParse(kUrl) != null) {
                                  music.audioPlayer?.play(UrlSource(kUrl));
                                  music.playerState = PlayerState.playing;
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
                            });
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
                        child: Text(
                          "Musify.",
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
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
                                    itemCount:
                                        (data.data as List?)?.length ?? 0,
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
