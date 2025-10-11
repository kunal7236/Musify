import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'package:Musify/providers/search_provider.dart';
import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/shared/widgets/app_widgets.dart';

class TopSongsGrid extends StatelessWidget {
  final Function(String songId, BuildContext context) onSongTap;
  final Function(String songId) onDownload;

  const TopSongsGrid({
    super.key,
    required this.onSongTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.topSongs.isEmpty) {
          return const SizedBox.shrink();
        }

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
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.8, // Adjust for card proportions
                ),
                itemCount: searchProvider.topSongs.length,
                itemBuilder: (BuildContext context, int index) {
                  final song = searchProvider.topSongs[index];
                  return Card(
                    color: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        onSongTap(song.id, context);
                      },
                      splashColor: AppColors.accent,
                      hoverColor: AppColors.accent,
                      focusColor: AppColors.accent,
                      highlightColor: AppColors.accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Album Art Image
                          Expanded(
                            flex: 3,
                            child: Container(
                              width: double.infinity,
                              color: Colors
                                  .black12, // Match the card background color
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12.0),
                                  topRight: Radius.circular(12.0),
                                ),
                                child: song.imageUrl.isNotEmpty
                                    ? AppImageWidgets.albumArt(
                                        imageUrl: song.imageUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Container(
                                        color: AppColors.backgroundSecondary,
                                        child: Center(
                                          child: Icon(
                                            MdiIcons.musicNoteOutline,
                                            size: 40,
                                            color: AppColors.accent,
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
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title
                                        .split("(")[0]
                                        .replaceAll("&quot;", "\"")
                                        .replaceAll("&amp;", "&"),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    song.artist,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Spacer(),
                                  // Download button
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      color: AppColors.accent,
                                      icon: Icon(
                                        MdiIcons.downloadOutline,
                                        size: 20,
                                      ),
                                      onPressed: () => onDownload(song.id),
                                      tooltip: 'Download',
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
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
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
