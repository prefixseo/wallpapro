import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallpaperplugin/wallpaperplugin.dart';
import 'package:wallpapro/_screen/_search.dart';
import 'package:wallpapro/customHeaderCLipper.dart';
import 'package:wallpapro/helper/AdsManager.dart';
import 'package:wallpapro/helper/unsplashAPI.dart';
import 'package:wallpapro/helper/models.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Wallpaper> _latestWallpaper = new List<Wallpaper>();
  final GlobalKey _menuKey = new GlobalKey();
  SwiperController _swiperController = new SwiperController();
  var _searchBoxController = new TextEditingController();

  var _localPathDl = "";
  bool isDownloading = false;

  // -- todo: ad init
  static const MobileAdTargetingInfo _mobileAdTargetingInfo =
      MobileAdTargetingInfo(
          testDevices: AdsManager.testDevice != null
              ? <String>[AdsManager.testDevice]
              : null,
          nonPersonalizedAds: true,
          keywords: <String>[
        'earn wallpaper',
        'money wallpaper',
        'gaming wallpaper',
        'wallpaper',
        'hd',
        'android wallpaper',
        'hd wallpaper'
      ]);

  // -- todo: banner ad
  BannerAd _bannerAd;
  BannerAd createBannerAd() {
    return BannerAd(
        adUnitId: AdsManager.bannerAdId,
        size: AdSize.banner,
        targetingInfo: _mobileAdTargetingInfo,
        listener: (MobileAdEvent event) {
          print("MobileAdEvent $event");
        });
  }

  // -- todo interstitial ad
  InterstitialAd _interstitialAd;
  InterstitialAd createFullAd() {
    return InterstitialAd(
        adUnitId: AdsManager.InterstitialAdId,
        targetingInfo: _mobileAdTargetingInfo,
        listener: (MobileAdEvent e) {
          print("InterAdEve $e");
        });
  }

  var tagsList = [
    "Animal",
    "Artistic",
    "Super Bike",
    "Car",
    "Color",
    "Event",
    "Fruit",
    "Food",
    "Flower",
    "Feeling",
    "Gaming",
    "Gradients",
    "Inspirational",
    "Nature",
    "Office",
    "People",
    "Photography",
    "Religion",
    "Sports",
    "Travel"
  ];

  @override
  void initState() {
    FirebaseAdMob.instance.initialize(appId: AdsManager.appId);
    _bannerAd = createBannerAd()
      ..load()
      ..show();
    _getFeatured();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    if (_bannerAd != null) {
      _bannerAd.dispose();
    }
    if (_interstitialAd != null) {
      _interstitialAd.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFefeeee),
        body: (_latestWallpaper.length > 0)
            ? Column(
                children: [
                  Expanded(
                    child: ListView(children: <Widget>[
                      _topHeaderSearchBox(),
                      SizedBox(
                        height: 40.0,
                      ),
                      _titleBox("Latest Wallpapers"),
                      (_latestWallpaper.length > 0)
                          ? latestWallpapers()
                          : Center(child: CircularProgressIndicator()),
                      SizedBox(
                        height: 20.0,
                      ),
                      _titleBox("Quick Categories"),
                      SizedBox(
                        height: 20.0,
                      ),
                      QuickSearch(),
                      SizedBox(
                        height: 50.0,
                      ),
                    ]),
                  ),
                ],
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
        Navigator.pop(context);
        _interstitialAd = await createFullAd()
          ..load()
          ..show();
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
                          style: TextStyle(
                            fontFamily: "ArchitectsDaughter",
                          ),
                        ),
                        Text(
                          "Uploaded By: " + winfo.attribution + " with ♥ Love",
                          textAlign: TextAlign.left,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: "ArchitectsDaughter",
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        (!isDownloading)
                            ? SizedBox(
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
                                        "Download & Apply",
                                        style: TextStyle(
                                            fontFamily: "ArchitectsDaughter",
                                            color: Colors.white),
                                      )
                                    ],
                                  ),
                                ),
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
      margin: EdgeInsets.symmetric(horizontal: 25.0),
      child: Text(
        _title,
        style: TextStyle(
            fontFamily: 'ArchitectsDaughter',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontSize: 24.0),
      ),
    );
  }

  // -- latest
  Widget latestWallpapers() {
    return Container(
      height: 380,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Swiper(
        controller: _swiperController,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () => _showModalSheet(_latestWallpaper[index]),
            child: Stack(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(1.0),
                  margin: EdgeInsets.symmetric(vertical: 15.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: Offset(3.0, 3.0),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: CachedNetworkImage(
                      imageUrl: _latestWallpaper[index].smallUrl,
                      fit: BoxFit.fill,
                      height: 380,
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
                  bottom: 30,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                    child: Text(
                      _latestWallpaper[index].attribution.length > 15
                          ? "By " +
                              _latestWallpaper[index]
                                  .attribution
                                  .substring(0, 15) +
                              "...."
                          : "By " + _latestWallpaper[index].attribution,
                      style: TextStyle(
                          fontFamily: "ArchitectsDaughter",
                          color: Colors.white),
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
                        style: TextStyle(
                            fontFamily: "ArchitectsDaughter",
                            color: Colors.white),
                      )),
                ),
              ],
            ),
          );
        },
        itemCount: _latestWallpaper.length,
        autoplay: true,
        viewportFraction: 0.7,
        scale: 0.7,
      ),
    );
  }

  // -- Quick Search
  Widget QuickSearch() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: tagsList.isNotEmpty ? tagsList.length : 0,
      physics: BouncingScrollPhysics(),
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
                height: 160.0,
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: CachedNetworkImage(
                    imageUrl: "https://source.unsplash.com/400x150/?" +
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
                  height: 130.0,
                  margin: EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 0), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Center(),
                ),
              ),
              Text(
                tagsList[index].toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 24.0,
                  fontFamily: 'ArchitectsDaughter',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _topHeaderSearchBox() {
    return Stack(
      children: [
        ClipPath(
          clipper: CustomHeaderClipper(),
          child: Container(
            child: CachedNetworkImage(
              imageUrl: "https://source.unsplash.com/400x250/?nature",
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
              height: 225.0,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    spreadRadius: 0,
                    blurRadius: 0,
                    offset: Offset(0, 0), // changes position of shadow
                  ),
                ],
              ),
              child: Center(),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 60.0),
          child: Center(
            child: Text(
              "Wallpapro",
              style: TextStyle(
                fontSize: 32.0,
                fontFamily: 'ArchitectsDaughter',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          margin: EdgeInsets.only(top: 180.0, right: 20.0, left: 20.0),
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
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16.0,
                    fontFamily: 'ArchitectsDaughter',
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
                    color: Theme.of(context).primaryColor,
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
          child: IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.white,
              size: 32.0,
            ),
            onPressed: () {
              Share.share(
                "Hey, I am Using WallpaPro best wallpaper One Tap Download and Apply Application\nYou can also Download and Get Free HD Wallpapers with One Tap \n https://play.google.com/store/apps/details?id=com.hellodearcode.wallpapro",
                subject: "Wallpapro HD mobile backgrounds app",
              );
            },
          ),
        ),
        Positioned(
          left: 10,
          child: PopupMenuButton<String>(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: 32,
            ),
            onSelected: (c) {
              switch (c) {
                case 'About':
                  launchLandingPage();
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
                  child: Text(choice),
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
    const url = 'https://wallpapro.hellodearcode.com';
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
