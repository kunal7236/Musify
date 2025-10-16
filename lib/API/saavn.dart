import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'des_helper.dart';

List searchedList = [];
List topSongsList = [];
String kUrl = "",
    checker = "",
    image = "",
    title = "",
    album = "",
    artist = "",
    lyrics = "",
    has_lyrics = "",
    has_320 = "",
    albumId = "",
    rawkUrl = "";

// API Endpoints (exactly as in your Python endpoints.py)
const String searchBaseUrl =
    "https://www.jiosaavn.com/api.php?__call=autocomplete.get&_format=json&_marker=0&cc=in&includeMetaTags=1&query=";
const String songDetailsBaseUrl =
    "https://www.jiosaavn.com/api.php?__call=song.getDetails&cc=in&_marker=0%3F_marker%3D0&_format=json&pids=";
const String albumDetailsBaseUrl =
    "https://www.jiosaavn.com/api.php?__call=content.getAlbumDetails&_format=json&cc=in&_marker=0%3F_marker%3D0&albumid=";
const String playlistDetailsBaseUrl =
    "https://www.jiosaavn.com/api.php?__call=playlist.getDetails&_format=json&cc=in&_marker=0%3F_marker%3D0&listid=";
const String lyricsBaseUrl =
    "https://www.jiosaavn.com/api.php?__call=lyrics.getLyrics&ctx=web6dot0&api_version=4&_format=json&_marker=0%3F_marker%3D0&lyrics_id=";

// DES Decryption function (Python pyDes equivalent implementation)
String decryptUrl(String encryptedUrl) {
  return DESHelper.decryptUrl(encryptedUrl);
}

// Format string function (as per your Python helper.py)
String formatString(String input) {
  return input
      .replaceAll("&quot;", "'")
      .replaceAll("&amp;", "&")
      .replaceAll("&#039;", "'");
}

// Search for songs (exactly as per your Python jiosaavn.py search_for_song function)
Future<List> fetchSongsList(String searchQuery) async {
  try {
    String searchUrl = searchBaseUrl + Uri.encodeComponent(searchQuery);
    debugPrint('🔍 Search URL: $searchUrl');

    var response = await http.get(Uri.parse(searchUrl));

    if (response.statusCode != 200) {
      throw Exception('Search API failed with status: ${response.statusCode}');
    }

    // Handle response format (as per your Python code)
    String responseBody = response.body;
    if (responseBody.contains("-->")) {
      var resEdited = responseBody.split("-->");
      if (resEdited.length < 2) {
        throw Exception('Invalid search API response format');
      }
      responseBody = resEdited[1];
    }

    // Parse JSON response
    dynamic responseJson = json.decode(responseBody);

    // Process songs data (as per your Python logic)
    List songResponse = responseJson['songs']['data'];
    searchedList = songResponse;

    // Format song data (as per your Python helper.py)
    for (int i = 0; i < searchedList.length; i++) {
      searchedList[i]['title'] = formatString(searchedList[i]['title'] ?? '');
      searchedList[i]['music'] = formatString(searchedList[i]['music'] ?? '');
      searchedList[i]['singers'] =
          formatString(searchedList[i]['singers'] ?? '');
      searchedList[i]['album'] = formatString(searchedList[i]['album'] ?? '');

      // Enhance image quality
      if (searchedList[i]['image'] != null) {
        searchedList[i]['image'] = searchedList[i]['image']
            .toString()
            .replaceAll("150x150", "500x500");
      }
    }

    return searchedList;
  } catch (e) {
    debugPrint('❌ Search failed: $e');
    return [];
  }
}

// Get song details (exactly as per your Python jiosaavn.py get_song+get_lyrics function)
Future<bool> fetchSongDetails(String songId) async {
  try {
    debugPrint('🎵 Getting song details for ID: $songId');

    // Use the exact API endpoint from your Python endpoints.py
    String songDetailsUrl = songDetailsBaseUrl + songId;

    debugPrint('📡 API URL: $songDetailsUrl');

    var response = await http.get(Uri.parse(songDetailsUrl));

    if (response.statusCode != 200) {
      debugPrint('❌ API failed with status: ${response.statusCode}');
      checker = "something went wrong";
      return false;
    }

    // Handle response format (as per your Python code)
    String responseBody = response.body;
    if (responseBody.contains("-->")) {
      var resEdited = responseBody.split("-->");
      if (resEdited.length < 2) {
        debugPrint('❌ Invalid API response format');
        checker = "something went wrong";
        return false;
      }
      responseBody = resEdited[1];
    }

    // Parse JSON
    dynamic songResponse = json.decode(responseBody);

    if (!songResponse.containsKey(songId)) {
      debugPrint('❌ Song ID not found in response');
      checker = "something went wrong";
      return false;
    }

    var songData = songResponse[songId];

    // Extract song information (following your Python format_song function)
    title = formatString(songData["song"] ?? "");
    album = formatString(songData["album"] ?? "");
    artist = formatString(songData["singers"] ?? "");
    albumId = songData["albumid"] ?? "";
    has_lyrics = songData["has_lyrics"] ?? "false";
    image =
        (songData["image"] ?? "").toString().replaceAll("150x150", "500x500");
    has_320 = songData["320kbps"] ?? "false";

    debugPrint('🎼 Song: $title');
    debugPrint('🎤 Artist: $artist');
    debugPrint('💿 Album: $album');
    debugPrint('💿 Album ID: $albumId');
    debugPrint('🔊 320kbps: $has_320');
    debugPrint('🔊 has lyrics: $has_lyrics');

    if (has_lyrics == "true") {
      String lyricsUrl = lyricsBaseUrl + songId;
      debugPrint('📡 API URL: $lyricsUrl');
      var resLyrics = await http.get(Uri.parse(lyricsUrl));
      if (resLyrics.statusCode != 200) {
        debugPrint('❌ API failed with status: ${resLyrics.statusCode}');
        checker = "something went wrong";
      }
      dynamic lyricsResponse = json.decode(resLyrics.body);
      lyrics = lyricsResponse["lyrics"];
      lyrics = lyrics.replaceAll("<br>", "\n");
    }

    // Debug: Print all available fields in songData
    debugPrint('🔍 Available songData fields: ${songData.keys.toList()}');
    if (songData["more_info"] != null) {
      debugPrint(
          '🔍 Available more_info fields: ${songData["more_info"].keys.toList()}');
    }

    // URL processing (following your Python helper.py format_song logic)
    String mediaUrl = "";
    String encryptedMediaUrl = songData["encrypted_media_url"] ?? "";

    try {
      // Try to decrypt encrypted_media_url (main method from your Python code)
      if (encryptedMediaUrl.isNotEmpty) {
        debugPrint('🔐 Found encrypted_media_url, decrypting...');
        mediaUrl = decryptUrl(encryptedMediaUrl);

        if (mediaUrl.isNotEmpty) {
          debugPrint('✅ Successfully decrypted URL');

          // Apply quality selection (as per your Python logic)
          if (has_320 != "true") {
            mediaUrl = mediaUrl.replaceAll("_320.mp4", "_160.mp4");
            debugPrint('📶 Using 160kbps quality');
          } else {
            debugPrint('📶 Using 320kbps quality');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Decryption failed: $e');
    }


    if (mediaUrl.isEmpty) {
      debugPrint('❌ Failed to get any working media URL');
      checker = "something went wrong";
      return false;
    }

    kUrl = mediaUrl;
    rawkUrl = mediaUrl;

    debugPrint('🎯 Final media URL: $kUrl');
    checker = "successfully done";
    return true;
  } catch (e) {
    debugPrint('❌ fetchSongDetails failed: $e');
    checker = "something went wrong";
    return false;
  }
}

// Top songs function
Future<List> topSongs() async {
  try {
    String topSongsUrl =
        "https://www.jiosaavn.com/api.php?__call=webapi.get&token=8MT-LQlP35c_&type=playlist&p=1&n=20&includeMetaTags=0&ctx=web6dot0&api_version=4&_format=json&_marker=0";

    // Add headers to mimic browser behavior and handle SSL issues
    Map<String, String> headers = {
      "Accept": "application/json",
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
      "Accept-Language": "en-US,en;q=0.9",
      "Cache-Control": "no-cache",
      "Pragma": "no-cache"
    };

    var songsListJSON =
        await http.get(Uri.parse(topSongsUrl), headers: headers);

    if (songsListJSON.statusCode == 200) {
      var songsList = json.decode(songsListJSON.body);
      topSongsList = songsList["list"];

      for (int i = 0; i < topSongsList.length; i++) {
        topSongsList[i]['title'] =
            formatString(topSongsList[i]['title'].toString());

        if (topSongsList[i]["more_info"]["artistMap"]["primary_artists"] !=
                null &&
            topSongsList[i]["more_info"]["artistMap"]["primary_artists"]
                    .length >
                0) {
          topSongsList[i]["more_info"]["artistMap"]["primary_artists"][0]
              ["name"] = formatString(topSongsList[i]["more_info"]["artistMap"]
                  ["primary_artists"][0]["name"]
              .toString());
        }

        topSongsList[i]['image'] = topSongsList[i]['image']
            .toString()
            .replaceAll("150x150", "500x500");
      }

      debugPrint('✅ Successfully fetched ${topSongsList.length} top songs');
      return topSongsList;
    } else {
      debugPrint(
          '❌ Top songs API failed with status: ${songsListJSON.statusCode}');
      return [];
    }
  } catch (e) {
    debugPrint('❌ Failed to fetch top songs: $e');
    // Return empty list instead of throwing error
    return [];
  }
}

bool isVpnConnected() {
  if (kUrl.isNotEmpty) {
    return kUrl.contains('150x150');
  } else {
    return false;
  }
}

// Get album details (for fetching album song IDs)
// Returns minimal info - just song IDs and basic metadata
// Actual song details (including playback URLs) will be fetched on-demand
Future<List<Map<String, dynamic>>> fetchAlbumDetails(String albumId) async {
  try {
    debugPrint('💿 Fetching album details for ID: $albumId');

    String albumUrl = albumDetailsBaseUrl + albumId;
    debugPrint('📡 Album API URL: $albumUrl');

    var response = await http.get(Uri.parse(albumUrl));

    if (response.statusCode != 200) {
      debugPrint('❌ Album API failed with status: ${response.statusCode}');
      return [];
    }

    // Handle response format
    String responseBody = response.body;
    if (responseBody.contains("-->")) {
      var resEdited = responseBody.split("-->");
      if (resEdited.length < 2) {
        debugPrint('❌ Invalid album API response format');
        return [];
      }
      responseBody = resEdited[1];
    }

    // Parse JSON
    dynamic albumResponse = json.decode(responseBody);

    // Check if songs array exists
    if (albumResponse == null || albumResponse['songs'] == null) {
      debugPrint('❌ No songs found in album');
      return [];
    }

    List albumSongs = albumResponse['songs'];
    List<Map<String, dynamic>> songIds = [];

    debugPrint('💿 Album: ${albumResponse['title'] ?? 'Unknown'}');
    debugPrint('💿 Found ${albumSongs.length} songs in album');

    // Extract just the song IDs and basic info
    // Don't filter anything - let the actual fetchSongDetails handle DRM/availability
    for (var song in albumSongs) {
      songIds.add({
        'id': song['id'] ?? '',
        'title': formatString(song['song'] ?? ''),
        'artist': formatString(song['singers'] ?? ''),
        'image':
            (song['image'] ?? '').toString().replaceAll('150x150', '500x500'),
      });
    }

    debugPrint('✅ Extracted ${songIds.length} song IDs from album');
    return songIds;
  } catch (e) {
    debugPrint('❌ fetchAlbumDetails failed: $e');
    return [];
  }
}
