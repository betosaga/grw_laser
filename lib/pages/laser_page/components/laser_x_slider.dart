import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class LaserXSlider extends StatefulWidget {
  final LaserPageController controller;
  LaserXSlider({required this.controller});
  @override
  _LaserXSliderState createState() => _LaserXSliderState();
}

class _LaserXSliderState extends State<LaserXSlider> {
  @override
  Widget build(BuildContext context) {
    return SfSlider.vertical(
        min: 0.0,
        max: 100.0,
        value: widget.controller.stepx,
        interval: 20,
        showTicks: true,
        showLabels: true,
        enableTooltip: true,
        minorTicksPerInterval: 1,
        onChanged: (dynamic value) {
          mySetState(() {
            widget.controller.stepx = value;
          });
        });
  }

  void mySetState(VoidCallback? f) {
    if (f == null) return;
    if (mounted) {
      setState(f);
    }
  }
}
