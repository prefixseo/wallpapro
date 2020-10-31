import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatelessWidget {
  // -- landing page
  launchLandingPage() async {
    const url = 'https://wallpapro.hellodearcode.com';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About Wallpapro"),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Container(
          margin: EdgeInsets.only(bottom: 35.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => launchLandingPage(),
                child: Center(
                    child: Image.asset(
                      "assets/splash_icon.png",
                      width: 170.0,
                    )),
              ),
              Container(
                margin: EdgeInsets.all(20.0),
                child: Text(
                  "Wallpapro Is free Application with One Tap Download Hd wallpapers and apply into mobile phone Home & Lock Screen. Amazing and User friendly interface which provide Quality Wallpapers for every dimension Smart Phones.",
                  style: GoogleFonts.lato(
                    fontSize: 17.0,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(20.0),
                child: Text(
                  "Wallpapro Contain Daily Basis Up-to-Date Latest Content in every search category. On Home Screen you can choose daily top trending Latest wallpapers. You can also Get Amazing Trending HD wallpapers from Quick Search Categories.",
                  style: GoogleFonts.lato(
                    fontSize: 17.0,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(20.0),
                child: Text(
                  "You can download with only Single Tap on any wallpaper by *Regular HD* (medium file size 1~2mb approx) or *4K High Quality* (High file size 3~4MB+). You Can Choose according to your internet connection easily",
                  style: GoogleFonts.lato(
                    fontSize: 17.0,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
