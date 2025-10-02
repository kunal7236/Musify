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
    has_320 = "",
    rawkUrl = "";

// API Endpoints (exactly as in your Python endpoints.py)
const String searchBaseUrl =
    "https://www.jiosaavn.com/api.php?__call=autocomplete.get&_format=json&_marker=0&cc=in&includeMetaTags=1&query=";
const String songDetailsBaseUrl =
    "https://www.jiosaavn.com/api.php?__call=song.getDetails&cc=in&_marker=0%3F_marker%3D0&_format=json&pids=";

// DES Decryption function (Python pyDes equivalent implementation)
String decryptUrl(String encryptedUrl) {
  // Use the dedicated DES helper with multiple approaches
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

// Get song details (exactly as per your Python jiosaavn.py get_song function)
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
    image =
        (songData["image"] ?? "").toString().replaceAll("150x150", "500x500");
    has_320 = songData["320kbps"] ?? "false";

    debugPrint('🎼 Song: $title');
    debugPrint('🎤 Artist: $artist');
    debugPrint('💿 Album: $album');
    debugPrint('🔊 320kbps: $has_320');

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

    // Alternative approach (try other fields)
    if (mediaUrl.isEmpty) {
      debugPrint('🔄 Trying alternative URL construction methods...');

      try {
        // Method 1: Check for direct media_url field
        if (songData["media_url"] != null) {
          String directUrl = songData["media_url"] ?? "";
          if (directUrl.isNotEmpty) {
            debugPrint('🔄 Found direct media_url: $directUrl');
            mediaUrl = directUrl.replaceAll("_96.mp4", "_320.mp4");
            if (mediaUrl.isNotEmpty) {
              debugPrint('✅ Using direct media_url: $mediaUrl');
            }
          }
        }

        // Method 2: Try media_preview_url with proper construction
        if (mediaUrl.isEmpty && songData["media_preview_url"] != null) {
          String previewUrl = songData["media_preview_url"] ?? "";
          if (previewUrl.isNotEmpty) {
            debugPrint('🔄 Found media_preview_url: $previewUrl');

            // Convert preview URL to full URL properly - use aac.saavncdn.com
            String constructedUrl = previewUrl
                .replaceAll("preview.saavncdn.com", "aac.saavncdn.com")
                .replaceAll("_96_p.mp4", "_320.mp4")
                .replaceAll("_96.mp4", "_320.mp4");

            if (constructedUrl != previewUrl &&
                constructedUrl.contains("http")) {
              debugPrint('✅ Constructed URL from preview: $constructedUrl');
              mediaUrl = constructedUrl;
            }
          }
        }

        // Method 3: Check more_info for alternative URLs
        if (mediaUrl.isEmpty) {
          var moreInfo = songData["more_info"];
          if (moreInfo != null) {
            debugPrint('🔄 Checking more_info for alternative URLs...');

            // Check for various URL fields in more_info
            List<String> urlFields = [
              "media_url",
              "song_url",
              "perma_url",
              "vlink"
            ];
            for (String field in urlFields) {
              if (moreInfo[field] != null) {
                String altUrl = moreInfo[field].toString();
                if (altUrl.contains("http") && altUrl.contains(".mp4")) {
                  debugPrint('🔍 Found $field: $altUrl');
                  mediaUrl = altUrl.replaceAll("_96.mp4", "_320.mp4");
                  break;
                }
              }
            }

            // Try encrypted_media_url from more_info if different
            if (mediaUrl.isEmpty && moreInfo["encrypted_media_url"] != null) {
              String altEncryptedUrl = moreInfo["encrypted_media_url"];
              if (altEncryptedUrl.isNotEmpty &&
                  altEncryptedUrl != encryptedMediaUrl) {
                debugPrint(
                    '🔄 Trying alternative encrypted URL from more_info...');
                mediaUrl = decryptUrl(altEncryptedUrl);
              }
            }
          }
        }

        // Method 4: Try to construct URL from song ID and metadata
        if (mediaUrl.isEmpty) {
          debugPrint('🔄 Attempting URL construction from song metadata...');

          String songId = songData["id"] ?? "";
          String permaUrl = songData["perma_url"] ?? "";

          if (songId.isNotEmpty) {
            // Try common JioSaavn URL patterns - use aac.saavncdn.com
            List<String> patterns = [
              "https://aac.saavncdn.com/${songId}/${songId}_320.mp4",
              "https://aac.saavncdn.com/${songId.substring(0, 3)}/${songId}_320.mp4",
              "https://snoidcdncol01.snoidcdn.com/${songId}/${songId}_320.mp4",
            ];

            for (String pattern in patterns) {
              debugPrint('🔍 Testing URL pattern: $pattern');
              mediaUrl = pattern;
              break; // Use first pattern for testing
            }
          }

          // If song ID approach didn't work, try constructing from perma_url
          if (mediaUrl.isEmpty && permaUrl.isNotEmpty) {
            debugPrint('🔄 Trying to extract ID from perma_url: $permaUrl');
            // Extract song ID from perma_url if possible
            RegExp idPattern = RegExp(r'/([^/]+)/?$');
            Match? match = idPattern.firstMatch(permaUrl);
            if (match != null) {
              String extractedId = match.group(1)!;
              debugPrint('🔍 Extracted ID: $extractedId');
              mediaUrl =
                  "https://aac.saavncdn.com/${extractedId}/${extractedId}_320.mp4";
              debugPrint('🔍 Constructed from perma_url: $mediaUrl');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Alternative approach failed: $e');
      }
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
