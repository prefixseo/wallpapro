import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaperplugin/wallpaperplugin.dart';
import 'package:wallpapro/helper/models.dart';
import 'package:wallpapro/helper/unsplashAPI.dart';
import 'package:http/http.dart' as http;

class SearchWallpaper extends StatefulWidget {
  String searchQuery;
  SearchWallpaper({this.searchQuery});
  @override
  _SearchWallpaperState createState() => _SearchWallpaperState();
}

class _SearchWallpaperState extends State<SearchWallpaper> {
  
  List<Wallpaper> _searchWallpaper = [];

  bool isDownloading = false;
  bool overlayTour = true;
  var _localPathDl = "";
  SwiperController _swiperController = new SwiperController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _CheckOverlayTour();
    _getSearchResults();
  }

  _CheckOverlayTour() async {
    SharedPreferences _session = await SharedPreferences.getInstance();
    bool _isFirstTime = await _session.getBool("overlayTour");
    if(_isFirstTime != null) {
      setState(() {
        overlayTour = _isFirstTime;
      });
    }
  }

  // -- -- CHeck New
  _dissmissSetupTourFirstTime() async {
    SharedPreferences _session = await SharedPreferences.getInstance();
    await _session.setBool('overlayTour', false);
    setState(() {
      overlayTour = false;
    });
  }


  @override
  void dispose() {
    super.dispose();
  }

  // -- Get search results from API
  _getSearchResults() async {
    var _fetch = await http.get(UnsplashAPI()
        .SearchPhotos(Uri.encodeQueryComponent(widget.searchQuery)));
    if (_fetch.statusCode == 200) {
      var deData = json.decode(_fetch.body);
      setState(() {
        for (Map i in deData['results']) {
          if (i['height'] > i['width']) {
            _searchWallpaper.add(Wallpaper.fromJson(i));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFefeeee),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_sharp,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    (_searchWallpaper.length > 0)
                        ? "( " +
                            widget.searchQuery +
                            " ) " +
                            _searchWallpaper.length.toString() +
                            " results"
                        : widget.searchQuery,
                    style: GoogleFonts.lato(
                      fontStyle: FontStyle.italic,
                      fontSize: 18.0,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: (_searchWallpaper.length > 0)
                      ? Swiper(
                          controller: _swiperController,
                          itemBuilder: (BuildContext context, int index) {
                            return InkWell(
                              onTap: () =>
                                  _showModalSheet(_searchWallpaper[index]),
                              child: Stack(
                                children: <Widget>[
                                  CachedNetworkImage(
                                    imageUrl: _searchWallpaper[index].smallUrl,
                                    fit: BoxFit.cover,
                                    height: MediaQuery.of(context).size.height,
                                    progressIndicatorBuilder: (context, url,
                                            downloadProgress) =>
                                        Center(
                                            child: CircularProgressIndicator(
                                                value:
                                                    downloadProgress.progress)),
                                    errorWidget: (context, url, error) =>
                                        Center(child: Icon(Icons.error)),
                                  ),
                                  Positioned(
                                    bottom: 60,
                                    left: 10,
                                    child: Container(
                                      padding: EdgeInsets.all(5.0),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.5),
                                      ),
                                      child: Text(
                                        _searchWallpaper[index]
                                                    .attribution
                                                    .length >
                                                15
                                            ? "By " +
                                                _searchWallpaper[index]
                                                    .attribution
                                                    .substring(0, 15) +
                                                "...."
                                            : "By " +
                                                _searchWallpaper[index]
                                                    .attribution,
                                        style: GoogleFonts.lato(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 30,
                                    right: 10,
                                    child: Container(
                                        padding: EdgeInsets.all(5.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.5),
                                        ),
                                        child: Text(
                                          "♥ " + _searchWallpaper[index].likes,
                                          style: GoogleFonts.lato(
                                              color: Colors.white),
                                        )),
                                  ),
                                ],
                              ),
                            );
                          },
                          itemCount: _searchWallpaper.length,
                          viewportFraction: 1,
                          scale: 1,
                        )
                      : Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
              ],
            ),
            (overlayTour)
                ? Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black.withAlpha(150),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Swipe Left & Right to\nExplore Search Results",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 18.0),
                        ),
                        SizedBox(
                          height: 200.0,
                          width: 200.0,
                          child: Lottie.asset("assets/swipe.json"),
                        ),
                        RaisedButton(
                            child: Text("Got it!",style: GoogleFonts.lato(),),
                            color: Colors.white,
                            onPressed: () => _dissmissSetupTourFirstTime())
                      ],
                    ),
                  )
                : Center(),
          ],
        ),
      ),
    );
  }

  // -- Bottom Modal
  void _showModalSheet(Wallpaper winfo) {
    Future<void> future = showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (builder) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Wrap(
                children: <Widget>[
                  Container(
                    margin:
                        EdgeInsets.only(left: 30.0, right: 30.0, bottom: 70.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xffdcdddd),
                            Color(0xffefeeee),
                          ]),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          offset: Offset(0, 0),
                          blurRadius: 10.0,
                        )
                      ],
                      color: Color(0xFFEFEEEE),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          winfo.description != null ? winfo.description : '',
                          style: GoogleFonts.lato()
                        ),
                        Text(
                          "Published By " + winfo.attribution + " with ♥ Unsplash \n\nDownload & Apply",
                          textAlign: TextAlign.left,
                          textDirection: TextDirection.ltr,
                          style: GoogleFonts.lato()
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        (!isDownloading)
                            ? Column(
                              children: [
                                SizedBox(
                                    width: 200.0,
                                    child: MaterialButton(
                                      onPressed: () {
                                        setState(() {
                                          isDownloading = true;
                                        });
                                        _downloadAndApply(winfo.regularUrl);
                                      },
                                      color: Theme.of(context).primaryColor,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.file_download,
                                            color: Colors.white,
                                          ),
                                          SizedBox(
                                            width: 10.0,
                                          ),
                                          Text(
                                            "Regular HD",
                                            style: GoogleFonts.lato(
                                                color: Colors.white
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                    width: 200.0,
                                    child: MaterialButton(
                                      onPressed: () {
                                        setState(() {
                                          isDownloading = true;
                                        });
                                        _downloadAndApply(winfo.highUrl);
                                      },
                                      color: Theme.of(context).primaryColor,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.file_download,
                                            color: Colors.white,
                                          ),
                                          SizedBox(
                                            width: 10.0,
                                          ),
                                          Text(
                                            "4k High Quality",
                                            style: GoogleFonts.lato(
                                                color: Colors.white
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            )
                            : Container(
                                height: 200,
                                width: 200,
                                child: Lottie.asset("assets/download.json"),
                              )
                      ],
                    ),
                    padding: EdgeInsets.all(20.0),
                  ),
                ],
              );
            },
          );
        });
  }

  static Future<bool> _checkAndGetPermission() async {
    final PermissionStatus permissionStatus = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (permissionStatus != PermissionStatus.granted) {
      final Map<PermissionGroup, PermissionStatus> _permission =
          await PermissionHandler()
              .requestPermissions(<PermissionGroup>[PermissionGroup.storage]);
      if (_permission[PermissionGroup.storage] != PermissionStatus.granted) {
        return null;
      }
    }
    return true;
  }

  _downloadAndApply(dl_url) async {
    // -- todo: Iamge set as wallpaper
    if (_checkAndGetPermission != null) {
      Dio _dio = new Dio();
      final Directory _dir = await getExternalStorageDirectory();
      final Directory _walpaDir =
          await Directory(_dir.path + '/walpadl').create(recursive: true);
      final String imagePath = _walpaDir.path + '/_walpapro.jpeg';

      try {
        await _dio.download(dl_url, imagePath);
        setState(() {
          _localPathDl = imagePath;
        });

        await Wallpaperplugin.setAutoWallpaper(localFile: _localPathDl);
        setState(() {
          isDownloading = false;
        });
        Navigator.pop(context);
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }
}
