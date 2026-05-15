import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserPointButtonsBelt extends StatelessWidget {
  final LaserPageController controller;

  const LaserPointButtonsBelt({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SizedBox(
        //   height: 30,
        // ),
        // Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceAround,
        //     children: controller.punti.keys.toList().map((e) {
        //       bool puntoAbilitato = controller.punti[e] ?? false;
        //       return ElevatedButton(
        //           onPressed: (puntoAbilitato &&
        //                       controller.controllerMode ==
        //                           LaserControllerMode.movimentoAssistito) ||
        //                   !(controller.controllerMode ==
        //                       LaserControllerMode.movimentoAssistito)
        //               ? () {
        //                   print("Punto Preso");
        //                   controller.onPointSelected(e, context);
        //                 }
        //               : null,
        //           style: puntoAbilitato ||
        //                   !(controller.controllerMode ==
        //                       LaserControllerMode.movimentoAssistito)
        //               ? ButtonStyle(
        //                   backgroundColor:
        //                       WidgetStatePropertyAll(AppColors.sagaBlue))
        //               : null,
        //           child: Text(
        //             e.toUpperCase(),
        //             style: TextStyle(
        //                 color: puntoAbilitato ||
        //                         (!(controller.controllerMode ==
        //                                 LaserControllerMode
        //                                     .movimentoAssistito) &&
        //                             controller.points.isSetted(pointName: e))
        //                     ? Colors.white
        //                     : Colors.grey),
        //           ));
        //     }).toList()),
        // Divider(
        //   color: Colors.transparent,
        // ),
      ],
    );
  }
}
