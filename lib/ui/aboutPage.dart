import 'package:flutter/material.dart';
import 'package:gradient_widgets_plus/gradient_widgets_plus.dart';
import 'package:Musify/helper/contact_widget.dart';
import 'package:Musify/style/appColors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AboutPage extends StatelessWidget {
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          title: GradientText(
            "About",
            shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
            gradient: LinearGradient(colors: [
              Color(0xff4db6ac),
              Color(0xff61e88a),
            ]),
            style: TextStyle(
              color: accent,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: accent,
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        // appBar: AppBar(
        //   systemOverlayStyle: SystemUiOverlayStyle.light,
        //   centerTitle: true,
        //   title: Text(
        //     "About",
        //     style: TextStyle(
        //       color: accent,
        //       fontSize: 25,
        //       fontWeight: FontWeight.w700,
        //     ),
        //   ),
        //   leading: IconButton(
        //     icon: Icon(
        //       Icons.arrow_back,
        //       color: accent,
        //     ),
        //     onPressed: () => Navigator.pop(context, false),
        //   ),
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        // ),
        body: SingleChildScrollView(child: AboutCards()),
      ),
    );
  }
}

class AboutCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(top: 20, left: 8, right: 8, bottom: 6),
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Image.asset(
                    "assets/image.png",
                    height: 120,
                  ),
                  // title: Image.network(
                  //   "https://telegra.ph/file/4798f3a9303b8300e4b5b.png",
                  //   height: 120,
                  // ),
                  subtitle: Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: Center(
                      child: Text(
                        "Musify  | 2.1.0",
                        style: TextStyle(
                            color: accentLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ContactCard(
            name: 'Harsh V23',
            subtitle: 'App Developer',
            imageUrl: 'https://telegram.im/img/harshv23',
            telegramUrl: 'https://telegram.dog/harshv23',
            xUrl: 'https://x.com/harshv23',
            textColor: accentLight,
          ),
          ContactCard(
            name: 'Sumanjay',
            subtitle: 'App Developer',
            imageUrl: 'https://telegra.ph/file/a64152b2fae1bf6e7d98e.jpg',
            telegramUrl: 'https://telegram.dog/cyberboysumanjay',
            xUrl: 'https://x.com/cyberboysj',
            textColor: accentLight,
          ),
          ContactCard(
            name: 'Dhruvan Bhalara',
            subtitle: 'Contributor',
            imageUrl: 'https://avatars1.githubusercontent.com/u/53393418?v=4',
            telegramUrl: 'https://t.me/dhruvanbhalara',
            xUrl: 'https://x.com/dhruvanbhalara',
            textColor: accentLight,
          ),
          ContactCard(
            name: 'Kapil Jhajhria',
            subtitle: 'Contributor',
            imageUrl: 'https://avatars3.githubusercontent.com/u/6892756?v=4',
            telegramUrl: 'https://telegram.dog/kapiljhajhria',
            xUrl: 'https://x.com/kapiljhajhria',
            textColor: accentLight,
          ),
          ContactCard(
            name: 'Kunal Kashyap',
            subtitle: 'App Developer',
            imageUrl: 'https://avatars.githubusercontent.com/u/118793083?v=4',
            telegramUrl: 'https://telegram.dog/NinjaApache',
            xUrl: 'https://x.com/KashyapK257',
            textColor: accentLight,
          ),
        ],
      ),
    );
  }
}
