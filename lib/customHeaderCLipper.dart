import 'package:flutter/cupertino.dart';

class CustomHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height);
    path.quadraticBezierTo(size.width / 4, size.height-20,        size.width / 2, size.height-20);
    path.quadraticBezierTo(size.width - (size.width / 4), size.height-20,        size.width, size.height - 0);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}