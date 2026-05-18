import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserJog extends StatefulWidget {
  final double maxstepx;
  final LaserPageController controller;
  const LaserJog({super.key, required this.maxstepx, required this.controller});

  @override
  _LaserJogState createState() => _LaserJogState();
}

class _LaserJogState extends State<LaserJog>
    with SingleTickerProviderStateMixin {
  double _value = 0.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _controller.addListener(() {
      mySetState(() {
        _value = _animation.value;
      });
      widget.controller.onJogChangedValue(_value);
    });
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  void _updateValue(double dy) {
    mySetState(() {
      // divisore = half_travel / maxstepx = 90 / maxstepx → mappatura 1:1 gesto↔cursore
      _value -= dy / (90 / widget.maxstepx);
      if (_value > widget.maxstepx) _value = widget.maxstepx;
      if (_value < -widget.maxstepx) _value = -widget.maxstepx;
    });
    widget.controller.onJogChangedValue(_value);
  }

  void _resetValue() {
    _animation = Tween<double>(begin: _value, end: 0).animate(_controller);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          child: Center(
            child: _value < -0.05
                ? Text(
                    _value.abs().toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.sagaBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ),
        GestureDetector(
          onPanUpdate: (details) {
            _updateValue(-details.delta.dy);
          },
          onPanEnd: (details) {
            _resetValue();
          },
          child: Container(
            height: 220,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Cursore: centro = 90, range [0, 180] → arriva in testa e in fondo
                Positioned(
                  top: 100 + (_value / widget.maxstepx) * 100,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.sagaBlue,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(0),
                          spreadRadius: 3,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(child: Divider(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 16,
          child: Center(
            child: _value > 0.05
                ? Text(
                    _value.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.sagaBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void mySetState(VoidCallback? f) {
    if (f == null) return;
    if (mounted) {
      setState(f);
    }
  }
}
