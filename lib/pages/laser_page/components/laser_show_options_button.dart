import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:grw_laser/common_components/loading_spinner.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserShowOptionsButton extends StatelessWidget {
  final LaserPageController controller;
  const LaserShowOptionsButton({required this.controller});

  final double _width = 300;
  final double _verticalSpace = 8;

  @override
  Widget build(BuildContext context) {
    // - - - - - - - - - - - - - - - - - - - 
    // - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - -
    final outerContext = context;
    return Listener(
      onPointerDown: (_) => Vibrator.shortVibration(),
      child: IconButton(
        icon: Icon(
          Icons.list,
          color: Colors.white,
        ),
        onPressed: () {
          showPopover(
            context: context,
            radius: 32,
            bodyBuilder: (context) => Container(
              color: Colors.white,
              width: _width,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: _verticalSpace,
                    ),
                    Container(
                      width: _width,
                      child: Listener(
                        onPointerDown: (_) => Vibrator.shortVibration(),
                        child: TextButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(AppColors.sagaBlue)),
                          onPressed: () {
                            Pager.pop(context);
                            controller.goToPointsHistory(context: context);
                          },
                          child: Text(
                            "STORICO PUNTI",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _verticalSpace,
                    ),
                    Container(
                      width: _width,
                      child: TextButton(
                        style: ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(AppColors.sagaBlue)),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                                context: outerContext,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Conferma'),
                                  content:
                                      const Text('Avviare la simulazione?'),
                                  actions: [
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('ANNULLA'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('CONFERMA'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (!confirmed) return;
                          Vibrator.mediumVibration();
                          Pager.pop(context);
                          controller.sendPointsToFastAPI();
                        },
                        child: controller.sendingSimulationPoints
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: LoadingSpinner(
                                  color: Colors.white,
                                ))
                            : Text(
                                "SIMULA",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                    if (controller.paused || !controller.startedWeldingOnce)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: _verticalSpace,
                          ),
                          if (!controller.isControrotaiaSemplice &&
                              !controller.isPianoRotolamento)
                          Container(
                            width: _width,
                            child: TextButton(
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        AppColors.sagaBlue)),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                        context: outerContext,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Conferma'),
                                          content: const Text(
                                              'Avviare la modalità pulizia?'),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('ANNULLA'),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('CONFERMA'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (!confirmed) return;
                                  Vibrator.mediumVibration();
                                  Pager.pop(context);
                                  controller.enterPuliziaMode();
                                },
                                child: Text(
                                  "PULIZIA",
                                  style: TextStyle(color: Colors.white),
                                )),
                          ),
                          if (!controller.isControrotaiaSemplice &&
                              !controller.isPianoRotolamento)
                          SizedBox(
                            height: _verticalSpace,
                          ),
                          if (!controller.isControrotaiaSemplice &&
                              !controller.isPianoRotolamento)
                          Container(
                            width: _width,
                            child: TextButton(
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        AppColors.sagaBlue)),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                        context: outerContext,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Conferma'),
                                          content: const Text(
                                              'Avviare la modalità manutenzione?'),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('ANNULLA'),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('CONFERMA'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (!confirmed) return;
                                  Vibrator.mediumVibration();
                                  Pager.pop(context);
                                  controller.enterMaintenanceMode();
                                },
                                child: Text(
                                  "MANUTENZIONE",
                                  style: TextStyle(color: Colors.white),
                                )),
                          ),
                          if (!controller.isControrotaiaSemplice &&
                              !controller.isPianoRotolamento)
                          SizedBox(
                            height: _verticalSpace,
                          ),
                          if (!controller.isControrotaiaSemplice &&
                              !controller.isPianoRotolamento)
                          Container(
                            width: _width,
                            child: TextButton(
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        AppColors.sagaBlue)),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                        context: outerContext,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Conferma'),
                                          content: const Text(
                                              'Avviare la modalità trasporto?'),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('ANNULLA'),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('CONFERMA'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (!confirmed) return;
                                  Vibrator.mediumVibration();
                                  Pager.pop(context);
                                  controller.enterTransportMode();
                                },
                                child: Text(
                                  "TRASPORTO",
                                  style: TextStyle(color: Colors.white),
                                )),
                          ),
                          if (!controller.isControrotaiaSemplice &&
                              !controller.isPianoRotolamento)
                          SizedBox(
                            height: _verticalSpace,
                          ),
                          Container(
                            width: _width,
                            child: TextButton(
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        AppColors.sagaBlue)),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                        context: outerContext,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Conferma'),
                                          content: const Text(
                                              'Spegnere il server FastAPI?'),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('ANNULLA'),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('CONFERMA'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (!confirmed) return;
                                  Vibrator.mediumVibration();
                                  Pager.pop(context);
                                  controller.shutDownFastAPIServer();
                                },
                                child: Text(
                                  "SPEGNI FASTAPI",
                                  style: TextStyle(color: Colors.white),
                                )),
                          ),
                          SizedBox(height: _verticalSpace),
                          Container(
                            width: _width,
                            child: Listener(
                              onPointerDown: (_) => Vibrator.shortVibration(),
                              child: TextButton(
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        AppColors.sagaBlue)),
                                onPressed: () {
                                  Pager.pop(context);
                                  controller.openPanelAlignmentConfig();
                                },
                                child: Text(
                                  "CONFIGURAZIONE",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                  ],
                ),
              ),
            ),
            onPop: () {},
            direction: PopoverDirection.top,
            width: _width,
            // height: _height,
            arrowHeight: 15,
            arrowWidth: 20,
          );
        }),
      );
  }
}
