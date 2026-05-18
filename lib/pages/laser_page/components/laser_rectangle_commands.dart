// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/components/laser_all_points_setted_led.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:unicons/unicons.dart';

class LaserRectangleCommands extends StatefulWidget {
  final LaserPageController controller;
  final Stopwatch stopwatch;
  bool canMoveRobot = false;

  final Point posizioneRobot;

  LaserRectangleCommands(
      {super.key, required this.controller,
      required this.canMoveRobot,
      required this.stopwatch,
      required this.posizioneRobot});

  @override
  State<LaserRectangleCommands> createState() => _LaserRectangleCommandsState();
}

class _LaserRectangleCommandsState extends State<LaserRectangleCommands> {
  bool filoIsPressed = false;
  bool gasIsPressed = false;

  final double leftSpace = 16;
  final double bottomDelta = 12;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          if (filoIsPressed)
            Positioned(
                child: Align(
              alignment: Alignment.center,
              child: Text("PROVA FILO IN CORSO",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            )),
          if (gasIsPressed)
            Positioned(
                child: Align(
              alignment: Alignment.center,
              child: Text("PROVA GAS IN CORSO",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            )),
          Positioned(
            left: leftSpace,
            bottom: 170 + bottomDelta,
            child: Listener(
                key: GlobalKey(),
                onPointerDown: (details) {
                  mySetState(() {
                    filoIsPressed = true;
                  });
                  widget.controller.filoTouchedDown();
                },
                onPointerUp: (details) {
                  mySetState(() {
                    filoIsPressed = false;
                  });
                  widget.controller.filoTouchedUp();
                },
                onPointerCancel: (details) {
                  mySetState(() {
                    filoIsPressed = false;
                  });
                  widget.controller.filoTouchedUp();
                },
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: filoIsPressed ? Colors.yellow : AppColors.sagaBlue,
                    ),
                    width: 30,
                    height: 30,
                    child: Icon(UniconsLine.drill))),
          ),
          Positioned(
            left: leftSpace,
            bottom: 125 + bottomDelta,
            child: Listener(
                key: GlobalKey(),
                onPointerDown: (details) {
                  mySetState(() {
                    gasIsPressed = true;
                  });
                  widget.controller.gasTouchedDown();
                },
                onPointerCancel: (details) {
                  mySetState(() {
                    gasIsPressed = false;
                  });
                  widget.controller.gasTouchedUp();
                },
                onPointerUp: (details) {
                  mySetState(() {
                    gasIsPressed = false;
                  });
                  widget.controller.gasTouchedUp();
                },
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: gasIsPressed ? Colors.yellow : AppColors.sagaBlue,
                    ),
                    width: 30,
                    height: 30,
                    child: Icon(UniconsLine.sanitizer))),
          ),
          Positioned(
            left: leftSpace + 3,
            bottom: 90 + bottomDelta,
            child: LaserAllPointsSettedLED(controller: widget.controller),
          ),
          Positioned(
              left: leftSpace,
              bottom: 50 + bottomDelta,
              child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: widget.canMoveRobot ? Colors.green : Colors.red,
                  ),
                  width: 30,
                  height: 30,
                  child: Icon(UniconsLine.expand_arrows))),
          Positioned(
              left: leftSpace,
              bottom: 10 + bottomDelta,
              child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: widget.controller.laserStatus
                        ? Colors.red
                        : Colors.grey,
                  ),
                  width: 30,
                  height: 30,
                  child: Icon(Icons.data_thresholding_outlined))),
        ],
      ),
    );
  }

  void mySetState(VoidCallback? f) {
    if (f == null) return;
    if (mounted) {
      setState(f);
    }
  }
}
