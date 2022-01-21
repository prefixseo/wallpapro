import 'dart:io';
import 'dart:typed_data';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:toast/toast.dart';

class Editor extends StatefulWidget {
  File fileImage;

  Editor({Key key, this.fileImage}) : super(key: key);

  @override
  _EditorState createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  Offset offset = Offset.zero;
  Offset creditsOffset = Offset.zero;
  TextEditingController _textInputController = TextEditingController();
  TextEditingController _creditsController = TextEditingController();
  GlobalKey _captureglobalKey = new GlobalKey();
  Uint8List imageInMemory;
  bool working = false;
  String creditsText = "Follow @cactus_rajput";

  // -- Settings
  double _fontSize = 24.0;
  String _fontFamily = "";
  String _text = "";
  double _opacity = 0.5;

  bool isSaving = false;

  bool colorPickerToggle = false;

  Color pickerColor = Color(0xffffffff);
  Color currentColor = Color(0xffffffff);

  final _controller = CircleColorPickerController(
    initialColor: Colors.yellow,
  );

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  void initState() {
    _creditsController.text = creditsText;
    creditsOffset = Offset(40, 220);
  }

  // -- Show Text Input
  showTextInput() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("Enter Multiline Text"),
            content: SingleChildScrollView(
                child: TextField(
              keyboardType: TextInputType.multiline,
              controller: _textInputController,
              maxLines: 5,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter Text on Image",
                  labelText: "Text On Image"),
              style: TextStyle(fontSize: 16.0),
            )),
            actions: [
              TextButton(
                child: const Text('Done'),
                onPressed: () {
                  setState(() => _text = _textInputController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  // -- focus remover
  _removeFocus() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  // -- download in downloads gallery
  downloadIntoGallery() async {
    RenderRepaintBoundary boundary =
        _captureglobalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    final file_name = DateTime.now().millisecondsSinceEpoch;
    final path = '/storage/emulated/0/Download';
    final checkPathExistence = await Directory(path).exists();
    // -- directory creation and file save
    if (!checkPathExistence) {
      await Directory(path).create(recursive: true);
    }
    File file = File(path + '/' + file_name.toString() + ".png");
    file.writeAsBytesSync(pngBytes);
    setState(() {
      isSaving = true;
    });
    Toast.show(
      "Post Exported To Gallery",
      context,
      gravity: Toast.CENTER,
      duration: Toast.LENGTH_LONG,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
    );
  }

  // -- Generate Image
  _capturensharePng() async {
    try {
      imageCache.clear();
      setState(() {
        working = false;
      });

      RenderRepaintBoundary boundary =
          _captureglobalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      setState(() {
        working = false;
      });
      // share Image
      await Share.file(
          'Social Post By freeimagetotext.com', 'freeimagetotext_com.png', pngBytes, 'image/png',
          text: "Hey, I am Using HD Real Wallpapers App\nYou can also Download and Get Free HD Wallpapers with One Tap\n\nYou Can Also Edit them to make social Media Post For Whatsapp, Insta, Facebook, Twitter \n https://play.google.com/store/apps/details?id=com.hellodearcode.wallpapro",
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('Post Editor'),
          actions: [
            (_textInputController.text.length > 1)
                ? IconButton(
                    color: Colors.white.withAlpha(50),
                    onPressed: _capturensharePng,
                    icon: Icon(Icons.share, color: Colors.white),
                  )
                : Center(),
            (_textInputController.text.length > 1)
                ? (!isSaving) ? IconButton(
                    color: Colors.white.withAlpha(50),
                    onPressed: () {
                      setState(() {
                        isSaving = true;
                      });
                      downloadIntoGallery();
                    },
                    icon: Icon(Icons.save_alt, color: Colors.white),
                  ) : CircularProgressIndicator()
                : Center()
          ],
        ),
        body: GestureDetector(
          onTap: _removeFocus,
          child: Column(
            children: [
              Container(
                height: 400,
                  child: RepaintBoundary(
                key: _captureglobalKey,
                child: Stack(
                  children: [
                    Image.file(
                      widget.fileImage,
                      width: MediaQuery.of(context).size.width,
                      height: 400.0,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 400.0,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(_opacity),
                      ),
                      child: Center(),
                    ),
                    Container(
                      child: Positioned(
                        left: offset.dx,
                        top: offset.dy,
                        child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                offset = Offset(offset.dx + details.delta.dx,
                                    offset.dy + details.delta.dy);
                              });
                            },
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 50,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(_text,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: _fontSize,
                                          color: pickerColor,
                                          fontFamily: _fontFamily)),
                                ),
                              ),
                            )),
                      ),
                    ),
                    Positioned(
                        left: creditsOffset.dx,
                        top: creditsOffset.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              creditsOffset = Offset(
                                  creditsOffset.dx + details.delta.dx,
                                  creditsOffset.dy + details.delta.dy);
                            });
                          },
                          child: Text(
                            creditsText,
                            style: TextStyle(
                                color: Color(0x44ffffff), fontSize: 20.0),
                          ),
                        ))
                  ],
                ),
              )),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Center(
                            child: TextButton(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.g_translate_rounded,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 5.0,
                                  ),
                                  Text("Enter Text Here",
                                      style: TextStyle(color: Colors.white))
                                ],
                              ),
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Theme.of(context).primaryColor),
                              ),
                              onPressed: () => showTextInput(),
                            ),
                          ),
                        ],
                      ),
                      (_text.length > 1)
                          ? Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Size"),
                                      Expanded(
                                        child: Slider(
                                            activeColor:
                                                Theme.of(context).primaryColor,
                                            inactiveColor: Theme.of(context)
                                                .primaryColor
                                                .withAlpha(100),
                                            value: _fontSize,
                                            min: 12.0,
                                            max: 72.0,
                                            onChanged: (_size) {
                                              _removeFocus();
                                              setState(() {
                                                _fontSize = _size;
                                              });
                                            }),
                                      ),
                                      _opacityMenuButton(),
                                    ],
                                  ),
                                  Center(
                                      child: CircleColorPicker(
                                    controller: _controller,
                                    onChanged: (c) => changeColor(c),
                                  ))
                                ],
                              ),
                            )
                          : Center(),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(
                        " -- Credits Setting -- ",
                        style: TextStyle(
                            color: Theme.of(context).primaryColor.withAlpha(150)),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        height: 70.0,
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextField(
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          keyboardType: TextInputType.multiline,
                          controller: _creditsController,
                          maxLength: 25,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  _removeFocus();
                                  setState(() {
                                    creditsText = _creditsController.text;
                                  });
                                },
                                icon: Icon(Icons.check,
                                    size: 28,
                                    color: Theme.of(context).primaryColor),
                              )),
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                    ],
                  ),
                ),
              ),
              !working
                  ? Center()
                  : Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: Colors.black.withAlpha(120),
                      child: Center(child: CircularProgressIndicator()))
            ],
          ),
        ));
  }

  // -- -- Color Button
  Widget _opacityMenuButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.opacity,
        color: Theme.of(context).primaryColor,
        size: 28,
      ),
      onSelected: (c) {
        _removeFocus();
        double x = double.parse(c);
        setState(() {
          _opacity = x;
        });
      },
      itemBuilder: (BuildContext context) {
        return {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0}.map((choice) {
          return PopupMenuItem<String>(
            value: choice.toString(),
            height: 30.0,
            child: Center(
              child: Text(choice.toString().replaceAll(".", "")),
            ),
          );
        }).toList();
      },
    );
  }
}
