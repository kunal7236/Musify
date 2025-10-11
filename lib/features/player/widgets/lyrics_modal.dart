import 'package:flutter/material.dart';

import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/models/app_models.dart';
import 'package:Musify/API/saavn.dart' as saavn;

class LyricsBottomSheet extends StatelessWidget {
  final Song song;

  const LyricsBottomSheet({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate height to start from below play/pause button
    // This positions the modal to cover only the lower portion of the screen
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.5; // Cover bottom 50% of screen

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18.0),
          topRight: const Radius.circular(18.0),
        ),
      ),
      height: modalHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 42.0),
                    child: Center(
                      child: Text(
                        "Lyrics",
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    child: saavn.has_lyrics == "true"
                        ? Text(
                            saavn.lyrics,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            "Lyrics not available",
                            style: TextStyle(
                              fontSize: 16.0,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LyricsBottomSheet(song: song),
    );
  }
}
