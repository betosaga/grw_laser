import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserAskRobotSerialDialog extends StatelessWidget {
  final serialEditingController = TextEditingController();

  LaserAskRobotSerialDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Seriale Robot"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              "Inserire il seriale del robot per continuare:"),
          SizedBox(height: 32,),
          TextField(controller: serialEditingController, textAlign: TextAlign.center,)
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Listener(
            onPointerDown: (_) => Vibrator.shortVibration(),
            child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.sagaBlue,
            ),
            onPressed: () {
              Pager.pop(context, null);
            },
            child: Text("ANNULLA", style: TextStyle(color: AppColors.sagaBlue, fontWeight: FontWeight.bold),))),
        Listener(
            onPointerDown: (_) => Vibrator.shortVibration(),
            child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sagaBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Pager.pop(context, serialEditingController.text);
            },
            child: Text("INSERISCI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),))),
      ],
    );
  }
}
