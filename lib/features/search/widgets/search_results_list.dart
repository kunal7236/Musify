import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'package:Musify/providers/search_provider.dart';
import 'package:Musify/core/constants/app_colors.dart';

class SearchResultsList extends StatelessWidget {
  final Function(String songId, BuildContext context) onSongTap;
  final Function(String songId) onDownload;
  final VoidCallback onLongPress;

  const SearchResultsList({
    super.key,
    required this.onSongTap,
    required this.onDownload,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (!searchProvider.showSearchResults) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchProvider.searchResults.length,
            itemBuilder: (BuildContext context, int index) {
              final song = searchProvider.searchResults[index];
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
                      onSongTap(song.id, context);
                    },
                    onLongPress: onLongPress,
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
                            style: TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            style: TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            color: AppColors.accent,
                            icon: Icon(MdiIcons.downloadOutline),
                            onPressed: () => onDownload(song.id),
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
      },
    );
  }
}
