import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/response/response_error.dart';
import 'package:grw_laser/pages/laser_page/laser_page.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/components/select_laser_robot_settings_dialog.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/services/api.dart';
import 'package:grw_laser/services/hive_disk_encoder.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/pager.dart';

//
//
//
class LaserPageHubController {
  BuildContext? context;
  Function(VoidCallback?)? mySetState;

  final box = HiveDiskEncoder();

  bool isLoadingRobots = false;
  bool isThinking = false;
  bool isRemovingPage = false;
  List<LaserRobotSettings> elencoRobotSettings = [];

  int currentIndex = 0;

  List<LaserPage> laserPages = [];
  LaserPageController get currentController =>
      laserPages[currentIndex].controller;

  PageController pageController = PageController(initialPage: 0);
  bool scrollViewEnabledScrolling = false;

  void onInit() {
    restoreSettingsListFromDisk();
  }

  void toggleScrollViewEnabledScrolling() {
    scrollViewEnabledScrolling = !scrollViewEnabledScrolling;
    laserPages.forEach((element) {
      element.controller
          .setScrollViewEnabledScrolling(newValue: scrollViewEnabledScrolling);
      ;
    });
  }

  //
  //
  //

  void onLaserPageChanged(int newIndex) {
    mySetState?.call(() {
      currentIndex = newIndex;
    });
  }

  //
  //
  //
  
  void goToNextRightPage() {
    int newIndex =
        currentIndex < laserPages.length - 1 ? currentIndex + 1 : currentIndex;
    mySetState?.call(() {
      if (pageController.hasClients) {
        pageController.animateToPage(newIndex,
            duration: Duration(milliseconds: 500), curve: Curves.bounceInOut);
      }
    });
  }

  //
  //
  //
  void goToPreviousPage() {
    int newIndex = currentIndex > 0 ? currentIndex - 1 : currentIndex;
    mySetState?.call(() {
      if (pageController.hasClients) {
        pageController.animateToPage(newIndex,
            duration: Duration(milliseconds: 500), curve: Curves.bounceInOut);
      }
    });
  }

  //
  //
  //

  Future<void> selectRobotPressed() async {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    // SELECT ROBOT PRESSED

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if (context == null) return;
    await fetchRobotList();
    final LaserRobotSettings? selectedSettings =
        await showDialog<LaserRobotSettings?>(
      barrierDismissible: false,
      context: context!,
      builder: (BuildContext context) {
        return SelectLaserRobotSettingsDialog(list: elencoRobotSettings);
      },
    );

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if (selectedSettings != null) {
      // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
      // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
      // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
      print("SETTINGS SELEZIONATE");
      bool found = false;
      for (int i = 0; i < laserPages.length; i++) {
        if (laserPages[i].controller.settings.serialeRobot.trim() ==
            selectedSettings.serialeRobot.trim()) {
          found = true;
          break;
        }
      }
      if (found) {
        return;
      }

      String? tipoControrotaia;
      if (selectedSettings.tipoControrotaia.trim().isNotEmpty &&
          selectedSettings.tipoControrotaia.trim() != '0') {
        tipoControrotaia =
            _normalizeTipoControrotaia(selectedSettings.tipoControrotaia);
      } else {
        tipoControrotaia = await _askTipoControrotaia();
      }
      if (tipoControrotaia == null) {
        return;
      }

      final newLaserController = LaserPageController(
          hubController: this,
          settings: selectedSettings,
          tipoControrotaia: tipoControrotaia);
      final newLaserPage = LaserPage(controller: newLaserController);

      laserPages.add(newLaserPage);
      mySetState?.call(() {});
      if (pageController.hasClients) {
        pageController.animateToPage(laserPages.length - 1,
            duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
      storeSettingsListToDisk();
      //
    } else {
      print("OPERAZIONE ANNULLATA");
    }
  }

  //
  //
  //
  Future<String?> _askTipoControrotaia() async {
    if (context == null) return null;
    return showDialog<String>(
      context: context!,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tipo controrotaia',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleziona il tipo di controrotaia da lavorare',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sagaBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop('controrotaiadoppia'),
                  child: const Text('Doppia', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sagaBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      Navigator.of(ctx).pop('controrotaiasemplice'),
                  child: const Text('Semplice', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sagaBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop('piano'),
                  child: const Text('Piano di rotolamento',
                      textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Annulla', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _normalizeTipoControrotaia(String? tipo) {
    final raw = (tipo ?? '').trim().toLowerCase();
    switch (raw) {
      case '0':
      case 'lunga':
      case 'controrotaiasemplice':
      case 'controrotaia semplice':
      case 'semplice':
        return 'controrotaiasemplice';
      case '1':
      case 'cuore':
      case 'controrotaiadoppia':
      case 'controrotaia doppia':
      case 'doppia':
        return 'controrotaiadoppia';
      case '2':
      case 'piano':
      case 'piano di rotolamento':
        return 'piano';
      default:
        return 'controrotaiasemplice';
    }
  }

  //
  //
  //
  Future<void> fetchRobotList() async {
    mySetState?.call(() {
      isLoadingRobots = true;
    });
    try {
      final response = await Api.request({
        "f": "getRobotLaserList",
      }, verbose: false);
      elencoRobotSettings = robotLaserSettingsListFromJson(response.body);
    } catch (e) {
      print(e.toString());
      if (e is ResponseError) {
        if (e.message.trim() != "" && context != null) {
          Messenger.showMessageGenericError(context, e.message, 2);
        }
      }
    }
    mySetState?.call(() {
      isLoadingRobots = false;
    });
  }

  void setRobotSettings(
      {required String newSeriale, required LaserRobotSettings newSettings}) {
    // controllo, faccio qualcosa solo se è cambiato qualcosa:
    print("SET ROBOT SETTINGS HUB");
  }

  void resetRobotSettings() {}

  void closePage({required BuildContext context}) async {
    final confirmed = await Messenger.askMessage(
          context,
          "CONFERMA",
          "CONFERMI DI USCIRE DALLA PAGINA?",
          "ESCI DALLA PAGINA",
          "ANNULLA",
        ) ??
        false;

    if (confirmed) {
      mySetState?.call(() {
        isThinking = true;
      });
      for (var i = 0; i < laserPages.length; i++) {
        await laserPages[i].controller.eraseController();
      }
      this.laserPages = [];

      storeSettingsListToDisk();
      // elimino tutto anche da box:

      Pager.goToFirstPage(context);
    }
  }

  Future<bool> removePageFor({required String robotSerial}) async {
    if (isRemovingPage) {
      return false;
    }

    if (context == null) {
      return false;
    }

    final confirmed = await Messenger.askMessageAlert(context, "CONFERMA",
            "ELIMINARE PAGINA ROBOT?", "ELIMINA", "INDIETRO") ??
        false;
    if (!confirmed) {
      return false;
    }

    isRemovingPage = true;
    try {
      final targetIndex = laserPages.indexWhere((page) =>
          page.controller.settings.serialeRobot.trim() == robotSerial.trim());

      if (targetIndex < 0) {
        return false;
      }

      final pageToRemove = laserPages[targetIndex];

      mySetState?.call(() {
        laserPages.removeAt(targetIndex);

        if (laserPages.isEmpty) {
          currentIndex = 0;
          return;
        }

        if (currentIndex > targetIndex) {
          currentIndex -= 1;
        }
        if (currentIndex >= laserPages.length) {
          currentIndex = laserPages.length - 1;
        }
      });

      if (pageController.hasClients && laserPages.isNotEmpty) {
        try {
          pageController.jumpToPage(currentIndex);
        } catch (_) {}
      }

      storeSettingsListToDisk();

      // Cleanup best-effort: la rimozione pagina non deve fallire se il socket
      // robot non risponde o è già chiuso.
      try {
        await pageToRemove.controller
            .deleteSafePosition()
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      try {
        await pageToRemove.controller.eraseController();
      } catch (_) {}

      return true;
    } finally {
      isRemovingPage = false;
    }
  }

  void storeSettingsListToDisk() {
    //
    //
    final currentSettingsList =
        laserPages.map((e) => e.controller.settings).toList();
    final settingsString = robotLaserSettingsListToJson(currentSettingsList);
    box.setString(
        value: settingsString, key: Constants.HIVE_LASER_SETTINGS_LIST_KEY);

    final tipoMap = <String, String>{};
    for (final page in laserPages) {
      final serial = page.controller.settings.serialeRobot.trim();
      if (serial.isEmpty) continue;
      tipoMap[serial] = page.controller.controrotaiaModeValue;
    }
    box.setString(
      value: jsonEncode(tipoMap),
      key: Constants.HIVE_LASER_TIPO_CONTROROTAIA_MAP_KEY,
    );
  }

  void restoreSettingsListFromDisk() {
    final settingsString =
        box.stringFor(key: Constants.HIVE_LASER_SETTINGS_LIST_KEY);
    final tipoMapString =
        box.stringFor(key: Constants.HIVE_LASER_TIPO_CONTROROTAIA_MAP_KEY);
    Map<String, String> tipoMap = {};
    if (tipoMapString != null && tipoMapString.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(tipoMapString);
        if (decoded is Map<String, dynamic>) {
          tipoMap = decoded
              .map((key, value) => MapEntry(key.toString(), value.toString()));
        }
      } catch (_) {}
    }

    if (settingsString != null && settingsString != "") {
      try {
        final currentSettingsList =
            robotLaserSettingsListFromJson(settingsString);
        final pages = currentSettingsList.map((e) {
          final serial = e.serialeRobot.trim();
          final tipo = e.tipoControrotaia.trim().isNotEmpty
              ? _normalizeTipoControrotaia(e.tipoControrotaia)
              : _normalizeTipoControrotaia(tipoMap[serial]);

          return LaserPage(
            controller: LaserPageController(
              settings: e,
              hubController: this,
              tipoControrotaia: tipo,
            ),
          );
        }).toList();
        mySetState?.call(() {
          laserPages.addAll(pages);
        });
      } catch (e) {
        print("Failed to parse Settings String From Disk");
      }
    }
  }
}
