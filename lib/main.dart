import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallpapro/_screen/home.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xff768591)
  ));
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Wallpapro",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xff768591),
      ),
      home: Home(),
    );
  }
}
