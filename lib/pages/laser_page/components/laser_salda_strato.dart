import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserSaldaStrato extends StatelessWidget {
  final LaserPageController laserPageController;
  const LaserSaldaStrato({
    required this.laserPageController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                  width: 70,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("Salda\nstrato:")),
              for (int p = 0; p < laserPageController.offsetinizio.length; p++)
                Expanded(
                    flex: 1,
                    child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: laserPageController
                                        .currentStratiEseguiti?[p].eseguito ??
                                    false
                                ? AppColors.sagaBlue
                                : Colors
                                    .grey, // STRATO CORRENTE COLORATO -> SERVE IL DATO
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 18, // Aumenta la dimensione del testo
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                            padding: EdgeInsets.all(2),
                          ),
                          onPressed: null,
                          onLongPress: // lo strato parte solo se il robot è in pausa
                              () {
                            Vibrator.mediumVibration();
                            laserPageController.onSaldaStratoPressed(
                                p, context);
                          },
                          // onLongPress: () {
                          //   laserPageController.onSaldaStratoPressed(p, context);
                          // },
                          child: Text(
                            "Strato\n" + (p + 1).toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors
                                  .white, // Imposta il colore del testo a bianco
                              fontSize: 18, // Aumenta la dimensione del testo
                            ),
                          ),
                        ))),
            ],
          ),
          Row(
            children: [
              Container(
                width: 70,
                margin: EdgeInsets.symmetric(horizontal: 2),
              ),
              for (int p = 0; p < laserPageController.offsetinizio.length; p++)
                Expanded(
                    flex: 1,
                    child: Container(
                        child: Text(
                      laserPageController.currentStratiEseguiti?[p]
                              .getDurataFormatted() ??
                          "",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ))),
            ],
          )
        ],
      ),
    );
  }
}
