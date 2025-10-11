import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';
import 'package:provider/provider.dart';

import 'package:Musify/providers/search_provider.dart';
import 'package:Musify/core/constants/app_colors.dart';
import 'package:Musify/ui/aboutPage.dart';

class HomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onClearSearch;

  const HomeHeader({
    super.key,
    required this.searchController,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        return Column(
          children: [
            Padding(padding: EdgeInsets.only(top: 30, bottom: 20.0)),
            Center(
              child: Row(
                children: <Widget>[
                  // Back button when showing search results
                  if (searchProvider.showSearchResults)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.accent,
                        size: 28,
                      ),
                      onPressed: onClearSearch,
                    )
                  else
                    SizedBox(
                        width:
                            48), // Placeholder to maintain consistent spacing

                  // Centered Musify text
                  Expanded(
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

                  // Settings button (always visible)
                  IconButton(
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
