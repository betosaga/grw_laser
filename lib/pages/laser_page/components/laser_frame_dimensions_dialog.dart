import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/pager.dart';

class LaserFrameDimensionsDialog extends StatelessWidget {
  final TextEditingController widthController;
  final TextEditingController heightController;

  const LaserFrameDimensionsDialog(
      {super.key, required this.widthController, required this.heightController});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Dimensioni area lavorazione"),
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Larghezza (mm):",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: widthController,
              keyboardType: TextInputType.number,
            ),
            Text("Altezza (mm):",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
            )
          ],
        ),
      ),
      actions: [
        ElevatedButton(
            onPressed: () => Pager.pop(context),
            child: Text(
              'Annulla',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            )),
        ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.blue;
                }
                return AppColors.sagaBlue;
              }),
            ),
            onPressed: () => Pager.pop(context, "confirm"),
            child: Text(
              'Conferma',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            )),
      ],
    );
  }
}
