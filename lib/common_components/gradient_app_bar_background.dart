import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_gradients.dart';

class GradientAppBarBackground extends StatelessWidget {
  const GradientAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.drawerBlue,
      ),
      child: SizedBox.expand(),
    );
  }
}
