import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserSimulationPage extends StatelessWidget {
  //
  //
  //
  final String textToShow;
  const LaserSimulationPage({required this.textToShow});
  //
  //
  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Listener(
            onPointerDown: (_) => Vibrator.shortVibration(),
            child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_sharp,
              color: Colors.white,
            ),
            onPressed: () => Pager.pop(context),
          )),
          backgroundColor: AppColors.sagaBlue,
          title: Text(
            "SIMULAZIONE",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              child: Text(textToShow),
            ),
          ),
        ));
  }
}
