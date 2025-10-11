import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:Musify/core/constants/app_colors.dart';

class ContactCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String imageUrl;
  final String? telegramUrl;
  final String? xUrl;
  final Color textColor;

  const ContactCard({
    Key? key,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    this.telegramUrl,
    this.xUrl,
    this.textColor = Colors.white,
  }) : super(key: key);

  // Future<void> _launchOnTap(String url) async {
  //   final Uri uri = Uri.parse(url);
  //   if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
  //     throw 'Could not launch $url';
  //   }
  // }
  Future<void> _launchOnTap(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    )) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
      child: Card(
        color: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2.3,
        child: ListTile(
          leading: Container(
            width: 50.0,
            height: 50.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(imageUrl),
              ),
            ),
          ),
          title: Text(
            name,
            style: TextStyle(color: textColor),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: textColor),
          ),
          trailing: Wrap(
            children: [
              if (telegramUrl != null)
                IconButton(
                  icon: Icon(MdiIcons.send, color: textColor),
                  tooltip: 'Contact on Telegram',
                  onPressed: () async {
                    await _launchOnTap(telegramUrl!);
                  },
                ),
              if (xUrl != null)
                IconButton(
                  icon: Icon(MdiIcons.twitter, color: textColor),
                  tooltip: 'Contact on x',
                  onPressed: () async {
                    await _launchOnTap(xUrl!);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
