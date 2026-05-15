import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {

  final Color color;
  const LoadingSpinner({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: CircularProgressIndicator(color: this.color,));
  }
}