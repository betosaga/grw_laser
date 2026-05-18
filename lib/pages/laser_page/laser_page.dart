// ignore_for_file: must_call_super

import 'dart:core';
import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/components/laser_log_window.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:grw_laser/services/size_config.dart';
import 'package:grw_laser/pages/laser_page/laser_page_body.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserPage extends StatefulWidget {
  final LaserPageController controller;
  const LaserPage({super.key, required this.controller});

  @override
  LaserState createState() => LaserState();
}

class LaserState extends State<LaserPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
    // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + -
    widget.controller.mySetState = null;
    widget.controller.context = null;
    widget.controller.onDispose();
    super.dispose();
  }

  @override
  initState() {
    // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
    // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + -
    widget.controller.onInit();
    initializeDateFormatting("it_IT", null).then((_) {});
    super.initState();
    // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
    // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + -
  }

  @override
  Widget build(BuildContext context) {
    //
    //
    //
    widget.controller.context = context;
    widget.controller.mySetState = mySetState;
    //
    //
    //
    SizeConfig().init(context);
    //
    //
    //
    widget.controller.h = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(fontWeight: FontWeight.w500);
    widget.controller.l = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(fontWeight: FontWeight.w300);

    return Stack(
      fit: StackFit.expand,
      children: [
        LaserPageBody(controller: widget.controller),
        if (widget.controller.showLogWindow)
          LaserLogWindow(controller: widget.controller)
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
