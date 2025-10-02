import 'package:flutter/material.dart';
import 'package:Musify/style/appColors.dart';
import 'package:Musify/ui/homePage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() async {
  runApp(
    MaterialApp(
      theme: ThemeData(
        fontFamily: "DMSans",
        colorScheme: ColorScheme.fromSeed(seedColor: accent),
        primaryColor: accent,
        canvasColor: Colors.transparent,
      ),
      home: Musify(),
      builder: EasyLoading.init(),
    ),
  );
}
