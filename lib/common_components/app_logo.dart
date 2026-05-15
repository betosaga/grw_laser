import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: size,
        width: size,
        child: Image.asset('images/reports-appbar.png'));
  }
}
