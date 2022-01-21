import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallpaperplugin/wallpaperplugin.dart';
import 'package:wallpapro/_screen/_about.dart';
import 'package:wallpapro/_screen/_editor.dart';
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
  var _keyword = ["tree", "garden", "scene", "sunset", "people", "fireworks"];
  var rng = new Random();

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
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
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
                        height: 30.0,
                      ),
                      SizedBox(
                        height: 60.0,
                        width: 60.0,
                        child: CircularProgressIndicator(
                          color: Color(0xffFFE162),
                          backgroundColor: Color(0xffff5467),
                        ),
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

  _downloadAndApply(dl_url , isEditor) async {
    // -- todo: Iamge set as wallpaper
    if (_checkAndGetPermission != null) {
      Dio _dio = new Dio();
      final Directory _dir = await getExternalStorageDirectory();
      final Directory _walpaDir =
          await Directory(_dir.path + '/walpadl').create(recursive: true);
      final String imagePath = _walpaDir.path + '/_walpapro.jpeg';

      try {
        await _dio.download(dl_url, imagePath);

        if(!isEditor){
          await Wallpaperplugin.setAutoWallpaper(localFile: imagePath);

          setState(() {
            isDownloading = false;
          });
          Navigator.pop(context);
        }else{
          setState(() {
            isDownloading = false;
          });
          // -- Move to Editor
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Editor(
                        fileImage: File(imagePath),
                      )));
        }

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
    Future<void> future = showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Wrap(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      child: (!isDownloading)
                              ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Apply Wallpaper",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                fontSize: 22.0, color: Color(0xffFF6363)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      isDownloading = true;
                                    });
                                    _downloadAndApply(winfo.regularUrl,false);
                                  },
                                  icon: Icon(Icons.download,
                                      color: Color(0xffFFAB76)),
                                  label: Text(
                                    'HD',
                                    style: GoogleFonts.lato(
                                        color: Color(0xffFFAB76)),
                                  )),
                              TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      isDownloading = true;
                                    });
                                    _downloadAndApply(winfo.highUrl,false);
                                  },
                                  icon: Icon(Icons.download,
                                      color: Color(0xffFF6363)),
                                  label: Text(
                                    "4K",
                                    style: GoogleFonts.lato(
                                        color: Color(0xffFF6363)),
                                  )),
                            ],
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Text(
                            "Edit & Share",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                fontSize: 22.0, color: Color(0xffFFAB76)),
                          ),
                          TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  isDownloading = true;
                                });
                                _downloadAndApply(winfo.regularUrl,true);
                              },
                              icon: Icon(Icons.edit),
                              label: Text("Open Editor")),
                          SizedBox(
                            height: 10.0,
                          ),
                          Divider(
                            color: Colors.black,
                          ),
                          (winfo.description != null)
                              ? Text(
                                  winfo.description,
                                  style: GoogleFonts.lato(),
                                )
                              : Center(),
                          Text(
                            "Published By " +
                                winfo.attribution +
                                " with ♥ Unsplash",
                            textAlign: TextAlign.left,
                            style: GoogleFonts.lato(),
                          ),
                          TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.close,
                                color: Colors.red,
                              ),
                              label: Text(
                                "Cancel",
                                style:
                                    GoogleFonts.lato(color: Color(0xffFF6363)),
                              )),
                        ],
                      )
                      : 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Downloading....",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                fontSize: 22.0, color: Color(0xffFF6363)),
                          ),
                          CircularProgressIndicator()
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
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
                  width: 240.0,
                  height: 320.0,
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
                      )),
                ),
              ],
            ),
          );
        },
        itemCount: _latestWallpaper.length,
        autoplay: true,
        viewportFraction: 0.5,
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
                  height: 100.0,
                  width: 240.0,
                  margin: EdgeInsets.all(10.0),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        "https://source.unsplash.com/220x70/?" +
                            tagsList[index].toString(),
                        fit: BoxFit.fill,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes
                                  : null,
                            ),
                          );
                        },
                      )),
                ),
                Text(
                  tagsList[index].toString().toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 20.0,
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(1.0, 0),
                        blurRadius: 10.0,
                        color: Color(0xffff5467),
                      ),
                    ],
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
              useOldImageOnUrlChange: false,
              imageUrl: "https://source.unsplash.com/400x130/?" +
                  _keyword[rng.nextInt(_keyword.length - 1)],
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
                borderRadius: BorderRadius.circular(10),
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
                "Hey, I am Using HD Real Wallpapers App\nYou can also Download and Get Free HD Wallpapers with One Tap\n\nYou Can Also Edit them to make social Media Post For Whatsapp, Insta, Facebook, Twitter \n https://play.google.com/store/apps/details?id=com.hellodearcode.wallpapro",
                subject: "HD Real Wallpapers",
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
                    CupertinoPageRoute(builder: (context) => About()),
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
