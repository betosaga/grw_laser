import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:unicons/unicons.dart';

class LaserOmnidirectionalJog extends StatefulWidget {
  final double range;
  final LaserPageController controller;

  const LaserOmnidirectionalJog(
      {Key? key, required this.range, required this.controller})
      : super(key: key);

  @override
  _LaserOmnidirectionalJogState createState() =>
      _LaserOmnidirectionalJogState();
}

class _LaserOmnidirectionalJogState extends State<LaserOmnidirectionalJog>
    with SingleTickerProviderStateMixin {
  double _yValue = 0.0;
  double _zValue = 0.0;
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addListener(() {
        if (!widget.controller.verticalLock) {
          mySetState(() {
            _yValue = _animation.value.dx;
            _zValue = _animation.value.dy;
          });
          widget.controller.onOmnidirectionJogChangedValue(_yValue, _zValue);
        }
      });
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_controller);
  }

  void _updateValue(Offset localPosition) {
    if (!widget.controller.verticalLock) {
      mySetState(() {
        _yValue = ((localPosition.dx - 100) / 90) * widget.range;
        _zValue = -((localPosition.dy - 100) / 90) *
            widget.range; // Invert the z-axis value

        // Clamping the values to the range
        if (_yValue > widget.range) _yValue = widget.range;
        if (_yValue < -widget.range) _yValue = -widget.range;
        if (_zValue > widget.range) _zValue = widget.range;
        if (_zValue < -widget.range) _zValue = -widget.range;
      });
      widget.controller.onOmnidirectionJogChangedValue(_yValue, _zValue);
    }
  }

  void _resetValue() {
    _animation =
        Tween<Offset>(begin: Offset(_yValue, _zValue), end: Offset.zero)
            .animate(_controller);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        _updateValue(details.localPosition);
      },
      onPanEnd: (details) {
        _resetValue();
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(110),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 90 + (_yValue / widget.range) * 90,
              top: 90 -
                  (_zValue / widget.range) * 90, // Adjusted for inverted z-axis
              // left: 100 + (_yValue / widget.range) * 90,
              // top: 100 - (_zValue / widget.range) * 90, // Adjusted for inverted z-axis
              child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.controller.verticalLock
                        ? Colors.grey
                        : AppColors.sagaBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(0),
                        spreadRadius: 3,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Icon(UniconsLine.expand_arrows, color: Colors.white)),
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
