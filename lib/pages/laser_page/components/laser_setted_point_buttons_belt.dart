import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserSettedPointButtonsBelt extends StatelessWidget {
  final LaserPageController controller;
  const LaserSettedPointButtonsBelt({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceAround,
        //     children: controller.punti.keys.toList().map((e) {
        //       return ElevatedButton(
        //           style: ButtonStyle(
        //             backgroundColor: WidgetStateProperty.resolveWith((states) {
        //               // If the button is pressed, return size 40, otherwise 20
        //               if (states.contains(WidgetState.pressed)) {
        //                 return AppColors.sagaBlue;
        //               }
        //               return AppColors.sagaBlue;
        //             }),
        //           ),
        //           onPressed: () {
        //             if (!(controller.controllerMode ==
        //                 LaserControllerMode.movimentoAssistito)) {
        //               controller.onPointSelected(e, context);
        //             }
        //           },
        //           onLongPress: () {
        //             controller.moveToPoint(e);
        //           },
        //           child: Text(
        //             e.toUpperCase(),
        //             style: TextStyle(color: Colors.white),
        //           ));
        //     }).toList()),
        // Divider(),
      ],
    );
  }
}
