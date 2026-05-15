import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/components/laser_numeric_pad_input.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserOffsetStrato extends StatelessWidget {
  final LaserPageController controller;
  const LaserOffsetStrato({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
              width: 70,
              margin: EdgeInsets.symmetric(horizontal: 2),
              child: Text(controller.stepLayerOffsetLabel)),
          for (int p = 0; p < controller.offsetstrato.length; p++)
            Expanded(
                flex: 1,
                child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    child: LaserNumericPadInput(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: AppColors.sagaBlue,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 6), // Imposta il padding a 2 pixel
                        border: OutlineInputBorder(), // Aggiungi un bordo
                        labelText: 'mm S' +
                            (p + 1).toString(), // Etichetta del campo di testo
                      ),
                      controller: controller.offsetStratoController[p],
                    ))),
        ],
      ),
    );
  }
}
