import 'package:flutter/material.dart';
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';

import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/core/constants/app_constants.dart';
import 'package:Musify/shared/widgets/app_widgets.dart';

class MusicPlayerAlbumArt extends StatelessWidget {
  final String imageUrl;
  final double size;

  const MusicPlayerAlbumArt({
    super.key,
    required this.imageUrl,
    this.size = AppConstants.albumArtSize,
  });

  @override
  Widget build(BuildContext context) {
    return AppImageWidgets.albumArt(
      imageUrl: imageUrl,
      width: size,
      height: size,
      backgroundColor: AppColors.backgroundSecondary,
      accentColor: AppColors.accent,
    );
  }
}

class MusicPlayerSongInfo extends StatelessWidget {
  final String title;
  final String artist;
  final String album;

  const MusicPlayerSongInfo({
    super.key,
    required this.title,
    required this.artist,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35.0, bottom: 35),
      child: Column(
        children: <Widget>[
          GradientText(
            title,
            shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
            gradient: LinearGradient(colors: [
              Color(0xff4db6ac),
              Color(0xff61e88a),
            ]),
            textScaleFactor: 2.5,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "$album  |  $artist",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
