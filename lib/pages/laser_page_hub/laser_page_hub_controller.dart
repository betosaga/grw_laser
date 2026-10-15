import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/response/response_error.dart';
import 'package:grw_laser/pages/laser_page/laser_page.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/components/select_laser_robot_settings_dialog.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_modalita.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/services/api.dart';
import 'package:grw_laser/services/hive_disk_encoder.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/robot/robot_discovery.dart';
import 'package:grw_laser/services/user_session_nest.dart';

//
//
//
class LaserPageHubController {
  LaserPageHubController({RobotDiscovery Function()? discoveryFactory})
      : _discoveryFactory = discoveryFactory ?? RobotDiscovery.new;

  final RobotDiscovery Function() _discoveryFactory;
  RobotDiscovery? _activeDiscovery;
  bool _selectingRobot = false;
  bool _disposed = false;

  bool get _canShowSelection => !_disposed && context != null && context!.mounted;

  /// The + button dispatches here; the original FLAT entry point is retained.
  Future<void> addRobotPressed() async {
    if (_selectingRobot || !_canShowSelection) return;
    _selectingRobot = true;
    try {
      if (Constants.ROBOT_SEARCH_MODE == 'SCAN') {
        await selectRobotByScanPressed();
      } else {
        await selectRobotPressed();
      }
    } finally {
      _selectingRobot = false;
    }
  }

  Future<void> selectRobotByScanPressed() async {
    if (!_canShowSelection || _activeDiscovery != null) return;
    final discovery = _discoveryFactory();
    _activeDiscovery = discovery;
    List<LaserRobotSettings>? available;
    final discoveredIps = <String, String>{};
    try {
      logRobotScan('Avvio flusso SCAN: scaricamento elenco robot dal server.');
      await fetchRobotList();
      logRobotScan('Elenco server: ${elencoRobotSettings.length} robot.');
      if (!_canShowSelection || discovery.isCancelled) return;
      _setLoadingRobots(true);
      final robots = await discovery.scan();
      if (!_canShowSelection || discovery.isCancelled) return;
      for (final robot in robots) {
        discoveredIps.putIfAbsent(robot.serverSerial, () => robot.ip);
      }
      available = elencoRobotSettings
          .where((settings) =>
              discoveredIps.containsKey(settings.serialeRobot.trim()))
          .map((settings) => settings
              .withRobotIp(discoveredIps[settings.serialeRobot.trim()]!))
          .toList();
      logRobotScan('Filtro completato: ${robots.length} robot rilevati in rete, '
          '${available.length}/${elencoRobotSettings.length} robot server disponibili.');
      for (final robot in robots) {
        final matched = available.any((settings) =>
            settings.serialeRobot.trim() == robot.serverSerial);
        logRobotScan('${matched ? 'INCLUSO' : 'ESCLUSO (non presente sul server)'}: '
            '${robot.serverSerial} @ ${robot.ip}:20002');
      }
    } catch (error) {
      logRobotScan('ERRORE flusso SCAN: $error');
      if (_canShowSelection && !discovery.isCancelled) {
        Messenger.showMessageGenericError(
          context,
          error is RobotDiscoveryException
              ? error.message
              : 'Impossibile cercare i robot. Verifica la connessione e il permesso di accesso alla rete locale.',
          4,
        );
      }
    } finally {
      discovery.cancel();
      _activeDiscovery = null;
      _setLoadingRobots(false);
    }
    if (available != null && _canShowSelection) {
      await _showRobotSelection(available, discoveredIps: discoveredIps);
    }
  }

  void _setLoadingRobots(bool value) {
    isLoadingRobots = value;
    if (!_disposed) mySetState?.call(() {});
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeDiscovery?.cancel();
    context = null;
    mySetState = null;
    pageController.dispose();
  }

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

  void toggleScrollViewEnabledScrolling() {
    scrollViewEnabledScrolling = !scrollViewEnabledScrolling;
    for (var element in laserPages) {
      element.controller
          .setScrollViewEnabledScrolling(newValue: scrollViewEnabledScrolling);
    }
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
    if (context == null) return;
    await fetchRobotList();
    if (!_canShowSelection) return;
    await _showRobotSelection(elencoRobotSettings);
  }

  Future<void> _showRobotSelection(
    List<LaserRobotSettings> robots, {
    Map<String, String> discoveredIps = const {},
  }) async {
    if (!_canShowSelection) return;
    final LaserRobotSettings? selectedSettings =
        await showDialog<LaserRobotSettings?>(
      barrierDismissible: false,
      context: context!,
      builder: (BuildContext context) {
        return SelectLaserRobotSettingsDialog(list: robots);
      },
    );

    if (selectedSettings != null) {
      print("SETTINGS SELEZIONATE");
      final selectedRobotSerial = selectedSettings.serialeRobot.trim();
      final serverDetail =
          await fetchRobotDetail(serialeRobot: selectedRobotSerial);
      if (serverDetail == null || !_canShowSelection) return;
      final discoveredIp = discoveredIps[selectedRobotSerial];
      if (discoveredIp != null) {
        logRobotScan('SELEZIONATO $selectedRobotSerial: connessione a '
            '$discoveredIp:20002 (IP server: ${serverDetail.ipRobot}).');
      }
      final selectedRobotDetail = discoveredIp == null
          ? serverDetail
          : serverDetail.withRobotIp(discoveredIp);

      final tipoControrotaia = await askTipoControrotaia(
        serialeRobot: selectedRobotSerial,
        modalitaAbilitate: selectedRobotDetail.modalitaAbilitate,
      );
      if (tipoControrotaia == null || context == null || !context!.mounted) return;

      final existingPageIndex = laserPages.indexWhere((page) =>
          page.controller.settings.serialeRobot.trim() == selectedRobotSerial);
      if (existingPageIndex >= 0) {
        await laserPages[existingPageIndex].controller
            .setRobotSettings(
              newSettings: selectedRobotDetail,
              connectionFieldsFromServer: true,
              selectedWorkMode: tipoControrotaia,
            );
        storeSettingsListToDisk();
        mySetState?.call(() {});
        if (pageController.hasClients) {
          pageController.animateToPage(existingPageIndex,
              duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
        return;
      }

      final newLaserController = LaserPageController(
          hubController: this,
          settings: selectedRobotDetail,
          selectedWorkMode: tipoControrotaia);
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

  Future<LaserRobotSettings?> fetchRobotDetail(
      {required String serialeRobot}) async {
    try {
      final response = await Api.request({
        "f": "getRobotLaserDetail",
        "seriale_robot": serialeRobot,
      }, verbose: false);
      return robotLaserSettingsFromJson(response.body);
    } catch (e) {
      print(e.toString());
      if (e is ResponseError) {
        if (e.message.trim() != "" && context != null) {
          Messenger.showMessageGenericError(context, e.message, 2);
        }
      }
    }
    return null;
  }

  //
  //
  //
  Future<void> _modeDialogQueue = Future<void>.value();

  Future<String?> askTipoControrotaia({
    String? serialeRobot,
    required List<LaserRobotModalita> modalitaAbilitate,
  }) {
    // Le pagine ripristinate possono richiedere la modalità contemporaneamente.
    final request = _modeDialogQueue.then(
      (_) => _showTipoControrotaiaDialog(
        serialeRobot: serialeRobot,
        modalitaAbilitate: modalitaAbilitate,
      ),
    );
    _modeDialogQueue = request.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return request;
  }

  Future<String?> _showTipoControrotaiaDialog({
    String? serialeRobot,
    required List<LaserRobotModalita> modalitaAbilitate,
  }) async {
    if (context == null || !context!.mounted) return null;
    return showDialog<String>(
      context: context!,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tipo di lavorazione',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                serialeRobot == null
                    ? 'Seleziona il tipo di lavorazione'
                    : 'Robot $serialeRobot\nSeleziona il tipo di lavorazione',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (modalitaAbilitate.isEmpty)
                const Text(
                  'Nessuna lavorazione abilitata per questo robot. Impossibile proseguire.',
                  textAlign: TextAlign.center,
                ),
              for (final modalita in modalitaAbilitate) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sagaBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(modalita.codice),
                    child: Text(
                      modalita.nome.isEmpty ? modalita.codice : modalita.nome,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
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

  //
  //
  //
  Future<void> fetchRobotList() async {
    _setLoadingRobots(true);
    elencoRobotSettings = [];
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
    if (_activeDiscovery == null) _setLoadingRobots(false);
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
          "LOGOUT",
          "CONFERMI IL LOGOUT?",
          "LOGOUT",
          "ANNULLA",
        ) ??
        false;

    if (confirmed) {
      _activeDiscovery?.cancel();
      mySetState?.call(() {
        isThinking = true;
      });
      for (var i = 0; i < laserPages.length; i++) {
        await laserPages[i].controller.eraseController();
      }
      laserPages = [];

      storeSettingsListToDisk();

      await UserSessionNest.eraseSession();
      Pager.setFirstPageLogin(context: context);
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

}
