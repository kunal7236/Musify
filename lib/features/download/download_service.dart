import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:audiotags/audiotags.dart';

import 'package:Musify/API/saavn.dart' as saavn;
import 'package:Musify/core/constants/app_colors.dart';

class DownloadService {
  static Future<void> downloadSong(String id) async {
    String? filepath;

    // Check Android version and request appropriate permissions
    bool permissionGranted = false;

    try {
      // For Android 13+ (API 33+), use media permissions
      // Check if permission is NOT granted (includes: denied, not determined, restricted, etc.)
      if (!await Permission.audio.isGranted) {
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
          backgroundColor: AppColors.backgroundModal,
          textColor: AppColors.textPrimary,
          fontSize: 14.0);
      return;
    }

    // Proceed with download
    await _fetchSongDetails(id);
    EasyLoading.show(status: 'Downloading ${saavn.title}...');

    try {
      final filename =
          saavn.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim() + ".m4a";

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
          debugPrint('✓ Using Downloads/Musify directory: $dlPath');
        } catch (e) {
          debugPrint('✗ Downloads directory failed: $e');

          // Strategy 2: Try app-specific external directory
          try {
            musicDir = await getExternalStorageDirectory();
            if (musicDir != null) {
              dlPath = "${musicDir.path}/Music";
              await Directory(dlPath).create(recursive: true);
              locationDescription = "App Music folder";
              debugPrint('✓ Using app-specific directory: $dlPath');
            } else {
              throw Exception('External storage not available');
            }
          } catch (e2) {
            debugPrint('✗ App-specific directory failed: $e2');

            // Strategy 3: Use internal app directory
            musicDir = await getApplicationDocumentsDirectory();
            dlPath = "${musicDir.path}/Music";
            await Directory(dlPath).create(recursive: true);
            locationDescription = "App Documents folder";
            debugPrint('✓ Using internal app directory: $dlPath');
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

      debugPrint('Audio path: $filepath');

      // Check if file already exists
      bool fileExists = await File(filepath).exists();
      if (fileExists) {
        EasyLoading.dismiss();
        Fluttertoast.showToast(
            msg: "✓ ${saavn.title} already downloaded!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: AppColors.backgroundModal,
            textColor: AppColors.accent,
            fontSize: 14.0);
        return;
      }

      // Download audio file
      debugPrint('Downloading audio from: ${saavn.rawkUrl}');
      var request = await http.get(Uri.parse(saavn.rawkUrl));
      var bytes = request.bodyBytes;
      await File(filepath).writeAsBytes(bytes);
      debugPrint('✓ Audio file saved to: $filepath');

      // Download artwork to memory (not saved to disk)
      Uint8List? artworkBytes;
      if (saavn.image.isNotEmpty) {
        try {
          debugPrint('Downloading artwork from: ${saavn.image}');
          var imageRequest = await http.get(Uri.parse(saavn.image));
          artworkBytes = Uint8List.fromList(imageRequest.bodyBytes);
          debugPrint(
              '✓ Artwork downloaded to memory (${artworkBytes.length} bytes)');
        } catch (e) {
          debugPrint('✗ Artwork download failed: $e');
          artworkBytes = null;
        }
      }

      // Write metadata tags using audiotags package
      try {
        debugPrint('Writing metadata tags...');
        final tag = Tag(
          title:
              saavn.title.replaceAll("&quot;", "\"").replaceAll("&amp;", "&"),
          trackArtist:
              saavn.artist.replaceAll("&quot;", "\"").replaceAll("&amp;", "&"),
          album:
              saavn.album.replaceAll("&quot;", "\"").replaceAll("&amp;", "&"),
          pictures: artworkBytes != null
              ? [
                  Picture(
                    bytes: artworkBytes,
                    mimeType: MimeType.jpeg,
                    pictureType: PictureType.coverFront,
                  ),
                ]
              : [],
        );

        await AudioTags.write(filepath, tag);
        debugPrint('✓ Metadata written successfully');
      } catch (e) {
        debugPrint('✗ Metadata write failed: $e');
      }

      EasyLoading.dismiss();
      Fluttertoast.showToast(
          msg:
              "✓ ${saavn.title} downloaded successfully!\nSaved in: $locationDescription",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: AppColors.backgroundModal,
          textColor: AppColors.accent,
          fontSize: 14.0);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('✗ Download error: $e');
      Fluttertoast.showToast(
          msg: "✗ Download failed: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: AppColors.backgroundModal,
          textColor: AppColors.error,
          fontSize: 14.0);
    }
  }

  static Future<void> _fetchSongDetails(String id) async {
    try {
      debugPrint('Fetching song details for ID: $id');
      bool success = await saavn.fetchSongDetails(id);

      if (success) {
        // Global variables are set by fetchSongDetails
        debugPrint('✓ Fetched song details: ${saavn.title} by ${saavn.artist}');
      } else {
        throw Exception('Failed to fetch song details');
      }
    } catch (e) {
      debugPrint('✗ Error fetching song details: $e');
      throw e;
    }
  }
}
