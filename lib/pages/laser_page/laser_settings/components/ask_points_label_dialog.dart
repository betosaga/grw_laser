import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class AskPointsLabelDialog extends StatelessWidget {
  AskPointsLabelDialog({super.key, String initialLabel = ""})
      : editingController = TextEditingController(text: initialLabel);

  final TextEditingController editingController;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        scrollable: true,
        title: Text("Etichetta"),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Inserire un etichetta:"),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: editingController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  maxLines: 1,
                )
              ],
            ),
          ),
        ),
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
                  child: Text("ANNULLA",
                      style: TextStyle(color: AppColors.sagaBlue)))),
          Listener(
              onPointerDown: (_) => Vibrator.shortVibration(),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sagaBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Pager.pop(context, editingController.text);
                  },
                  child: Text("CONFERMA"))),
        ]);
  }
}
