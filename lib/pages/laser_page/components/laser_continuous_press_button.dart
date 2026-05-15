import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/vibrator.dart';

class ContinuousPressButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final BorderRadius radius;
  final bool locked;
  final bool limited;
  final bool onlyLongPress;
  final String? stepLabel;
  final bool showLabelOnTop;

  ContinuousPressButton.LaserContinuousPressButton({
    required this.icon,
    required this.onPressed,
    required this.locked,
    this.limited = false,
    this.radius = BorderRadius.zero,
    this.onlyLongPress = false,
    this.stepLabel,
    this.showLabelOnTop = false,
  });

  @override
  _ContinuousPressButtonState createState() => _ContinuousPressButtonState();
}

class _ContinuousPressButtonState extends State<ContinuousPressButton> {
  bool buttonPressed = false;

  Timer? _timer;

  void _startTimer() {
    //print('Timer started for direction: ${widget.direction}');
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      // print('Timer tick for direction: ${widget.direction}');
      widget.onPressed();
    });
  }

  void _stopTimer() {
    //print('Timer stopped for direction: ${widget.direction}');
    _timer?.cancel();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        (buttonPressed || widget.limited) ? Colors.white : AppColors.sagaBlue;

    return GestureDetector(
      onLongPressCancel: () {
        mySetState(() {
          buttonPressed = false;
        });
      },
      onTapUp: (details) {
        mySetState(() {
          buttonPressed = false;
        });
      },
      onTapDown: (details) {
        mySetState(() {
          buttonPressed = true;
        });
      },
      onLongPress: () {
        mySetState(() {
          buttonPressed = true;
        });
        Vibrator.mediumVibration();
        _startTimer();
        widget.onPressed();
      },
      onLongPressEnd: (details) {
        mySetState(() {
          buttonPressed = false;
        });
        // print('onLongPressEnd for direction: ${widget.direction}');
        _stopTimer();
      },
      onLongPressUp: () {
        mySetState(() {
          buttonPressed = false;
        });
        // print('onLongPressEnd for direction: ${widget.direction}');
        _stopTimer();
      },
      onLongPressDown: (detail) {
        mySetState(() {
          buttonPressed = true;
        });
      },
      onTap: widget.onlyLongPress
          ? null
          : () {
              Vibrator.shortVibration();
              widget.onPressed();
            },
      onTapCancel: () {
        mySetState(() {
          buttonPressed = false;
        });
      },
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
            color: (widget.locked || buttonPressed)
                ? Color(0xFFA1A1A1)
                : (widget.limited
                    ? const Color(0xFF6254BB)
                    : AppColors.lightGray),
            shape: BoxShape.rectangle,
            borderRadius: widget.radius),
        child: Stack(
          children: [
            Center(
              child: Icon(widget.icon, color: iconColor),
            ),
            if (widget.stepLabel != null)
              Positioned(
                top: widget.showLabelOnTop ? 4 : null,
                bottom: widget.showLabelOnTop ? null : 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    widget.stepLabel!,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
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
