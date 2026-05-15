import 'package:flutter/material.dart';
import 'package:grw_laser/common_components/loading_spinner.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserCaricamentoDati extends StatelessWidget {
  final LaserPageController controller;
  const LaserCaricamentoDati({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
            child: LoadingSpinner(
      color: AppColors.sagaBlue,
    )));
  }
}
