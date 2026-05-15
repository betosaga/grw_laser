import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserLogWindow extends StatefulWidget {
  final LaserPageController controller;
  LaserLogWindow({required this.controller});

  final double windowWidth = 450.0;
  final double windowHeight = 300.0;

  @override
  State<LaserLogWindow> createState() => _LaserLogWindowState();
}

class _LaserLogWindowState extends State<LaserLogWindow> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.controller.logWindowTopPosition,
      left: widget.controller.logWindowLeftPosition,
      width: widget.windowWidth,
      height: widget.windowHeight,
      child: Draggable(
        feedback: Container(),
        onDragUpdate: (details) {
          final currentX = widget.controller.logWindowLeftPosition;
          final currentY = widget.controller.logWindowTopPosition;

          final newCurrentX =
              widget.controller.logWindowLeftPosition + details.delta.dx;
          final newCurrentY =
              widget.controller.logWindowTopPosition + details.delta.dy;

          final finalX = newCurrentX > 0 &&
                  newCurrentX + widget.windowWidth <
                      MediaQuery.sizeOf(context).width
              ? newCurrentX
              : currentX;
          final finalY = newCurrentY > 32 &&
                  newCurrentY + widget.windowHeight <
                      MediaQuery.sizeOf(context).height
              ? newCurrentY
              : currentY;

          mySetState(() {
            widget.controller.logWindowLeftPosition = finalX;
            widget.controller.logWindowTopPosition = finalY;
          });
        },
        onDragEnd: (details) {
          final currentX = widget.controller.logWindowLeftPosition;
          final currentY = widget.controller.logWindowTopPosition;

          final newCurrentX = details.offset.dx;
          final newCurrentY =
              details.offset.dy - View.of(context).viewPadding.top - 32;

          final finalX = newCurrentX > 0 &&
                  newCurrentX + widget.windowWidth <
                      MediaQuery.sizeOf(context).width
              ? newCurrentX
              : currentX;
          final finalY = newCurrentY > 32 &&
                  newCurrentY + widget.windowHeight <
                      MediaQuery.sizeOf(context).height
              ? newCurrentY
              : currentY;

          mySetState(() {
            widget.controller.logWindowLeftPosition = finalX;
            widget.controller.logWindowTopPosition = finalY;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            width: widget.windowWidth,
            height: widget.windowHeight,
            decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                border: Border.all(color: AppColors.sagaBlue, width: 8),
                borderRadius: BorderRadius.circular(10.0)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.controller.logString,
                style: TextStyle(color: Colors.green),
              ),
            ),
          ),
        ),
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
