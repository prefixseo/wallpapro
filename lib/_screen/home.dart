import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallpaperplugin/wallpaperplugin.dart';
import 'package:wallpapro/_screen/_about.dart';
import 'package:wallpapro/_screen/_search.dart';
import 'package:wallpapro/customHeaderCLipper.dart';
import 'package:wallpapro/helper/unsplashAPI.dart';
import 'package:wallpapro/helper/models.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Wallpaper> _latestWallpaper = [];
  final GlobalKey _menuKey = new GlobalKey();
  SwiperController _swiperController = new SwiperController();
  var _searchBoxController = new TextEditingController();

  var _localPathDl = "";
  bool isDownloading = false;

  var tagsList = [
    "Animal",
    "Artistic",
    "Fruit",
    "Food",
    "Flower",
    "Gaming",
    "Gradients",
    "Nature",
    "Office",
    "People",
    "Photography",
    "Sports",
    "Travel"
  ];

  @override
  void initState() {
    _getFeatured();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Color(0xFFefeeee),
        body: (_latestWallpaper.length > 0)
            ? InkWell(
              onTap: (){
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus) {
                  currentFocus.unfocus();
                }
              },
              child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _topHeaderSearchBox(),
                      SizedBox(
                        height: 15.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 32.0,
                            color: Color(0x55ff5467),
                          ),
                          _titleBox("Popular Categories"),
                        ],
                      ),
                      QuickSearch(),
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 32.0,
                            color: Color(0x55ff5467),
                          ),
                          _titleBox("Trending Wallpapers"),
                        ],
                      ),
                      (_latestWallpaper.length > 0)
                          ? Expanded(child: latestWallpapers())
                          : Center(child: CircularProgressIndicator()),
                      SizedBox(
                        height: 40.0,
                      ),
                    ],
                  ),
                ),
            )
            : Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff768591), Color(0xffffffff)],
                  stops: [0.2, 0.7],
                )),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/splash_icon.png'),
                      SizedBox(
                        height: 10.0,
                      ),
                      SizedBox(
                        height: 200.0,
                        width: 200.0,
                        child: Lottie.asset("assets/splash_loading.json"),
                      )
                    ],
                  ),
                ),
              ));
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

  _getFeatured() async {
    var _fetch = await http.get(UnsplashAPI().LatestPhotos());
    if (_fetch.statusCode == 200) {
      var deData = json.decode(_fetch.body);
      setState(() {
        for (Map i in deData) {
          if (i['height'] > i['width']) {
            _latestWallpaper.add(Wallpaper.fromJson(i));
          }
        }
      });
    }
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
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  // -- Bottom Modal
  void _showModalSheet(Wallpaper winfo) {
    if (_swiperController.hasListeners) {
      _swiperController.stopAutoplay();
    }
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
                          style: GoogleFonts.lato(),
                        ),
                        Text(
                          "Published By " +
                              winfo.attribution +
                              " with ♥ Unsplash \n\nDownload & Apply",
                          textAlign: TextAlign.left,
                          textDirection: TextDirection.ltr,
                          style: GoogleFonts.lato(),
                        ),
                        SizedBox(
                          height: 20.0,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                                color: Colors.white),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                                color: Colors.white),
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
    future.then((void value) => _closeModal(value));
  }

  void _closeModal(void value) {
    if (_swiperController.hasListeners) {
      _swiperController.startAutoplay();
    }
  }

  Widget _titleBox(_title) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.0),
      child: Text(
        _title,
        style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontSize: 20.0),
      ),
    );
  }

  // -- latest
  Widget latestWallpapers() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Swiper(
        controller: _swiperController,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () => _showModalSheet(_latestWallpaper[index]),
            child: Stack(
              children: <Widget>[
                Container(
                  width: 220.0,
                  height: 300.0,
                  margin: EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: Offset(3.0, 3.0),
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: CachedNetworkImage(
                      imageUrl: _latestWallpaper[index].smallUrl,
                      fit: BoxFit.cover,
                      width: 220.0,
                      height: 300,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                              child: CircularProgressIndicator(
                                  value: downloadProgress.progress)),
                      errorWidget: (context, url, error) =>
                          Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 10,
                  child: Container(
                      padding: EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                      child: Text(
                        "♥ " + _latestWallpaper[index].likes,
                        style: GoogleFonts.lato(color: Colors.white),
                      )
                  ),
                ),
              ],
            ),
          );
        },
        itemCount: _latestWallpaper.length,
        autoplay: true,
        viewportFraction: 0.4,
        scale: 0.5,
      ),
    );
  }

  // -- Quick Search
  Widget QuickSearch() {
    return Container(
      height: 110.0,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: tagsList.isNotEmpty ? tagsList.length : 0,
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        SearchWallpaper(searchQuery: tagsList[index])),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  height: 70.0,
                  width: 220.0,
                  margin: EdgeInsets.all(15.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: CachedNetworkImage(
                      imageUrl: "https://source.unsplash.com/220x70/?" +
                          tagsList[index].toString(),
                      fit: BoxFit.fill,
                      height: MediaQuery.of(context).size.width,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                              child: CircularProgressIndicator(
                                  value: downloadProgress.progress)),
                      errorWidget: (context, url, error) =>
                          Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
                Positioned(
                  child: Container(
                    height: 70.0,
                    width: 220.0,
                    margin: EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: Theme.of(context).primaryColor.withAlpha(130),
                    ),
                    child: Center(),
                  ),
                ),
                Text(
                  tagsList[index].toString().toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _topHeaderSearchBox() {
    return Stack(
      children: [
        ClipPath(
          clipper: CustomHeaderClipper(),
          child: Container(
            child: CachedNetworkImage(
              imageUrl: "https://source.unsplash.com/400x130/?tree,garden,scene",
              fit: BoxFit.fill,
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  Center(
                      child: CircularProgressIndicator(
                          value: downloadProgress.progress)),
              errorWidget: (context, url, error) =>
                  Center(child: Icon(Icons.error)),
            ),
          ),
        ),
        Positioned(
          child: ClipPath(
            clipper: CustomHeaderClipper(),
            child: Container(
              height: 117.0,
              color: Theme.of(context).primaryColor.withAlpha(130),
              child: Center(),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 5.0),
          child: InkWell(
            onTap: () => launchLandingPage(),
            child: Center(
                child: Image.asset(
              "assets/splash_icon.png",
              width: 70.0,
            )),
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            top: 90.0,
            right: 20.0,
            left: 20.0,
          ),
          child: Stack(
            children: [
              Material(
                elevation: 20.0,
                shadowColor: Theme.of(context).primaryColor,
                child: TextField(
                  controller: _searchBoxController,
                  autofocus: false,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),
                    border: InputBorder.none,
                    hintText: "Search By Keyword",
                    hintStyle: TextStyle(
                        color: Theme.of(context).primaryColor.withOpacity(0.6)),
                  ),
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.lato(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16.0,
                  ),
                  onChanged: (query) {},
                  onSubmitted: (w) {
                    _searchBoxController.clear();
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                    if (w.length > 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SearchWallpaper(searchQuery: w)),
                      );
                    }
                  },
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.search,
                    color: Color(0xffff5467),
                  ),
                  onPressed: () {
                    String _qq = _searchBoxController.value.text;
                    _searchBoxController.clear();

                    FocusScopeNode currentFocus = FocusScope.of(context);

                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }

                    if (_qq.length > 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SearchWallpaper(searchQuery: _qq)),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 10,
          top: 20,
          child: IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              Share.share(
                "Hey, I am Using WallpaPro\nYou can also Download and Get Free HD Wallpapers with One Tap \n https://play.google.com/store/apps/details?id=com.hellodearcode.wallpapro",
                subject: "Wallpapro HD mobile backgrounds app",
              );
            },
          ),
        ),
        Positioned(
          left: 10,
          top: 20,
          child: PopupMenuButton<String>(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: 28,
            ),
            onSelected: (c) {
              switch (c) {
                case 'About':
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) =>
                            About()
                    ),
                  );
                  break;
                case 'Rate Us':
                  launchRateUs();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'About', 'Rate Us'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(
                    choice,
                    style: GoogleFonts.lato(),
                  ),
                );
              }).toList();
            },
          ),
        )
      ],
    );
  }

  // -- landing page
  launchLandingPage() async {
    const url = 'https://www.prefixseo.com';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // -- rate us
  launchRateUs() async {
    const url =
        'market://details?id=com.hellodearcode.wallpapro&showAllReviews=true';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
