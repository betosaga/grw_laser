import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/extensions/response_success_extension.dart';
import 'package:grw_laser/model/laser_controller_mode.dart';
import 'package:grw_laser/model/interpola_response.dart';
import 'package:grw_laser/model/laser_points_package.dart';
import 'package:grw_laser/model/params.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/model/points_free.dart';
import 'package:grw_laser/model/strato_laser.dart';
import 'package:grw_laser/pages/laser_page/components/laser_frame_dimensions_dialog.dart';
import 'package:grw_laser/pages/laser_page/laser_panel_state.dart';
import 'package:grw_laser/pages/laser_page/laser_points_history/laser_points_history_page.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/components/ask_points_label_dialog.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/laser_settings_page.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_limite.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/pages/laser_page/laser_simulation_page.dart';
import 'package:grw_laser/pages/laser_page/model/safe_position.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub_controller.dart';
import 'package:grw_laser/services/api.dart';
import 'package:grw_laser/services/audio_service.dart';
import 'package:grw_laser/services/hive_disk_encoder.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';
import 'package:grw_laser/services/volume_service.dart';
import 'package:http/http.dart' as http;
import 'package:grw_laser/model/response/response_error.dart';

//
//
//
class _SocketJsonExtraction {
//
//
  final List<String> messages;
  final String remainingBuffer;

  _SocketJsonExtraction(
      {required this.messages, required this.remainingBuffer});
}

//
//
class LaserPageController {
  //
  //
  static const String robotTxLogPrefix = '[SAGA_ROBOT_TX]';
  static const String moveToDebugLogPrefix = '[SAGA_MOVETO_DEBUG]';
  static const bool disableMoveToRobotSend = false;

  //
  //
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  //
  //  LaserPageController
  //
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  //
  //
  bool UNLOCK_PAGE_FOR_TEST = false;
  //
  //
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  //
  //
  BuildContext? context;
  Function(VoidCallback?)? mySetState;
  // Impostazioni - Start
  LaserPageHubController hubController;
  LaserRobotSettings settings;
  String tipoControrotaia;
  LaserPageController(
      {required this.hubController,
      required this.settings,
      this.tipoControrotaia = 'controrotaiasemplice'});
  //
  //
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  bool scrollViewEnabledScrolling = false;
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  bool connectionStatus = false;
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  LaserPanelState pageState = LaserPanelState.joystick;
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  bool? armPosition = true;
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  bool mostraJoystick = false;
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  /// 'left' = layout originale, 'right' = specchiato
  String panelAlignment = 'left';
  bool showTakenPointsPanel = true;
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  LaserControllerMode controllerMode = LaserControllerMode.freeDraw;
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  String testoloading = "";
  String message = "";
  String posizione = "";
  String peso = "";
  String testolog = "";
  double dimensionipiano = 600;
  double altezzacontrorotaia = 100;
  double rientrocontrorotaia = 50;
  final widgetList = [];
  Point posizioneRobot = Point();
  Point lastRobotPosition = Point();
  List<double> robotSpeed = [0, 0, 0, 0, 0, 0];
  int cordone = 0;
  int strato = 1;
  static const List<int> _offsetInizioDefaultSemplicePiano = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  static const List<int> _offsetInizioDefaultDoppia = [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
  ];
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  // * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *
  List<int> offsetinizio = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45];
  List<int> offsetfine = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  List<int> larghezzasaldatura = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  List<int> velocitasaldatura = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
  List<double> offsetstrato = [0, 1.2, 2.4, 3.6, 4.8, 6.0, 7.2, 8.4, 9.8, 11.0];
  final double defaultSovrapposizioneCordone = 33.3;
  int numerocordonitotale = 0;
  int cordoneiniziale = 0;
  int cordonefinale = 0;
  static const String weldingStatusInactive = 'INACTIVE';
  static const String weldingStatusWelding = 'WELDING';
  static const String weldingStatusPausing = 'PAUSING';
  static const String weldingStatusPaused = 'PAUSED';
  static const String weldingStatusEnd = 'END';
  static const Set<String> weldingFlowStatuses = {
    weldingStatusInactive,
    weldingStatusWelding,
    weldingStatusPausing,
    weldingStatusPaused,
    weldingStatusEnd,
  };
  String status = "";
  String weldingStatus = weldingStatusInactive;
  Timer? timerReconnection;
  Stopwatch stopwatch = Stopwatch();
  bool laserStatus = false;
  bool paused = true;
  PointsFree? ultimiPuntiSalvati;
  bool allPointsSet = false;
  bool allPointsRestored = false;
  TextEditingController sovrapposizioneCordone =
      TextEditingController(text: "");
  double defaultLarghezzaCordone = 3;
  TextEditingController larghezzaCordone = TextEditingController(text: "");
  double defaultScostamentoStratoX = 1.0;
  TextEditingController scostamentoStratoX = TextEditingController(text: "");
  double defaultScostamentoStratoZ = 0.5;
  TextEditingController scostamentoStratoZ = TextEditingController(text: "");
  double defaultWaitPreUscita = 0.5;
  TextEditingController waitPreUscitaController =
      TextEditingController(text: "");
  double defaultWaitFineCordone = 0.2;
  TextEditingController waitFineCordoneController =
      TextEditingController(text: "");
  double defaultWaitLaseronStartCordone = 0.1;
  TextEditingController waitLaseronStartCordoneController =
      TextEditingController(text: "0.1");
  double defaultMinLengthCordoni = 20;
  TextEditingController minLengthCordoniController =
      TextEditingController(text: "20");
  double defaultVelocitaAvvicinamento = 50;
  TextEditingController velocitaAvvicinamentoController =
      TextEditingController(text: "50");
  double defaultVelocitaAllontanamento = 50;
  TextEditingController velocitaAllontanamentoController =
      TextEditingController(text: "50");
  bool alternata = false;
  TextEditingController frameWidthController = TextEditingController(text: "");
  TextEditingController frameHeightController = TextEditingController(text: "");
  bool isConnectingToRobot = false;
  int frameWidth = 0;
  int frameHeight = 0;
  bool frameSet = false;

  String robotModelRead = "";
  String robotSerialRead = "";

  bool isPausingResuming = false;
  bool isStopping = false;
  String? pendingRobotTargetStatus;
  bool isGasActive = false;
  bool isWireActive = false;
  bool startedWeldingOnce = false;

  bool isRemovingRobotPage = false;

  double totalWeldingLength = 0;
  double totalWeldedLength = 0;

  // Modalità Nuvola: quando true, non si assegna ordinamento ai punti e
  // il bottone interpola si abilita con >= 2 punti.
  final ValueNotifier<bool> modalitaNuvolaNotifier = ValueNotifier<bool>(false);
  bool get modalitaNuvola => modalitaNuvolaNotifier.value;

  // Modalità selezione punti: 'perimetro' (ordine), 'base', 'limite'
  final ValueNotifier<String> pointSelectionModeNotifier =
      ValueNotifier<String>('perimetro');
  String get pointSelectionMode => pointSelectionModeNotifier.value;
  void setPointSelectionMode(String mode) {
    pointSelectionModeNotifier.value = mode;
    mySetState?.call(() {});
  }

  // Parametri avanzati modalità Nuvola (editabili via dialog)
  final TextEditingController nuvolaInterpMethodController =
      TextEditingController(text: 'smooth');
  final TextEditingController nuvolaSmoothLambdaController =
      TextEditingController(text: '0.000001');
  final TextEditingController nuvolaInterpKController =
      TextEditingController(text: '8');

  int? currentRobotFrameEpoch;
  int? pointsFrameEpoch;
  bool hasFrameMismatch = false;
  String? lastFrameReason;

  List<TextEditingController> offsetinizioController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<TextEditingController> offsetfineController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<TextEditingController> larghezzasaldaturaController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<TextEditingController> velocitaSaldaturaController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  List<TextEditingController> offsetStratoController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  Map<String, List<StratoLaser>> stratiEseguiti = {};

  Params params = Params();
  // Points points = Points();

  PointsFree points = PointsFree(points: []);
  final ValueNotifier<int> pointsOrderVersion = ValueNotifier<int>(0);
  final ValueNotifier<bool> canGeneratePointsNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> canTakePointNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> sendingSimulationNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<String?> viewerUrlNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> lastInterpolaResponseNotifier =
      ValueNotifier<String?>(null);
  // 'h' = orizzontale, 'v' = verticale
  final ValueNotifier<String> direzioneCordoniNotifier =
      ValueNotifier<String>('v');

  // 'dxsx' = destra->sinistra, 'sxdx' = sinistra->destra
  final ValueNotifier<String> direzioneSaldaturaNotifier =
      ValueNotifier<String>('dxsx');

  void setDirezioneCordoni(String value) {
    if (value != 'h' && value != 'v') return;
    if (direzioneCordoniNotifier.value == value) return;
    direzioneCordoniNotifier.value = value;
  }

  String get defaultDirezioneCordoniForTipo {
    switch (controrotaiaModeValue) {
      case 'controrotaiasemplice':
      case 'piano':
        return 'h';
      case 'controrotaiadoppia':
        return 'v';
      default:
        return 'h';
    }
  }

  void _applyDefaultDirezioneCordoniForTipo() {
    final defaultValue = defaultDirezioneCordoniForTipo;
    if (direzioneCordoniNotifier.value == defaultValue) return;
    direzioneCordoniNotifier.value = defaultValue;
  }

  String get fixedDirezioneSaldaturaForTipo {
    switch (controrotaiaModeValue) {
      case 'controrotaiasemplice':
      case 'piano':
        return 'sxdx';
      case 'controrotaiadoppia':
        return 'dxsx';
      default:
        return 'sxdx';
    }
  }

  void _applyFixedDirezioneSaldaturaForTipo() {
    final fixedValue = fixedDirezioneSaldaturaForTipo;
    if (direzioneSaldaturaNotifier.value == fixedValue) return;
    direzioneSaldaturaNotifier.value = fixedValue;
  }

  void _applyDirectionDefaultsForTipo() {
    _applyDefaultDirezioneCordoniForTipo();
    _applyFixedDirezioneSaldaturaForTipo();
  }

  void setDirezioneSaldatura(String value) {
    final fixedValue = fixedDirezioneSaldaturaForTipo;
    if (value != 'dxsx' && value != 'sxdx') {
      value = fixedValue;
    }
    if (value != fixedValue) {
      value = fixedValue;
    }
    if (direzioneSaldaturaNotifier.value == value) return;
    direzioneSaldaturaNotifier.value = value;
  }

  bool get canTakePoint => canTakePointNotifier.value;
  bool get isWaitingHomeReach => connectionStatus && !homeReachReceived;

  void _setCanTakePoint(bool value) {
    if (canTakePointNotifier.value == value) return;
    canTakePointNotifier.value = value;
    mySetState?.call(() {});
  }

  List<double>? _parseRobotPositionList(dynamic rawPosition) {
    if (rawPosition == null) return null;

    try {
      dynamic value = rawPosition;
      if (value is String) {
        value = jsonDecode(value);
      }

      if (value is List) {
        return List<double>.from(value.map((x) => (x as num).toDouble()));
      }
    } catch (_) {}

    return null;
  }

  int? _parseCordoneFromRobotMessage(Map<String, dynamic> message) {
    final rawCordone = message['Cordone'] ?? message['cordone'];
    if (rawCordone == null) return null;
    if (rawCordone is num) return rawCordone.toInt();
    return int.tryParse(rawCordone.toString());
  }

  int? _parseStratoFromRobotMessage(Map<String, dynamic> message) {
    final rawStrato = message['Strato'] ?? message['strato'];
    if (rawStrato == null) return null;
    if (rawStrato is num) return rawStrato.toInt();
    return int.tryParse(rawStrato.toString());
  }

  List<Map<String, int>> _parseExecutedCordoniFromRobotMessage(
      Map<String, dynamic> message) {
    dynamic rawExecuted =
        message['ExecutedCordoni'] ?? message['executedCordoni'];

    if (rawExecuted is String) {
      try {
        rawExecuted = jsonDecode(rawExecuted);
      } catch (_) {
        return const [];
      }
    }

    if (rawExecuted is! List) {
      return const [];
    }

    final parsed = <Map<String, int>>[];
    for (final item in rawExecuted) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final strato = _parseStratoFromRobotMessage(map);
      final cordone = _parseCordoneFromRobotMessage(map);
      if (strato == null || cordone == null) continue;
      parsed.add({
        'strato': strato,
        'cordone': cordone,
      });
    }

    return parsed;
  }

  Future<void> _forwardExecutedCordoniToWebview(
      List<Map<String, int>> executedCordoni) async {
    try {
      await webviewDispatchFlutterMessage?.call({
        "action": "SET_EXECUTED_CORDONI",
        "executedCordoni": executedCordoni,
      });
    } catch (e) {
      printLog('[WEBVIEW] Errore invio SET_EXECUTED_CORDONI: $e');
    }
  }

  bool _ensureRobotReadyForAction(
    BuildContext? dialogContext, {
    required String actionLabel,
  }) {
    if (homeReachReceived) return true;

    final effectiveContext = dialogContext ?? context;
    if (effectiveContext != null) {
      Messenger.infoDialog(
        effectiveContext,
        'Attendere HOME',
        'Attendere il messaggio HOMEREACH prima di $actionLabel.',
        'OK',
      );
    }

    printLog('BLOCCO $actionLabel: in attesa di HOMEREACH');
    return false;
  }

  void _setPendingRobotTargetStatus(String? statusTarget) {
    pendingRobotTargetStatus = statusTarget;
    isPausingResuming = statusTarget == 'WELDING' || statusTarget == 'PAUSED';
    isStopping = statusTarget == 'END';
  }

  void _resolvePendingRobotTargetStatus(String currentStatus) {
    final pending = pendingRobotTargetStatus;
    if (pending == null) return;

    final reachedTarget =
        (pending == 'WELDING' && currentStatus == 'WELDING') ||
            (pending == 'PAUSED' && currentStatus == 'PAUSED') ||
            (pending == 'END' &&
                (currentStatus == 'END' || currentStatus == 'INACTIVE'));

    if (reachedTarget) {
      _setPendingRobotTargetStatus(null);
    }
  }

  bool get isWeldingControlsVisible =>
      weldingStatus != weldingStatusInactive &&
      weldingStatus != weldingStatusEnd;

  bool get _isWeldingRunActive => startedWeldingOnce || stratoCominciato;

  bool get canPauseWelding =>
      _isWeldingRunActive &&
      !paused &&
      weldingStatus != weldingStatusPausing &&
      weldingStatus != weldingStatusInactive &&
      weldingStatus != weldingStatusEnd;

  bool get canResumeWelding =>
      _isWeldingRunActive &&
      paused &&
      weldingStatus != weldingStatusInactive &&
      weldingStatus != weldingStatusEnd;

  bool get canStopWelding =>
      _isWeldingRunActive &&
      paused &&
      weldingStatus != weldingStatusInactive &&
      weldingStatus != weldingStatusEnd;

  bool get canReturnToPointSelection =>
      weldingStatus == weldingStatusEnd ||
      weldingStatus == weldingStatusInactive;

  String _normalizeWeldingStatus(dynamic rawStatus) {
    final normalized = rawStatus?.toString().trim().toUpperCase() ?? '';
    switch (normalized) {
      case 'START':
      case 'RUNNING':
        return weldingStatusWelding;
      case 'WELDING':
        return weldingStatusWelding;
      case 'PAUSING':
        return weldingStatusPausing;
      case 'PAUSE':
      case 'PAUSED':
        return weldingStatusPaused;
      case 'STOP':
      case 'STOPPED':
      case 'STOPPING':
      case 'DONE':
      case 'FINISHED':
      case 'END':
        return weldingStatusEnd;
      case 'IDLE':
      case 'READY':
      case 'INACTIVE':
        return weldingStatusInactive;
      default:
        return normalized;
    }
  }

  void _applyWeldingStatus(String normalizedStatus) {
    if (!weldingFlowStatuses.contains(normalizedStatus)) return;

    mySetState?.call(() {
      weldingStatus = normalizedStatus;

      switch (normalizedStatus) {
        case weldingStatusInactive:
        case weldingStatusEnd:
          paused = false;
          dashboardSetPaused?.call(paused);
          _setPendingRobotTargetStatus(null);
          stratoCominciato = false;
          startedWeldingOnce = false;
          break;
        case weldingStatusWelding:
          pageState = LaserPanelState.tipoSaldatura;
          paused = false;
          dashboardSetPaused?.call(paused);
          stratoCominciato = true;
          startedWeldingOnce = true;
          break;
        case weldingStatusPausing:
          pageState = LaserPanelState.tipoSaldatura;
          paused = false;
          dashboardSetPaused?.call(paused);
          stratoCominciato = true;
          startedWeldingOnce = true;
          break;
        case weldingStatusPaused:
          pageState = LaserPanelState.tipoSaldatura;
          paused = true;
          dashboardSetPaused?.call(paused);
          stratoCominciato = true;
          startedWeldingOnce = true;
          break;
      }
    });
  }

  void _logWeldUiState({required String sourceStatus}) {
    debugPrint(
      '[WELD_UI] status=$weldingStatus sourceStatus=$sourceStatus '
      'canPause=$canPauseWelding canResume=$canResumeWelding '
      'canStop=$canStopWelding visible=$isWeldingControlsVisible paused=$paused',
    );
  }

  bool get isControrotaiaSemplice =>
      controrotaiaModeValue == 'controrotaiasemplice';

  // Compatibilita con codice esistente: "lunga" = "controrotaiasemplice"
  bool get isControrotaiaLunga => isControrotaiaSemplice;

  String get controrotaiaModeValue {
    final raw = tipoControrotaia.trim().toLowerCase();
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
  bool get isPianoRotolamento => controrotaiaModeValue == 'piano';
  //
  //
  //
  TextEditingController get scostamentoStratoXFieldController =>
      scostamentoStratoX;

  TextEditingController get scostamentoStratoZFieldController =>
      scostamentoStratoZ;

  String get scostamentoStratoXValue =>
      scostamentoStratoXFieldController.text.trim();

  String get scostamentoStratoZValue =>
      scostamentoStratoZFieldController.text.trim();

  String get scostamentoStratoXLabel => 'Step Layer X (mm)';

  String get scostamentoStratoZLabel =>
      isPianoRotolamento ? 'Step Layer Y (mm)' : 'Step Layer Z (mm)';

  String get stepLayerOffsetLabel =>
      isPianoRotolamento ? 'Step Layer Z' : 'Step Layer Y';

  double get defaultStepLayerXByControrotaia =>
      isPianoRotolamento ? defaultScostamentoStratoX : 0.0;

  double get defaultStepLayerZByControrotaia =>
      isPianoRotolamento ? defaultScostamentoStratoZ : 0.0;

  void _syncScostamentoFieldDefaultsForCurrentMode({bool force = false}) {
    final defaultX = defaultStepLayerXByControrotaia.toString();
    final defaultZ = defaultStepLayerZByControrotaia.toString();

    if (force || scostamentoStratoX.text.trim().isEmpty) {
      scostamentoStratoX.text = defaultX;
    }

    if (force || scostamentoStratoZ.text.trim().isEmpty) {
      scostamentoStratoZ.text = defaultZ;
    }
  }

  void _syncOffsetInizioDefaultsForCurrentMode({bool force = false}) {
    final useZeroDefaults = controrotaiaModeValue == 'controrotaiasemplice' ||
        controrotaiaModeValue == 'piano';

    final defaults = useZeroDefaults
        ? _offsetInizioDefaultSemplicePiano
        : _offsetInizioDefaultDoppia;

    offsetinizio = List<int>.from(defaults);

    for (int i = 0;
        i < offsetinizioController.length && i < defaults.length;
        i++) {
      if (force || offsetinizioController[i].text.trim().isEmpty) {
        offsetinizioController[i].text = defaults[i].toString();
      }
    }
  }

  String get serverBaseUrl {
    final host = settings.ipServer.contains(':')
        ? settings.ipServer.split(':').first
        : settings.ipServer;
    return 'http://$host';
  }

  void openLastInterpolaResponseDebug() {
    if (context == null) return;
    final lastResponse = lastInterpolaResponseNotifier.value;
    if (lastResponse == null || lastResponse.isEmpty) return;
    Pager.push(
      context: context!,
      page: LaserSimulationPage(textToShow: lastResponse),
    );
  }

  void notifyPointsOrderChanged() {
    pointsOrderVersion.value = pointsOrderVersion.value + 1;
  }

  void setCanGeneratePoints(bool value) {
    if (canGeneratePointsNotifier.value == value) return;
    canGeneratePointsNotifier.value = value;
  }

  final box = HiveDiskEncoder();

  // Impostazioni - END

  // Log Window - Start
  String logString = "";
  String lastLogMessage = "";
  bool showLogWindow = false;
  double logWindowLeftPosition = 0.0;
  double logWindowTopPosition = 0.0;
  // Log Window - End

  bool stratoCominciato = false;

  // soundEnabled
  bool soundFXEnabled = false;

  // sending simulation points
  bool sendingSimulationPoints = false;

  bool loadingDati = false;
  bool initialized = false;

  // - - - - - - - - - - - . - - - - -
  Function? dashboardClear;
  Offset Function(double, double, bool)? dashboardSetDStart;
  Offset Function(double, double, bool)? dashboardInitDStartWithoutMove;
  Function(Point)? dashboardAddExternalPoint;
  Function(String, Offset)? dashboardAddExternalPointRecalculated;
  Function(bool)? dashboardSetCanMoveRobot;
  Function(double, double)? dashboardSetHomeReferenceCenter;
  Offset? Function(double, double)? dashboardCalculatePointPosition;
  Offset Function()? dashboardGetPoint;
  Function(double, double)? dashboardUpdateCursorFromExternalCoordinates;
  Function(Offset)? dashboardUpdateCursorPosition;
  Function(bool)? dashboardSetPaused;
  Function? dashboardRedrawPoints;
  bool Function()? dashboardHasRobotReferenceFrame;
  Future<void> Function(dynamic data)? webviewDispatchFlutterMessage;

  // Flag per congelere l'aggiornamento del cursore dopo che è stato aggiunto un punto
  DateTime? freezeCursorUntil;

  final int GAS_WIRE_TIMEOUT_SECONDS = 2;

  TextStyle h = TextStyle();
  TextStyle l = TextStyle();
  FocusNode focusNode = FocusNode();
  Socket? socket;
  StreamSubscription? socketSubscription;
  bool isDisposing = false;
  String socketReadBuffer = "";
  double step = 10;
  double stepx = 1;
  double deltax = 0, deltay = 0, deltaz = 0;

  // ─── Limite robot attivo ──────────────────────────────────────────────────
  // Restituisce la riga di limite più specifica (limiteZDown più alto tra quelle
  // dove limiteZDown > 0 e posizioneRobot.z <= limiteZDown) per il tipoControrotaia
  // corrente. Ritorna null se nessuna riga è applicabile.
  LaserRobotLimite? get activeLimiteRow {
    final tipo = controrotaiaModeValue;
    LaserRobotLimite? best;
    for (final r in settings.limiti) {
      if (r.limiteZDown == 0) continue;
      final tipoR = r.tipoControrotaia.trim().toLowerCase();
      final tipoN = tipo.trim().toLowerCase();
      if (tipoR != tipoN && tipoR.isNotEmpty && tipoN.isNotEmpty) continue;
      if (posizioneRobot.z > r.limiteZDown) continue;
      if (best == null || r.limiteZDown > best.limiteZDown) {
        best = r;
      }
    }
    return best;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // Step effettivi che tengono conto del limite attivo.
  // Se il campo del limite è 0 (nessun limite) o nessuna riga attiva → valore corrente.
  // Se impostato → min(corrente, valoreLimite).
  double get effectiveStepUp {
    final base = math.min(step, 30.0);
    final lim = activeLimiteRow?.stepUp ?? 0;
    return (lim > 0) ? math.min(base, lim) : base;
  }

  double get effectiveStepDown {
    final base = math.min(step, 30.0);
    final lim = activeLimiteRow?.stepDown ?? 0;
    return (lim > 0) ? math.min(base, lim) : base;
  }

  double get effectiveStepUpSx {
    final base = math.min(step, 30.0);
    final lim = activeLimiteRow?.stepUpSx ?? 0;
    return (lim > 0) ? math.min(base, lim) : base;
  }

  double get effectiveStepUpDx {
    final base = math.min(step, 30.0);
    final lim = activeLimiteRow?.stepUpDx ?? 0;
    return (lim > 0) ? math.min(base, lim) : base;
  }

  double get effectiveStepDownSx {
    final base = math.min(step, 30.0);
    final lim = activeLimiteRow?.stepDownSx ?? 0;
    return (lim > 0) ? math.min(base, lim) : base;
  }

  double get effectiveStepDownDx {
    final base = math.min(step, 30.0);
    final lim = activeLimiteRow?.stepDownDx ?? 0;
    return (lim > 0) ? math.min(base, lim) : base;
  }

  double get effectiveStepLeft {
    final lim = activeLimiteRow?.stepLeft ?? 0;
    return (lim > 0) ? math.min(step, lim) : step;
  }

  double get effectiveStepRight {
    final lim = activeLimiteRow?.stepRight ?? 0;
    return (lim > 0) ? math.min(step, lim) : step;
  }

  // Step Y per i bottoni ↑↓ di LaserJoystickX (base = step corrente).
  double get effectiveStepY {
    final lim = activeLimiteRow?.stepY ?? 0;
    return (lim > 0) ? math.min(step, lim) : step;
  }

  // Range massimo per lo slider jog verticale (LaserJog, base fissa = 2.0).
  double get effectiveJogMaxStep {
    final lim = activeLimiteRow?.stepY ?? 0;
    return (lim > 0) ? math.min(2.0, lim) : 2.0;
  }

  bool _isEffectiveLimited(double effective, double base) {
    return (base - effective) > 0.0001;
  }

  bool get isStepUpLimited =>
      _isEffectiveLimited(effectiveStepUp, math.min(step, 30.0));
  bool get isStepDownLimited =>
      _isEffectiveLimited(effectiveStepDown, math.min(step, 30.0));
  bool get isStepUpSxLimited =>
      _isEffectiveLimited(effectiveStepUpSx, math.min(step, 30.0));
  bool get isStepUpDxLimited =>
      _isEffectiveLimited(effectiveStepUpDx, math.min(step, 30.0));
  bool get isStepDownSxLimited =>
      _isEffectiveLimited(effectiveStepDownSx, math.min(step, 30.0));
  bool get isStepDownDxLimited =>
      _isEffectiveLimited(effectiveStepDownDx, math.min(step, 30.0));
  bool get isStepLeftLimited => _isEffectiveLimited(effectiveStepLeft, step);
  bool get isStepRightLimited => _isEffectiveLimited(effectiveStepRight, step);
  bool get isStepYLimited => _isEffectiveLimited(effectiveStepY, step);

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  bool canMoveRobot = true;
  Point? homeReferencePosition;
  bool homeReachReceived = false;
  List<String> messagesList = [];
  int robotIsStill = 0;
  bool verticalLock = false;
  int dashboardResetVersion = 0;

  void onInit() {
    print("INITTTT");
    if (!initialized) {
      initialized = true;
    } else {
      redrawPoints();
      return;
    }
    _applyDirectionDefaultsForTipo();
    //
    //
    loadingDati = false;
    connectionStatus = UNLOCK_PAGE_FOR_TEST;
    //
    //
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //
      //
      //
      if (UNLOCK_PAGE_FOR_TEST) {
        mySetState?.call(() {
          loadingDati = false;
        });
      }

      restoreStratiEseguiti();
      await deleteSafePosition();
      loadPanelConfig();

      _syncOffsetInizioDefaultsForCurrentMode(force: true);

      for (int i = 0; i < offsetfine.length; i++) {
        offsetfineController[i].text = offsetfine[i].toString();
      }
      for (int i = 0; i < larghezzasaldatura.length; i++) {
        larghezzasaldaturaController[i].text = larghezzasaldatura[i].toString();
      }
      for (int i = 0; i < velocitasaldatura.length; i++) {
        velocitaSaldaturaController[i].text = velocitasaldatura[i].toString();
      }
      for (int i = 0; i < offsetstrato.length; i++) {
        offsetStratoController[i].text = offsetstrato[i].toString();
      }
      robotIsStill = 0;

      sovrapposizioneCordone.text = "$defaultSovrapposizioneCordone";
      larghezzaCordone.text = "$defaultLarghezzaCordone";
      _syncScostamentoFieldDefaultsForCurrentMode(force: true);
      waitPreUscitaController.text = "$defaultWaitPreUscita";
      waitFineCordoneController.text = "$defaultWaitFineCordone";
      waitLaseronStartCordoneController.text =
          "$defaultWaitLaseronStartCordone";
      minLengthCordoniController.text = "$defaultMinLengthCordoni";
      velocitaAvvicinamentoController.text = "$defaultVelocitaAvvicinamento";
      velocitaAllontanamentoController.text = "$defaultVelocitaAllontanamento";
      alternata = false;

      buildReconnectionTimer();
    });
  }

  void onDispose() {
    isDisposing = true;
    context = null;
    mySetState = null;
    webviewDispatchFlutterMessage = null;
    closeSocket();
    destroyReconnectionTimer();
  }

  void setScrollViewEnabledScrolling({required newValue}) {
    mySetState?.call(() {
      scrollViewEnabledScrolling = newValue;
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> sendMessageToRobot(
    Map<String, dynamic> message, {
    Duration postSendDelay = const Duration(seconds: 2),
  }) async {
    print("[SENTMESSAGE] : $message");
    if (socket == null) {
      return;
    }

    final command = message['f']?.toString().trim().toUpperCase();

    if (command == 'GOTOSAFEPOSITION') {
      debugPrint(
        '[SAFE_POSITION][TX] Command=GOTOSAFEPOSITION payload=${jsonEncode(message)}',
      );
    }

    if (command == 'SETSAFEPOSITION') {
      debugPrint(
        '[SET_SAFE_POSITION][TX] Command=SETSAFEPOSITION payload=${jsonEncode(message)}',
      );
    }

    if (command == 'MOVETO') {
      debugPrint('$moveToDebugLogPrefix payload=${jsonEncode(message)}');

      final point = message['point'];
      if (point is Point) {
        debugPrint(
          '$moveToDebugLogPrefix point '
          'x=${point.x} y=${point.y} z=${point.z} '
          'j1=${point.j1} j2=${point.j2} j3=${point.j3} '
          'order=${point.order} dashboard=${point.dashboardPosition}',
        );
      } else {
        debugPrint('$moveToDebugLogPrefix pointRaw=$point');
      }

      if (disableMoveToRobotSend) {
        debugPrint('$moveToDebugLogPrefix DRY_RUN ENABLED: MOVETO non inviato');
        return;
      }
    }

    final encodedMessage = jsonEncode(message);
    socket?.write(encodedMessage);
    if (postSendDelay > Duration.zero) {
      await Future.delayed(postSendDelay);
    }
  }

  void setRobotCanMove(bool value) {
    if (canMoveRobot == value) return;

    mySetState?.call(() {
      canMoveRobot = value;
    });
    dashboardSetCanMoveRobot?.call(value);
  }

  Future<void> sendJoystickMoveCommand(
    Map<String, dynamic> message, {
    String ignoredLog = 'Ignoro Joystick',
    Duration fallbackUnlockDelay = const Duration(milliseconds: 1200),
  }) async {
    if (!canMoveRobot) {
      printLog(ignoredLog);
      return;
    }

    setRobotCanMove(false);
    try {
      await sendMessageToRobot(message);
    } finally {
      Future.delayed(fallbackUnlockDelay, () {
        if (!canMoveRobot) {
          setRobotCanMove(true);
        }
      });
    }
  }

  Point _copyRobotPosition(Point point) {
    return Point(
      x: point.x,
      y: point.y,
      z: point.z,
      j1: point.j1,
      j2: point.j2,
      j3: point.j3,
      jt1: point.jt1,
      jt2: point.jt2,
      jt3: point.jt3,
      jt4: point.jt4,
      jt5: point.jt5,
      jt6: point.jt6,
    );
  }

  int? _parseFrameEpoch(dynamic rawValue) {
    if (rawValue == null) return null;
    if (rawValue is int) return rawValue;
    if (rawValue is num) return rawValue.toInt();
    return int.tryParse(rawValue.toString().trim());
  }

  bool get canUseSavedPointsInCurrentFrame => !hasFrameMismatch;

  void _updateFrameValidationFromCurrentState({String? reason}) {
    if (reason != null && reason.trim().isNotEmpty) {
      lastFrameReason = reason.trim();
    }

    if (points.points.isEmpty ||
        pointsFrameEpoch == null ||
        currentRobotFrameEpoch == null) {
      hasFrameMismatch = false;
      return;
    }

    hasFrameMismatch = pointsFrameEpoch != currentRobotFrameEpoch;
  }

  bool _ensurePointsFrameIsValidForAction(
    BuildContext? dialogContext, {
    required String actionLabel,
  }) {
    _updateFrameValidationFromCurrentState();

    if (canUseSavedPointsInCurrentFrame) return true;

    final effectiveContext = dialogContext ?? context;
    final reasonSuffix =
        (lastFrameReason != null && lastFrameReason!.trim().isNotEmpty)
            ? ' (motivo: ${lastFrameReason!})'
            : '';

    if (effectiveContext != null) {
      Messenger.infoDialog(
        effectiveContext,
        'Frame non allineato',
        'I punti salvati appartengono a un frame robot diverso: '
            '${pointsFrameEpoch ?? '-'} != ${currentRobotFrameEpoch ?? '-'}\n\n'
            'Operazione $actionLabel bloccata. Riprendere i punti.'
            '$reasonSuffix',
        'OK',
      );
    }

    printLog(
      'BLOCCO $actionLabel: frame mismatch points=${pointsFrameEpoch ?? '-'} '
      'robot=${currentRobotFrameEpoch ?? '-'}$reasonSuffix',
    );
    return false;
  }

  void _syncRobotMoveAvailabilityFromStatus() {
    const velocityTolerance = 0.01;
    final robotIsMoving =
        robotSpeed.any((speed) => speed.abs() > velocityTolerance);
    final samePosition = lastRobotPosition.isEqualTo(point: posizioneRobot);

    if (!robotIsMoving && samePosition) {
      robotIsStill++;
    } else {
      robotIsStill = 0;
    }

    if (!robotIsMoving && robotIsStill >= 1) {
      setRobotCanMove(true);
    }

    lastRobotPosition = _copyRobotPosition(posizioneRobot);
  }

  // * - * - * - * - * - * - * - * - * - *  Laser Globals - End - * - * - * - * - * - * - * - * - * - *

  Future<void> connettiRobot() async {
    print("CONNETTI ROBOT");
    await startConnection();
  }

  Future<void> resetPunti() async {
    points.deleteAllPoints();
    freezeCursorUntil = null;
    pointsFrameEpoch = null;
    hasFrameMismatch = false;
    lastFrameReason = null;

    mySetState?.call(() {
      allPointsRestored = false;
      allPointsSet = false;
    });

    resetStratiEseguiti();
    await sendMessageToRobot({"f": "RESETSAFEPOSITION"});
  }

  void replacePunti({required PointsFree newPoints}) {
    freezeCursorUntil = null;
    mySetState?.call(() {
      points = newPoints;
    });
    notifyPointsOrderChanged();
    redrawPoints();
    restoreStratiEseguiti();
  }

  Future<void> resetPoints() async {
    mySetState?.call(() {
      points.deleteAllPoints();
    });
    pointsFrameEpoch = null;
    hasFrameMismatch = false;
    lastFrameReason = null;
    notifyPointsOrderChanged();
    await sendMessageToRobot({"f": "RESETSAFEPOSITION"});
  }

  void resetFrame() {
    mySetState?.call(() {
      frameWidth = 0;
      frameHeight = 0;
      frameSet = false;
    });
  }

  final ValueNotifier<SafePosition?> safePositionNotifier = ValueNotifier(null);
  SafePosition? get currentSafePosition => safePositionNotifier.value;

  /// Flag ricevuto dal robot via RobotStatus.SafePosition (null = mai ricevuto).
  final ValueNotifier<bool?> robotSafePositionFlagNotifier =
      ValueNotifier(null);

  /// Ultimo valore raw ricevuto da RobotStatus.SafePosition.
  /// Contiene solo payload JSON valido (Map) quando disponibile.
  dynamic robotSafePositionCurrentRaw;

  /// Ultima SafePosition valida memorizzata lato app.
  /// Serve come fallback per RESTORESAFEPOSITION dopo reboot robot.
  Map<String, dynamic>? appSafePositionMemoryRaw;

  /// true se la safe position risulta impostata.
  /// Valida solo se confermata da stato robot.
  /// IS SAFE POSITION THERE
  bool get effectiveHasSafePosition {
    final hasSafe = robotSafePositionFlagNotifier.value == true;
    debugPrint(
      '[SAFE_TRACE][HAS] robotFlag=${robotSafePositionFlagNotifier.value} '
      'local=${currentSafePosition != null} resolved=$hasSafe',
    );
    return hasSafe;
    // return true;
  }

  Map<String, dynamic>? _normalizeSafePositionPayload(dynamic rawSafePosition) {
    debugPrint(
      '[SAFE_TRACE][NORMALIZE][IN] type=${rawSafePosition.runtimeType} value=$rawSafePosition',
    );

    if (rawSafePosition == null || rawSafePosition == false) {
      debugPrint('[SAFE_TRACE][NORMALIZE][OUT] null (raw null/false)');
      return null;
    }

    dynamic candidate = rawSafePosition;
    if (candidate is String) {
      final trimmed = candidate.trim();
      if (trimmed.isEmpty ||
          trimmed.toLowerCase() == 'false' ||
          trimmed.toLowerCase() == 'null') {
        debugPrint(
            '[SAFE_TRACE][NORMALIZE][OUT] null (string empty/false/null)');
        return null;
      }
      try {
        candidate = json.decode(trimmed);
      } catch (_) {
        debugPrint('[SAFE_TRACE][NORMALIZE][OUT] null (string not json)');
        return null;
      }
    }

    if (candidate is! Map) {
      debugPrint('[SAFE_TRACE][NORMALIZE][OUT] null (not map)');
      return null;
    }

    final normalized = Map<String, dynamic>.from(candidate);
    if (normalized.isEmpty) {
      debugPrint('[SAFE_TRACE][NORMALIZE][OUT] null (empty map)');
      return null;
    }

    debugPrint('[SAFE_TRACE][NORMALIZE][OUT] map=$normalized');
    return normalized;
  }

  bool? _extractSafePositionFlag(dynamic rawSafePosition) {
    if (rawSafePosition == null) return null;

    if (rawSafePosition is bool) return rawSafePosition;
    if (rawSafePosition is num) return rawSafePosition != 0;

    if (rawSafePosition is String) {
      final normalized = rawSafePosition.trim().toLowerCase();
      if (normalized.isEmpty || normalized == 'null') return null;
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }

    final derived = _normalizeSafePositionPayload(rawSafePosition) != null;
    debugPrint(
      '[SAFE_TRACE][FLAG] derived=$derived type=${rawSafePosition.runtimeType} value=$rawSafePosition',
    );
    return derived;
  }

  Map<String, dynamic>? _safePositionPayloadForRobotCommands() {
    final normalizedRobotSafePosition =
        _normalizeSafePositionPayload(robotSafePositionCurrentRaw);
    if (normalizedRobotSafePosition != null) {
      debugPrint(
        '[SAFE_TRACE][PAYLOAD] source=robot value=$normalizedRobotSafePosition',
      );
      return normalizedRobotSafePosition;
    }

    final normalizedAppSafePosition =
        _normalizeSafePositionPayload(appSafePositionMemoryRaw);
    if (normalizedAppSafePosition != null) {
      debugPrint(
        '[SAFE_TRACE][PAYLOAD] source=app-memory value=$normalizedAppSafePosition',
      );
      return normalizedAppSafePosition;
    }

    debugPrint('[SAFE_TRACE][PAYLOAD] source=none value=null');
    return null;
  }

  void _storeRobotSafePositionCurrent(dynamic rawSafePosition) {
    debugPrint(
      '[SAFE_TRACE][ROBOT_STATUS_SAFE][IN] type=${rawSafePosition.runtimeType} value=$rawSafePosition',
    );
    final normalizedSafePosition =
        _normalizeSafePositionPayload(rawSafePosition);
    if (normalizedSafePosition != null) {
      robotSafePositionCurrentRaw = normalizedSafePosition;
      appSafePositionMemoryRaw = normalizedSafePosition;
      robotSafePositionFlagNotifier.value = true;
      debugPrint(
        '[SAFE_TRACE][ROBOT_STATUS_SAFE][STORE] storedMap=$normalizedSafePosition appMemory=$appSafePositionMemoryRaw flag=true',
      );
      return;
    }

    robotSafePositionFlagNotifier.value =
        _extractSafePositionFlag(rawSafePosition);
    if (robotSafePositionFlagNotifier.value != true) {
      robotSafePositionCurrentRaw = null;
    }
    debugPrint(
      '[SAFE_TRACE][ROBOT_STATUS_SAFE][STORE] storedMap=$robotSafePositionCurrentRaw '
      'appMemory=$appSafePositionMemoryRaw '
      'flag=${robotSafePositionFlagNotifier.value}',
    );
  }

  Future<void> _restoreSafePositionOnHomeReachIfAvailable() async {
    debugPrint('[SAFE_TRACE][RESTORE][HOME] trigger=HOMEREACH');
    final currentValue = _safePositionPayloadForRobotCommands();
    if (currentValue == null) {
      debugPrint('[SAFE_TRACE][RESTORE][HOME] skip=no valid payload');
      return;
    }

    debugPrint('[SAFE_TRACE][RESTORE][HOME] send payload=$currentValue');
    debugPrint(
      '[SAFE_TRACE][RESTORE][TX] sending RESTORESAFEPOSITION with current=$currentValue',
    );

    await sendMessageToRobot({
      "f": "RESTORESAFEPOSITION",
      "current": currentValue,
    });
  }

  void redrawPoints() {
    dashboardClear?.call();

    if (points.points.isEmpty) {
      printLog("- - - - - - -> NO POINTS");
      return;
    }

    if (homeReferencePosition == null) {
      printLog("- - - - - - -> HOME REFERENCE NOT SET");
      return;
    }

    dashboardSetHomeReferenceCenter?.call(
      homeReferencePosition!.x,
      isPianoRotolamento
          ? homeReferencePosition!.y * -1
          : homeReferencePosition!.z,
    );

    dashboardRedrawPoints?.call();

    mySetState?.call(() {
      canMoveRobot = true;
    });
    dashboardSetCanMoveRobot?.call(true);
  }

  void ensureDashboardRobotReferenceFrame() {
    if (!homeReachReceived) return;
    if (homeReferencePosition == null) return;

    final hasReferenceFrame = dashboardHasRobotReferenceFrame?.call() ?? false;
    if (hasReferenceFrame) return;

    dashboardSetHomeReferenceCenter?.call(
      homeReferencePosition!.x,
      isPianoRotolamento
          ? homeReferencePosition!.y * -1
          : homeReferencePosition!.z,
    );
  }

  void _upsertPoint(Point point) {
    for (final existingPoint in points.points) {
      if (!existingPoint.isEqualTo(point: point)) continue;

      existingPoint.dashboardPosition ??= point.dashboardPosition;
      existingPoint.order ??= point.order;
      existingPoint.isFirst = existingPoint.isFirst || point.isFirst;
      notifyPointsOrderChanged();
      return;
    }

    points.add(point: point);
    notifyPointsOrderChanged();
  }

  PointsFree _mergeLocalOrdersWithIncomingPoints({
    required PointsFree incoming,
  }) {
    final currentPoints = points.points;
    final usedIncomingIndexes = <int>{};

    for (final localPoint in currentPoints) {
      ensureDashboardRobotReferenceFrame();
      if (localPoint.order == null) continue;

      for (int i = 0; i < incoming.points.length; i++) {
        if (usedIncomingIndexes.contains(i)) continue;

        final incomingPoint = incoming.points[i];
        if (incomingPoint.order != null) continue;

        if (_pointsMatchForOrder(localPoint, incomingPoint)) {
          incomingPoint.order = localPoint.order;
          usedIncomingIndexes.add(i);
          break;
        }
      }
    }

    return incoming;
  }

  bool _pointsMatchForOrder(Point a, Point b) {
    const tolerance = 0.05;
    return (a.x - b.x).abs() <= tolerance &&
        (a.y - b.y).abs() <= tolerance &&
        (a.z - b.z).abs() <= tolerance;
  }

  Future<void> processSocketChunk(String chunk) async {
    final sanitizedChunk = chunk.replaceAll("\r", "");
    if (sanitizedChunk.trim().isEmpty) return;

    socketReadBuffer += sanitizedChunk;

    final extraction = _extractCompleteJsonMessages(socketReadBuffer);
    socketReadBuffer = extraction.remainingBuffer;

    for (final message in extraction.messages) {
      await elaboraMessaggi(message);
    }
  }

  _SocketJsonExtraction _extractCompleteJsonMessages(String buffer) {
    final messages = <String>[];
    final workingBuffer = StringBuffer();
    var depth = 0;
    var startIndex = -1;
    var inString = false;
    var isEscaping = false;

    for (int index = 0; index < buffer.length; index++) {
      final char = buffer[index];

      if (startIndex == -1) {
        if (char.trim().isEmpty) {
          continue;
        }

        if (char == '{') {
          startIndex = index;
          depth = 1;
          inString = false;
          isEscaping = false;
        }
        continue;
      }

      if (isEscaping) {
        isEscaping = false;
        continue;
      }

      if (char == '\\') {
        if (inString) {
          isEscaping = true;
        }
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) {
        continue;
      }

      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          messages.add(buffer.substring(startIndex, index + 1));
          startIndex = -1;
        }
      }
    }

    if (startIndex != -1) {
      workingBuffer.write(buffer.substring(startIndex));
    }

    return _SocketJsonExtraction(
      messages: messages,
      remainingBuffer: workingBuffer.toString(),
    );
  }

  Future<void> elaboraMessaggi(String m) async {
    m = m.trim();
    if (m.isEmpty) return;
    m = m.replaceAll("\n", "");

    // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
    // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
    // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
    try {
      // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
      // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
      // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
      Map<String, dynamic> j = jsonDecode(m);
      // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
      // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
      // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

      print(j);

      if (j['MSG'] != null) {
        // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
        // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
        // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
        if (j['MSG']['f'] != null) {
          // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
          // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
          // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
          final messageFunctionRaw = j['MSG']['f']?.toString().trim();
          final normalizedMessageFunction = messageFunctionRaw?.toLowerCase();
          if (normalizedMessageFunction == 'robotstatus') {
            j['MSG']['f'] = 'RobotStatus';
          }
          if (normalizedMessageFunction == 'resetsafeposition') {
            j['MSG']['f'] = 'ResetSafePosition';
          }
          if (normalizedMessageFunction == 'webview_message') {
            j['MSG']['f'] = 'WEBVIEW_MESSAGE';
          }
          if (normalizedMessageFunction == 'statuscordoni') {
            j['MSG']['f'] = 'statusCordoni';
          }

          switch (j['MSG']['f']) {
            // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
            // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
            // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

            case 'listening':
              print("PASSO DI QUI 789236478932478932");
              //
              //
              final modalita = direzioneCordoniNotifier.value == 'h'
                  ? 'orizzontale'
                  : 'verticale';
              //
              //
              printLog("INVIO SET MODE...");
              //
              //
              await Future.delayed(Duration(milliseconds: 1500));
              //
              //
              await sendMessageToRobot(
                  {"f": "SETMODE", "tipo_controrotaia": controrotaiaModeValue});
              //
              //
              break;

            case 'getPoint':
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

              final point = j['MSG']['Point'];
              final positionJ = j['MSG']['PositionJ'];
              List<double>? positionJArray;
              PointJ? pointj;

              if (positionJ != null) {
                try {
                  if (positionJ is String) {
                    // Se è una stringa, la decodifichiamo prima in una lista dinamica
                    final List<dynamic> decoded = jsonDecode(positionJ);
                    positionJArray =
                        decoded.map((e) => (e as num).toDouble()).toList();
                  } else if (positionJ is List) {
                    // Se è già una lista (formato JSON standard), la mappiamo in double
                    positionJArray =
                        positionJ.map((e) => (e as num).toDouble()).toList();
                  }
                } catch (e) {
                  // Gestione errore decodifica o cast
                  positionJArray = null;
                }
              }

              if (positionJArray != null) {
                pointj = PointJ(positionJArray);
              }

              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

              print("POSITON J ARRAY: $positionJArray");

              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

              print("GETPOINT: ${j['MSG']}");

              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
              // - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

              if (point != null) {
                final pointParsed = Point.fromJson(point);
                pointParsed.positionJ = pointj;
                print("FINAL POINT: ${pointParsed.toJson()}");
                final recalculatedDashboardPosition =
                    dashboardCalculatePointPosition?.call(
                  pointParsed.x,
                  isPianoRotolamento ? pointParsed.y * -1 : pointParsed.z,
                );
                if (recalculatedDashboardPosition != null) {
                  pointParsed.dashboardPosition = recalculatedDashboardPosition;
                }

                _upsertPoint(pointParsed);
                dashboardRedrawPoints?.call();
                _setCanTakePoint(true);
              } else {
                _setCanTakePoint(true);
              }

              break;
            case 'Movement':
              //
              if (j['MSG']['Status'] == "Home") {
                dashboardUpdateCursorPosition?.call(Offset(0, 0));
              }
              if (j['MSG']['Status'] == "MaintenanceDX") {
                // Snackbar rimosso
              }
              if (j['MSG']['Status'] == "MaintenanceSX") {
                // Snackbar rimosso
              }
              if (j['MSG']['Status'] == "Clean") {
                // Snackbar rimosso
              }
              if (j['MSG']['Status'] == "Stopped") {
                dashboardSetPaused?.call(false);
                // Snackbar rimosso
              }
              mySetState?.call(() {
                canMoveRobot = true;
              });
              dashboardSetCanMoveRobot?.call(true);
              break;

            case 'WeldInfo':
              final currentCordone = _parseCordoneFromRobotMessage(j['MSG']);
              mySetState?.call(() {
                //
                //
                if (j['MSG']['LaserStatus'] != null) {
                  laserStatus = j['MSG']['LaserStatus'];
                }
                if (currentCordone != null) {
                  cordone = currentCordone;
                }
                if (j['MSG']['Strato'] != null &&
                    j['MSG']['executionTime'] != null) {
                  final numeroStrato = j['MSG']['Strato'];
                  final executionTime = j['MSG']['executionTime'];
                  printLog(
                      "Strato Eseguito: $numeroStrato in ${executionTime}s.");
                  if (stratiEseguiti[settings.serialeRobot] != null) {
                    stratiEseguiti[settings.serialeRobot]![numeroStrato]
                        .eseguito = true;
                    stratiEseguiti[settings.serialeRobot]![numeroStrato]
                        .durata = executionTime;
                  }
                }
                if (j['MSG']['numerocordonitotale'] != null) {
                  numerocordonitotale =
                      int.parse(j['MSG']['numerocordonitotale']);
                }
                if (j['MSG']['cordoneiniziale'] != null) {
                  cordoneiniziale = int.parse(j['MSG']['cordoneiniziale']);
                }
                if (j['MSG']['cordonefinale'] != null) {
                  cordonefinale = int.parse(j['MSG']['cordonefinale']);
                }
              });
              break;
            case 'Weld':
              final currentCordone = _parseCordoneFromRobotMessage(j['MSG']);
              mySetState?.call(() {
                if (currentCordone != null) {
                  cordone = currentCordone;
                }
                canMoveRobot = true;
                dashboardSetCanMoveRobot?.call(true);
              });
              break;
            case 'statusCordoni':
              final currentStrato = _parseStratoFromRobotMessage(j['MSG']);
              final executedCordoni =
                  _parseExecutedCordoniFromRobotMessage(j['MSG']);

              mySetState?.call(() {
                if (currentStrato != null) {
                  strato = currentStrato;
                }
              });

              await _forwardExecutedCordoniToWebview(executedCordoni);
              break;
            case 'SafePosition':
              try {
                print(json.encode(j));

                final msg = j['MSG'] as Map<String, dynamic>;
                final orientation =
                    (msg['DXSX'] ?? (armPosition == true ? 'DX' : 'SX'))
                        .toString();
                //
                dynamic positionRaw = msg['coords'];
                if (positionRaw != null && positionRaw is String) {
                  positionRaw = json.decode(positionRaw);
                }
                //
                if (positionRaw is! List) {
                  throw Exception('SafePosition payload non valido');
                }

                final position = List<double>.from(
                    positionRaw.map((x) => (x as num).toDouble()));

                final safePosition =
                    SafePosition(orientation: orientation, position: position);
                safePositionNotifier.value = safePosition;
                _storeRobotSafePositionCurrent(safePosition.toJson());
                // Snackbar rimosso
              } catch (e) {
                print(e);
                // Snackbar rimosso
              }
              break;
            case 'ResetSafePosition':
              debugPrint(
                '[SAFE_POSITION][RX] Comando resetSafePosition ricevuto, elimino safe position locale',
              );
              await deleteSafePosition();
              break;
            case 'FrameState':
              try {
                final msg = j['MSG'] as Map<String, dynamic>;
                final frameEpoch =
                    _parseFrameEpoch(msg['frameEpoch'] ?? msg['FrameEpoch']);
                if (frameEpoch != null) {
                  currentRobotFrameEpoch = frameEpoch;
                }

                _updateFrameValidationFromCurrentState(
                    reason: msg['frameReason']?.toString());
              } catch (e) {
                print("FRAME STATE ERROR: $e");
              }
              break;
            case 'FrameChanged':
              try {
                final msg = j['MSG'] as Map<String, dynamic>;
                final frameEpoch =
                    _parseFrameEpoch(msg['frameEpoch'] ?? msg['FrameEpoch']);
                if (frameEpoch != null) {
                  currentRobotFrameEpoch = frameEpoch;
                }

                _updateFrameValidationFromCurrentState(
                    reason: msg['frameReason']?.toString());
              } catch (e) {
                print("FRAME CHANGED ERROR: $e");
              }
              break;
            case 'RobotStatus':
              print(j['MSG']);
              try {
                print(
                    "[ROBOT_STATUS] raw MSG keys: ${(j['MSG'] as Map?)?.keys.toList()}");
                print("[ROBOT_STATUS] raw MSG: ${j['MSG']}");

                // Aggiorna il flag SafePosition del robot se presente nel messaggio.
                final rawSafeFlag = j['MSG']['SafePosition'];
                if ((j['MSG'] as Map).containsKey('SafePosition')) {
                  debugPrint(
                    '[SAFE_TRACE][ROBOT_STATUS] SafePosition field present value=$rawSafeFlag',
                  );
                  _storeRobotSafePositionCurrent(rawSafeFlag);
                } else {
                  debugPrint(
                    '[SAFE_TRACE][ROBOT_STATUS] SafePosition field missing, keep previous map=$robotSafePositionCurrentRaw flag=${robotSafePositionFlagNotifier.value}',
                  );
                }

                final robotStatus =
                    j['MSG']['Status']?.toString().trim().toUpperCase();
                final incomingArmPosition =
                    j['MSG']['armPosition']?.toString().trim().toUpperCase();

                if (incomingArmPosition == 'DX') {
                  mySetState?.call(() {
                    armPosition = true;
                  });
                } else if (incomingArmPosition == 'SX') {
                  mySetState?.call(() {
                    armPosition = false;
                  });
                }

                if (robotStatus == 'HOMEREACH') {
                  debugPrint(
                    '[SAFE_TRACE][HOMEREACH][RX] RobotStatus HOMEREACH received armPosition=$incomingArmPosition',
                  );
                  final homePosition = _parseRobotPositionList(
                      j['MSG']['position'] ?? j['MSG']['Position']);

                  if (homePosition != null && homePosition.length >= 3) {
                    posizioneRobot.x = homePosition[0];
                    posizioneRobot.y = homePosition[1];
                    posizioneRobot.z = homePosition[2];
                    if (homePosition.length >= 6) {
                      posizioneRobot.j1 = homePosition[3];
                      posizioneRobot.j2 = homePosition[4];
                      posizioneRobot.j3 = homePosition[5];
                    }
                  }

                  homeReferencePosition = Point(
                    x: posizioneRobot.x,
                    y: posizioneRobot.y,
                    z: posizioneRobot.z,
                  );

                  mySetState?.call(() {
                    if (incomingArmPosition == 'DX') {
                      armPosition = true;
                    } else if (incomingArmPosition == 'SX') {
                      armPosition = false;
                    }
                    homeReachReceived = true;
                  });

                  _setCanTakePoint(true);
                  setRobotCanMove(true);

                  dashboardSetHomeReferenceCenter?.call(
                    homeReferencePosition!.x,
                    isPianoRotolamento
                        ? homeReferencePosition!.y * -1
                        : homeReferencePosition!.z,
                  );
                  dashboardUpdateCursorPosition?.call(Offset.zero);

                  lastFrameReason = 'HOMEREACH';
                  _updateFrameValidationFromCurrentState(reason: 'HOMEREACH');

                  await _restoreSafePositionOnHomeReachIfAvailable();

                  break;
                }

                final p = jsonDecode(j['MSG']['Position']);
                final v = jsonDecode(j['MSG']['Velocity']);

                posizioneRobot.x = p[0];
                posizioneRobot.y = p[1];
                posizioneRobot.z = p[2];
                posizioneRobot.j1 = p[3];
                posizioneRobot.j2 = p[4];
                posizioneRobot.j3 = p[5];
                robotSpeed[0] = (v[0] * 100).roundToDouble() / 100;
                robotSpeed[1] = (v[1] * 100).roundToDouble() / 100;
                robotSpeed[2] = (v[2] * 100).roundToDouble() / 100;
                robotSpeed[3] = (v[3] * 100).roundToDouble() / 100;
                robotSpeed[4] = (v[4] * 100).roundToDouble() / 100;
                robotSpeed[5] = (v[5] * 100).roundToDouble() / 100;

                final frameEpoch = _parseFrameEpoch(
                    j['MSG']['frameEpoch'] ?? j['MSG']['FrameEpoch']);
                if (frameEpoch != null) {
                  currentRobotFrameEpoch = frameEpoch;
                }
                _updateFrameValidationFromCurrentState(
                    reason: j['MSG']['frameReason']?.toString());
                if (points.firstPoint() == null) {
                  // Prima del primo punto il cursore resta al centro del grafico.
                  dashboardUpdateCursorPosition?.call(Offset(0, 0));
                } else {
                  // Non aggiornare il cursore se è stato appena aggiunto un punto localmente
                  if (freezeCursorUntil == null ||
                      DateTime.now().isAfter(freezeCursorUntil!)) {
                    dashboardUpdateCursorFromExternalCoordinates?.call(
                        -1 * posizioneRobot.x,
                        isPianoRotolamento
                            ? posizioneRobot.y * -1
                            : posizioneRobot.z);
                  }
                }
                _syncRobotMoveAvailabilityFromStatus();

                final positionj = jsonDecode(j['MSG']['PositionJ']);
                //
                //
                if (positionj is List) {
                  //
                  //
                  if (positionj.length == 6) {
                    posizioneRobot.jt1 = positionj[0];
                    posizioneRobot.jt2 = positionj[1];
                    posizioneRobot.jt3 = positionj[2];
                    posizioneRobot.jt4 = positionj[3];
                    posizioneRobot.jt5 = positionj[4];
                    posizioneRobot.jt6 = positionj[5];
                  } else {
                    posizioneRobot.jt1 = 0;
                    posizioneRobot.jt2 = 0;
                    posizioneRobot.jt3 = 0;
                    posizioneRobot.jt4 = 0;
                    posizioneRobot.jt5 = 0;
                    posizioneRobot.jt6 = 0;
                  }
                } else {
                  posizioneRobot.jt1 = 0;
                  posizioneRobot.jt2 = 0;
                  posizioneRobot.jt3 = 0;
                  posizioneRobot.jt4 = 0;
                  posizioneRobot.jt5 = 0;
                  posizioneRobot.jt6 = 0;
                }

                final lastStrato = int.parse(j['MSG']['lastStrato']);
                final lastCordone = int.parse(j['MSG']['lastCordone']);

                mySetState?.call(() {
                  if (lastStrato >= 0) {
                    stratiEseguiti[settings.serialeRobot]![lastStrato]
                        .eseguito = true;
                    if (lastCordone >= 0) {
                      stratiEseguiti[settings.serialeRobot]![lastStrato]
                          .lastCordone = lastCordone;
                    }
                  }
                });
                if (j['MSG']['Paused'] != null) {
                  //
                  if (j['MSG']['Paused'] != paused) {
                    // printLog("RICEVUTO PAUSED: ${j['MSG']['Paused']}");
                    paused = j['MSG']['Paused'];
                  }
                  dashboardSetPaused?.call(paused);
                }

                if (j['MSG']['status'] != null) {
                  final currentStatus =
                      _normalizeWeldingStatus(j['MSG']['status']);
                  _resolvePendingRobotTargetStatus(currentStatus);
                  _applyWeldingStatus(currentStatus);
                  _logWeldUiState(sourceStatus: currentStatus);
                }

                if (j['MSG']['weldedLength'] != null &&
                    j['MSG']['weldTotalLength'] != null) {
                  mySetState?.call(() {
                    try {
                      totalWeldedLength =
                          double.parse(j['MSG']['weldedLength']);
                      totalWeldingLength =
                          double.parse(j['MSG']['weldTotalLength']);
                    } catch (e) {}
                  });
                }
              } catch (e) {
                print("ROBOT STATUS ERROR: $e");
              }
              break;
            case "ArmPositionStatus":
              final currentArmPosition = j["MSG"]["Status"];

              // print(
              //     " - - - - - - - - - - - - - - -> ARM POSITION: $currentArmPosition");

              if (currentArmPosition == "DX") {
                mySetState?.call(() {
                  armPosition = true;
                });
              } else if (currentArmPosition == "SX") {
                mySetState?.call(() {
                  armPosition = false;
                });
              } else if (currentArmPosition == "UNSET") {
                mySetState?.call(() {
                  // ARM POSITION UNSET
                  armPosition = null;
                });
              }
              if (armPosition != null) {
                final first = points.firstPoint();
                if (first != null) {
                  dashboardSetDStart?.call(
                      first.x,
                      isPianoRotolamento ? first.y * -1 : first.z,
                      armPosition!); // ci va posizione robot
                }
              } else {
                //print("Arm Position IS NULL");
              }

              break;
            case "Approach":
              mySetState?.call(() {
                if (j['MSG']['VerticalLock'] != null) {
                  try {
                    verticalLock = int.parse(j['MSG']['VerticalLock']) > 0;
                  } catch (e) {
                    verticalLock = false;
                  }
                } else {
                  verticalLock = false;
                }
              });

              break;
            case "FrameSet": // DIMENSIONI AREA DI LAVORO IMPOSTATE

              final int status = int.parse(j["MSG"]["Status"]);

              if (status > 0) {
                try {
                  final int width = j["MSG"]["Width"];
                  final int height = j["MSG"]["Height"];

                  mySetState?.call(() {
                    frameSet = true;
                    frameWidth = width;
                    frameHeight = height;
                  });
                } catch (e) {
                  printLog("FRAME: $e");
                }
              }
              break;

            case "RobotInfo":
              if (j["MSG"]["Model"] != null) {
                mySetState?.call(() {
                  robotModelRead = j["MSG"]["Model"];
                });
              }

              if (j["MSG"]["Serial"] != null) {
                mySetState?.call(() {
                  robotSerialRead = j["MSG"]["Serial"];
                });
              }
              break;
            case "FastAPIError":
              mySetState?.call(() {
                startedWeldingOnce = false;
                weldingStatus = weldingStatusInactive;
              });
              if (j["MSG"]["Error"] != null) {
                // Snackbar rimosso
              } else {
                // Generic / Default Error
                // Snackbar rimosso
              }

              if (j["MSG"]["Strato"] != null) {
                try {
                  final int errorStratoIndex = int.parse(j["MSG"]["Strato"]);
                  mySetState?.call(() {
                    stratiEseguiti[settings.serialeRobot]![errorStratoIndex]
                        .eseguito = false;
                  });
                } catch (e) {
                  print(e);
                }
              }

              break;

            case 'WEBVIEW_MESSAGE':
              await webviewDispatchFlutterMessage?.call(j['MSG']['data']);
              break;

            default:
              break;
          }
        }
      }
    } catch (e) {
      //
      print("[getPoint] ERROR: $e");
      //
      mySetState?.call(() {
        canMoveRobot = true;
      });
      dashboardSetCanMoveRobot?.call(true);
      _setCanTakePoint(true);
    }
  }

  Future<void> startConnection() async {
    //
    //
    print("[ Connecting ]");
    isDisposing = false;
    //
    //
    if (!UNLOCK_PAGE_FOR_TEST) {
      //
      //
      print("connected");
      //
      //
      try {
        //
        //
        socket = null;
        mySetState?.call(() {
          isConnectingToRobot = true;
        });
        //
        //
        socket = await Socket.connect(settings.ipRobot, 20002,
            timeout: Duration(seconds: 5));
        //
        //
        mySetState?.call(() {
          connectionStatus = true;
          isConnectingToRobot = false;
          homeReachReceived = false;
        });
        //
        //
        //
        printLog("SET MODE INVIATA");
        //
        //
        homeReferencePosition = null;
        setRobotCanMove(false);
        _setCanTakePoint(false);
        //
        //
        printLog("[ Connected ]");

        isGasActive = false;
        isWireActive = false;

        socketSubscription?.cancel();
        socketSubscription = socket?.listen(
          (data) {
            if (isDisposing) return;
            final chunk = String.fromCharCodes(data);
            mySetState?.call(() {
              message = chunk;
            });
            processSocketChunk(chunk);
          },
          onDone: () {
            if (isDisposing) return;
            printLog('[ Disconnected ]');
            socketReadBuffer = "";

            mySetState?.call(() {
              connectionStatus = false;
              isConnectingToRobot = false;
              homeReachReceived = false;
            });
            _setCanTakePoint(true);
            closeSocket();
          },
          onError: (e) {
            if (isDisposing) return;
            printLog('[ CONNECTION ERROR 1 ]');
            socketReadBuffer = "";
            closeSocket();

            mySetState?.call(() {
              connectionStatus = false;
              isConnectingToRobot = false;
              homeReachReceived = false;
            });
            _setCanTakePoint(true);
          },
        );
      } catch (e) {
        print(e);
        print("[ CONNECTION ERROR 2 ]");
        mySetState?.call(() {
          connectionStatus = false;
          isConnectingToRobot = false;
          homeReachReceived = false;
        });
      }
    }
  }

  void gasTouchedDown() async {
    if (!isGasActive) {
      isGasActive = true;
      await sendMessageToRobot({
        "f": "GAS-ON",
        "pin_laser": settings.pinLaser,
        "pin_gas": settings.pinGas,
        "pin_massa": settings.pinMassa,
      });
    }
  }

  void gasTouchedUp() {
    Timer(Duration(seconds: GAS_WIRE_TIMEOUT_SECONDS), () async {
      isGasActive = false;
      await sendMessageToRobot({"f": "GAS-OFF"});
    });
  }

  void filoTouchedDown() async {
    if (!isWireActive) {
      isWireActive = true;
      await sendMessageToRobot({
        "f": "WIRE-ON",
        "pin_laser": settings.pinLaser,
        "pin_gas": settings.pinGas,
        "pin_massa": settings.pinMassa,
      });
    }
  }

  void filoTouchedUp() {
    Timer(Duration(seconds: GAS_WIRE_TIMEOUT_SECONDS), () async {
      isWireActive = false;
      await sendMessageToRobot({"f": "WIRE-OFF"});
    });
  }

  void setStratoEseguito({required int indexStrato}) {
    // salvare strati su HIVE
    mySetState?.call(() {
      startedWeldingOnce = true;
      if (stratiEseguiti[settings.serialeRobot] != null) {
        stratiEseguiti[settings.serialeRobot]![indexStrato].eseguito = true;
      }
    });
    storeStratiEseguiti();
  }

  void initializeStratiEseguiti() {
    mySetState?.call(() {
      stratiEseguiti[settings.serialeRobot] = [
        StratoLaser(),
        StratoLaser(),
        StratoLaser(),
        StratoLaser(),
        StratoLaser(),
        StratoLaser(),
        StratoLaser(),
        StratoLaser(),
        StratoLaser(),
        StratoLaser(),
      ];
    });
  }

  void storeStratiEseguiti() {
    Map<String, dynamic> temp = {};
    stratiEseguiti.forEach((key, value) {
      temp[key] = value.map((e) => e.toJson()).toList();
    });

    final stratiEncoded = json.encode(temp);

    box.setString(
        value: stratiEncoded, key: Constants.HIVE_LASER_STRATI_ESEGUITI_KEY);
  }

  void restoreStratiEseguiti() {
    final stratiRaw =
        box.stringFor(key: Constants.HIVE_LASER_STRATI_ESEGUITI_KEY);

    if (stratiRaw != null && stratiRaw.trim() != "") {
      try {
        final decoded = json.decode(stratiRaw) as Map<String, dynamic>;
        final Map<String, List<StratoLaser>> tempStratiEseguiti = {};
        decoded.forEach((key, value) {
          tempStratiEseguiti[key] = stratoLaserListFromJson(json.encode(value));
        });

        mySetState?.call(
          () {
            stratiEseguiti = tempStratiEseguiti;
          },
        );
      } catch (e) {
        initializeStratiEseguiti();
      }
    } else {
      initializeStratiEseguiti();
    }
  }

  void printCurrentStratiEseguiti(String title) {
    print("");
    print("");
    print(title);
    stratiEseguiti.forEach((key, value) {
      for (var element in value) {
        print(
            " - - - > eseguito: ${element.eseguito}, durata: ${element.durata}");
      }
    });
    print("");
    print("");
  }

  List<StratoLaser>? get currentStratiEseguiti {
    if (stratiEseguiti[settings.serialeRobot] != null) {
      return stratiEseguiti[settings.serialeRobot];
    }
    return null;
  }

  void resetStratiEseguiti() {
    //
    //
    box.setString(value: "", key: Constants.HIVE_LASER_STRATI_ESEGUITI_KEY);
    //
    initializeStratiEseguiti();
  }

  Future<void> moveToPoint(Point point) async {
    if (!_ensurePointsFrameIsValidForAction(context, actionLabel: "MOVETO")) {
      return;
    }

    if (point.positionJ != null) {
      final messageMoveTo = {"f": "MOVETO", "point": point.positionJ!.toJson()};
      print("[MOVETO] : $messageMoveTo");
      await sendMessageToRobot(messageMoveTo);
    }
  }

  void onPointSelected(String e, BuildContext context) async {
    // se è il d_start e il movimento è assistito devo chiedere le dimensioni del frame
    if (e == "d_start" &&
        controllerMode == LaserControllerMode.movimentoAssistito) {
      print("[getPoint] PASSO QUI 1");
      final framesetResult = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => LaserFrameDimensionsDialog(
              widthController: frameWidthController,
              heightController: frameHeightController));

      if (framesetResult == 'confirm') {
        print("[getPoint] SETPOINT $e");
        await sendMessageToRobot({
          "f": "SETPOINT",
          "point": e,
          "allontanamento_x": settings.scostamentoX,
          "allontanamento_y": settings.scostamentoY,
          "allontanamento_z": settings.scostamentoZ,
          "assisted":
              controllerMode == LaserControllerMode.movimentoAssistito ? 1 : 0
        });
      }
    } else {
      print("[getPoint] PASSO QUI 2");
      print("[getPoint] $e");
      await sendMessageToRobot({
        "f": "SETPOINT",
        "point": e,
        "allontanamento_x": settings.scostamentoX,
        "allontanamento_y": settings.scostamentoY,
        "allontanamento_z": settings.scostamentoZ,
        "assisted":
            controllerMode == LaserControllerMode.movimentoAssistito ? 1 : 0,
      });
    }
  }

  void onSaldaStratoPressed(int p, BuildContext context) async {
    unfocusScreen();

    if (!_ensureRobotReadyForAction(context, actionLabel: "WELD")) {
      return;
    }

    if (armPosition == null) {
      Messenger.infoDialog(
          context,
          "Attenzione",
          "Posizione Destra / Sinistra del robot non impostata, non posso procedere",
          "OK");
      return;
    }

    if (!effectiveHasSafePosition) {
      Messenger.infoDialog(context, "Attenzione",
          "Posizione di sicurezza non impostata, non posso procedere", "OK");
      return;
    }

    if (currentSafePosition != null && armPosition != null) {
      final hasWrongOrientation =
          (currentSafePosition!.orientation == "DX" && !armPosition!) ||
              (currentSafePosition!.orientation == "SX" && armPosition!);
      //
      //
      if (hasWrongOrientation) {
        await deleteSafePosition();
        Messenger.infoDialog(
            context,
            "Attenzione",
            "Orientamento robot errata, riprendere Posizione di sicurezza",
            "OK");
        return;
      }
    }

    bool alternataTemp = false;
    final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              title: const Text("Conferma"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Inizio saldatura strato ${p + 1}?"),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text("Alternata"),
                    value: alternataTemp,
                    onChanged: (v) => setDialogState(() => alternataTemp = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.sagaBlue),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text("Annulla"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sagaBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text("Salda strato ${p + 1}"),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (confirmed) {
      alternata = alternataTemp;
      if (points.isEmpty) {
        // Snackbar rimosso
        return;
      }

      if (!_ensurePointsFrameIsValidForAction(context, actionLabel: "WELD")) {
        return;
      }

      int? startingCordone;

      if (stratiEseguiti[settings.serialeRobot]![p].lastCordone > 0) {
        //
        //
        //
        final confirmed = await Messenger.askMessage(
            context,
            "Conferma",
            "Ero arrivato al cordone ${stratiEseguiti[settings.serialeRobot]![p].lastCordone}, proseguo o ricomincio da capo?",
            "Prosegui da cordone ${stratiEseguiti[settings.serialeRobot]![p].lastCordone + 1}",
            "Ricomincia");
        //
        //
        //
        if (confirmed != null) {
          if (confirmed) {
            startingCordone =
                stratiEseguiti[settings.serialeRobot]![p].lastCordone;
          } else {
            startingCordone = 0;
          }
        }
      } else {
        startingCordone = 0;
      }
      //
      //
      //
      if (startingCordone == null) return;
      //
      //
      //
      strato = p;
      //
      //
      //
      mySetState?.call(() {
        totalWeldedLength = 0;
        totalWeldingLength = 0;
      });
      //
      //
      //
      // Entrambe le modalità usano l'ordinamento (perimetro mode)
      final List<Point> weldPoints = points.points
          .where((point) => point.order != null)
          .toList()
        ..sort((a, b) => a.order!.compareTo(b.order!));
      //
      //
      //
      final hasValidPointsCount =
          modalitaNuvola ? weldPoints.length >= 4 : weldPoints.length >= 2;
      if (!hasValidPointsCount) {
        Messenger.showMessageGenericError(
            context,
            modalitaNuvola
                ? "Numero punti non valido: servono almeno 4 punti perimetro"
                : "Numero punti non valido: usa almeno 2 punti",
            2);
        return;
      }
      final cordoneBase = [
        for (var i = 0; i < weldPoints.length; i++)
          if (weldPoints[i].isBase) i
      ];
      final cordoneLimite = [
        for (var i = 0; i < weldPoints.length; i++)
          if (weldPoints[i].isLimite) i
      ];
      if (modalitaNuvola) {
        if (cordoneBase.length < 2) {
          Messenger.showMessageGenericError(
              context, "Seleziona almeno 2 punti BASE", 2);
          return;
        }
        if (cordoneLimite.length < 2) {
          Messenger.showMessageGenericError(
              context, "Seleziona almeno 2 punti LIMITE", 2);
          return;
        }
      }
      //
      //
      //
      final puntiBase = weldPoints
          .map((point) =>
              [point.x, point.y, point.z, point.j1, point.j2, point.j3])
          .toList();
      final ordine = List<int>.generate(puntiBase.length, (index) => index);
      final stratoIndex = _currentStratoIndex();
      final larghezzaCordoneValue =
          _parseDoubleOrDefault(larghezzaCordone.text, defaultLarghezzaCordone);
      final sovrapposizioneValue = _parseDoubleOrDefault(
          sovrapposizioneCordone.text, defaultSovrapposizioneCordone);
      final stepCordoni =
          larghezzaCordoneValue * (1 - (sovrapposizioneValue / 100));
      final layerPayload =
          _buildLayeringPayloadByControrotaia(stratoIndex: stratoIndex);

      final modalita =
          (direzioneCordoniNotifier.value == 'h' ? 'orizzontale' : 'verticale');
      await playActivationSound();
      setStratoEseguito(indexStrato: p);
      //
      //
      //
      final elencoStepLayer = _buildElencoStepLayerPayload();
      //
      //
      //
      final safePositionDecoded = _safePositionPayloadForRobotCommands();
      //
      //
      //
      await sendMessageToRobot({
        "f": "WELD",
        "riempi_area": true,
        "execution_mode": "movel",
        "max_points_per_cordone": 5,
        "simplify_tolerance": 1.0,
        "ordine_cordoni": layerPayload["ordine_cordoni"],
        "verso_cordone": layerPayload["verso_cordone"],
        "punti_base": puntiBase,
        if (modalitaNuvola) ...{
          "cordone_base": cordoneBase,
          "cordone_limite": cordoneLimite,
          "ordine_perimetro": ordine,
        },
        "tipo_controrotaia": controrotaiaModeValue,
        "ordine": ordine,
        "modalita": modalita,
        "step_cordoni": stepCordoni,
        "offsetinizio": _parseDoubleOrDefault(
            offsetinizioController[stratoIndex].text,
            offsetinizio[stratoIndex].toDouble()),
        "offsetfine": _parseDoubleOrDefault(
            offsetfineController[stratoIndex].text,
            offsetfine[stratoIndex].toDouble()),
        "lastcordone": "$startingCordone",
        "strato": strato.toString(),
        "speed": velocitaSaldaturaController[strato].text.trim(),
        "step_layer_x": layerPayload["step_layer_x"],
        "step_layer_y": layerPayload["step_layer_y"],
        "step_layer_z": layerPayload["step_layer_z"],
        "elenco_step_layer": elencoStepLayer,
        "laseroff_wait_distacco": _parseDecimalStringOrDefault(
            waitPreUscitaController.text, defaultWaitPreUscita),
        "end_cordone_wait_laseroff": _parseDecimalStringOrDefault(
            waitFineCordoneController.text, defaultWaitFineCordone),
        "url": settings.ipServer,
        "pin_laser": settings.pinLaser,
        "pin_gas": settings.pinGas,
        "pin_massa": settings.pinMassa,
        "sovrapposizione_cordone": sovrapposizioneCordone.text.trim(),
        "larghezzacordone": larghezzaCordone.text.trim(),
        "laseron_wait_startcordone": _parseDecimalStringOrDefault(
            waitLaseronStartCordoneController.text,
            defaultWaitLaseronStartCordone),
        "min_length_cordoni": _parseDecimalStringOrDefault(
            minLengthCordoniController.text, defaultMinLengthCordoni),
        "velocita_avvicinamento": _parseDecimalStringOrDefault(
            velocitaAvvicinamentoController.text, defaultVelocitaAvvicinamento),
        "velocita_allontanamento": _parseDecimalStringOrDefault(
            velocitaAllontanamentoController.text,
            defaultVelocitaAllontanamento),
        "alternata": alternata,
        "safeposition": safePositionDecoded,
        "modalita_interpolazione": modalitaNuvola ? "nuvola" : "poligono",
        if (modalitaNuvola) ...{
          "use_nuvola": true,
          "quota_tassativa": true,
          "grid_only": true,
          "exact_tol": 0.001,
          "interp_method": nuvolaInterpMethodController.text.trim().isEmpty
              ? 'guided_loft_z'
              : nuvolaInterpMethodController.text.trim(),
          "smooth_kernel": "thin_plate",
          "smooth_lambda":
              double.tryParse(nuvolaSmoothLambdaController.text) ?? 0.000001,
          "interp_k": int.tryParse(nuvolaInterpKController.text) ?? 8,
          "interp_power": 2.0,
          "linear_candidate_k": 12,
          "debug_hull": false,
        },
      });
      //
      //
      //
    }
  }

  //
  //
  //
  String sovrapposizioneChecked() {
    try {
      final converted = double.parse(sovrapposizioneCordone.text);
      if (converted < 0) {
        return "0";
      } else if (converted > 0) {
        return "100";
      } else {
        return converted.toStringAsFixed(3);
      }
    } catch (e) {
      return "$sovrapposizioneCordone";
    }
  }

  Future<void> resumePressed({required BuildContext context}) async {
    unfocusScreen();
    //
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    //
    if (!canResumeWelding) {
      return;
    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    final result = await _showResumeCordoniDialog(
      context: context,
      cordoneCorrente: cordone,
      numerocordonitotale: numerocordonitotale,
    );
    if (result == null) {
      return;
    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    final descConfirm = result.isPrima
        ? 'Torno indietro di ${result.count} cordoni?'
        : 'Avanzo di ${result.count} cordoni?';
    final confirmed = await Messenger.askMessage(
        context, 'Conferma', descConfirm, 'Conferma', 'Annulla');

    if (!(confirmed ?? false)) {
      return;
    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - -
    mySetState?.call(() {
      _setPendingRobotTargetStatus('WELDING');
    });

    await playActivationSound();
    final backCordoneValue = result.isPrima ? result.count : -result.count;
    await sendMessageToRobot(
        {"f": "RESUME", "BackCordone": "$backCordoneValue"});
  }

  Future<_ResumeResult?> _showResumeCordoniDialog({
    required BuildContext context,
    required int cordoneCorrente,
    required int numerocordonitotale,
  }) {
    return showDialog<_ResumeResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResumeCordoniDialog(
        cordoneCorrente: cordoneCorrente,
        numerocordonitotale: numerocordonitotale,
      ),
    );
  }

  Future<void> pausePressed({required BuildContext context}) async {
    unfocusScreen();

    if (!canPauseWelding) {
      return;
    }
    mySetState?.call(() {
      _setPendingRobotTargetStatus('PAUSED');
    });
    await playDeactivationSound();
    await sendMessageToRobot({"f": "PAUSE"});
  }

  Future<void> connectRobot() async {
    final confirmed = await Messenger.askMessage(
          context,
          "CONFERMA",
          "CONNETTERSI AL ROBOT?",
          "CONNETTI",
          "ANNULLA",
        ) ??
        false;

    if (!confirmed) return;
    buildReconnectionTimer();
    await connettiRobot();
    testolog = "";
    mySetState?.call(() {});
  }

  Future<void> disconnectRobot() async {
    final confirmed = await Messenger.askMessage(
          context,
          "CONFERMA",
          "CONFERMI DI DISCONNETTERE IL ROBOT?",
          "DISCONNETTI",
          "ANNULLA",
        ) ??
        false;

    if (!confirmed) return;

    closeSocket();
    destroyReconnectionTimer();
    mySetState?.call(() {
      connectionStatus = false;
      homeReachReceived = false;
      canMoveRobot = true;
    });
    dashboardSetCanMoveRobot?.call(true);
  }

  void buildReconnectionTimer() {
    print("[ buildReconnectionTimer ] : $UNLOCK_PAGE_FOR_TEST");
    timerReconnection =
        Timer.periodic(Duration(seconds: 5), (Timer timer) async {
      if (!connectionStatus && !UNLOCK_PAGE_FOR_TEST) {
        await connettiRobot();
      }
    });
  }

  void destroyReconnectionTimer() {
    timerReconnection?.cancel();
  }

  Future<void> closePage({required BuildContext context}) async {
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
        loadingDati = true;
      });

      closeSocket();

      totalReset();

      mySetState?.call(() {
        connectionStatus = false;
      });

      dashboardSetCanMoveRobot?.call(true);
      Pager.goToFirstPage(context);
    }
  }

  //
  //
  Future<void> eraseController() async {
    closeSocket();
    totalReset();
    mySetState?.call(() {
      connectionStatus = false;
      homeReachReceived = false;
    });

    destroyReconnectionTimer();
    dashboardSetCanMoveRobot?.call(true);
  }

  void toggleJoystick() {
    mySetState?.call(() {
      mostraJoystick = !mostraJoystick;
    });
  }

  //
  //
  Future<void> loadLastSavedPoints({required BuildContext context}) async {
    if (ultimiPuntiSalvati == null) {
      try {
        await getPointsHistoryFromServer();
      } catch (_) {}
    }

    if (ultimiPuntiSalvati == null) {
      // Snackbar rimosso
      return;
    }

    // chiedere conferma
    final confirmed = await Messenger.askMessage(
          this.context,
          "CONFERMA",
          "CARICARE GLI ULTIMI PUNTI SALVATI?",
          "SI, SOVRASCRIVI I PUNTI",
          "ANNULLA",
        ) ??
        false;
    if (confirmed) {
      // Carica i punti nel grafico senza automatizzare state/robot
      replacePunti(newPoints: ultimiPuntiSalvati!);
      mySetState?.call(() {});

      // Se i punti sono ordinati, abilita il bottone "genera punti"
      final allPointsOrdered = ultimiPuntiSalvati!.points.isNotEmpty &&
          ultimiPuntiSalvati!.points.every((point) => point.order != null);
      if (allPointsOrdered) {
        setCanGeneratePoints(true);
      }

      // Snackbar rimosso
    }
  }

  //
  //
  Future<void> loadPoints({required PointsFree newPoints}) async {
    replacePunti(newPoints: newPoints);

    mySetState?.call(() {
      pageState = LaserPanelState.tipoSaldatura;
    });

    resetStratiEseguiti();
  }

  //
  //
  Future<void> deleteAllSavedPoints() async {
    await resetPunti();
    await resetPoints();
    resetFrame();
    dashboardResetVersion++;
    dashboardClear?.call();
  }

  //
  //
  Future<void> onOmnidirectionJogChangedValue(x, z) async {
    deltax = x * -1;
    deltaz = z;

    await sendJoystickMoveCommand(
      {
        "f": "MOVE",
        "deltax": deltax.toStringAsFixed(1),
        "deltay": deltay.toStringAsFixed(1),
        "deltaz": deltaz.toStringAsFixed(1),
        "deltaj6": "0",
      },
      ignoredLog: 'Ignoro Jog Omni',
    );
  }

  //
  //
  Future<void> onJogChangedValue(value) async {
    if (isPianoRotolamento) {
      deltaz = -value;
      deltay = 0;
    } else {
      deltay = value;
      deltaz = 0;
    }

    await sendJoystickMoveCommand(
      {
        "f": "MOVE",
        "deltax": deltax.toStringAsFixed(1),
        "deltay": deltay.toStringAsFixed(1),
        "deltaz": deltaz.toStringAsFixed(1),
        "deltaj6": "0",
      },
      ignoredLog: 'Ignoro Jog X',
    );
  }

  //
  //
  Future<void> laserDirectionSelected({required bool selection}) async {
    if (selection == armPosition) return;

    Vibrator.mediumVibration();
    playAlertSound();

    final confirmed = await Messenger.askMessageAlert(context, "CONFERMA",
            "CAMBIARE POSIZIONE ROBOT?", "CAMBIA POSIZIONE", "ANNULLA") ??
        false;

    if (confirmed) {
      final confirmTorch = await Messenger.askTorchUnmountedConfirm(
              context,
              "CONFERMA",
              "SEI SICURO DI AVER SMONTATO LA TORCIA?",
              "SI",
              "NO ANNULLA") ??
          false;
      if (confirmTorch) {
        mySetState?.call(() {
          armPosition = selection;
        });
        sendArmPosition();
      }
    }
  }

  //
  //
  void movimentoAutomaticoChanged(LaserControllerMode value) {
    mySetState?.call(() {
      controllerMode = value;
    });
  }

  //
  //
  Future<void> destraSinistraChanged(bool? value) async {
    if (value != null) {
      if (value == armPosition) return;
      final confirmed = await Messenger.askMessageAlert(context, "CONFERMA",
              "CAMBIARE POSIZIONE ROBOT?", "CAMBIA POSIZIONE", "ANNULLA") ??
          false;

      if (confirmed) {
        mySetState?.call(() {
          armPosition = value;
        });
        sendArmPosition();
      }
    }
  }

  void openSettingsPage({required BuildContext context}) {
    Pager.push(
        context: context,
        page: LaserSettingsPage(
          laserPageController: this,
        ));
  }

  /// Restituisce true solo se il nuovo valore è non-vuoto E diverso da quello attuale.
  /// Se la risposta del server non include il campo (valore vuoto), non lo consideriamo cambiato.
  bool _connectionParamChanged(String newVal, String currentVal) {
    final trimNew = newVal.trim();
    if (trimNew.isEmpty) return false;
    return trimNew != currentVal.trim();
  }

  Future<void> setRobotSettings(
      {required LaserRobotSettings newSettings}) async {
    final oldMode = controrotaiaModeValue;
    // Preserve the current tipoControrotaia: it is a runtime property of the
    // controller and must NOT be overwritten by the server response (which
    // derives tipoControrotaia from the first DB limit row, whose ordering is
    // arbitrary and may differ from the robot's actual current mode).
    // The mode can only change explicitly via sendSetModeControrotaia.
    final nextTipo = tipoControrotaia;

    final connectionParamsChanged = _connectionParamChanged(
            newSettings.serialeRobot, settings.serialeRobot) ||
        _connectionParamChanged(newSettings.ipRobot, settings.ipRobot) ||
        _connectionParamChanged(newSettings.ipServer, settings.ipServer) ||
        _connectionParamChanged(newSettings.pinGas, settings.pinGas) ||
        _connectionParamChanged(newSettings.pinLaser, settings.pinLaser) ||
        _connectionParamChanged(newSettings.pinMassa, settings.pinMassa);

    // Merge: se la risposta API non include un campo di connessione (stringa vuota),
    // mantieni il valore corrente per evitare di sovrascrivere dati validi con vuoti.
    final mergedSettings = LaserRobotSettings(
      serialeRobot: newSettings.serialeRobot.trim().isNotEmpty
          ? newSettings.serialeRobot
          : settings.serialeRobot,
      ipRobot: newSettings.ipRobot.trim().isNotEmpty
          ? newSettings.ipRobot
          : settings.ipRobot,
      ipServer: newSettings.ipServer.trim().isNotEmpty
          ? newSettings.ipServer
          : settings.ipServer,
      pinGas: newSettings.pinGas.trim().isNotEmpty
          ? newSettings.pinGas
          : settings.pinGas,
      pinLaser: newSettings.pinLaser.trim().isNotEmpty
          ? newSettings.pinLaser
          : settings.pinLaser,
      pinMassa: newSettings.pinMassa.trim().isNotEmpty
          ? newSettings.pinMassa
          : settings.pinMassa,
      scostamentoX: newSettings.scostamentoX,
      scostamentoY: newSettings.scostamentoY,
      scostamentoZ: newSettings.scostamentoZ,
      color: newSettings.color.trim().isNotEmpty
          ? newSettings.color
          : settings.color,
      limiteZDown: newSettings.limiteZDown,
      stepUp: newSettings.stepUp,
      stepDown: newSettings.stepDown,
      stepUpSx: newSettings.stepUpSx,
      stepUpDx: newSettings.stepUpDx,
      stepDownSx: newSettings.stepDownSx,
      stepDownDx: newSettings.stepDownDx,
      stepLeft: newSettings.stepLeft,
      stepRight: newSettings.stepRight,
      stepY: newSettings.stepY,
      tipoControrotaia: nextTipo,
      limiti: newSettings.limiti,
    );
    //
    //
    mySetState?.call(() {
      settings = mergedSettings;
      tipoControrotaia = nextTipo;
    });
    //
    //
    final modeChanged = oldMode != controrotaiaModeValue;
    //
    //
    _syncScostamentoFieldDefaultsForCurrentMode(force: true);
    if (modeChanged) {
      _applyDirectionDefaultsForTipo();
      _syncOffsetInizioDefaultsForCurrentMode(force: true);
      await resetPunti();
      dashboardClear?.call();
      notifyPointsOrderChanged();
    } else {
      _applyFixedDirezioneSaldaturaForTipo();
    }

    if (connectionParamsChanged && socket != null) {
      totalReset();
      closeSocket();
      await startConnection();
      return;
    }

    if (modeChanged && socket != null) {
      await sendMessageToRobot(
          {"f": "SETMODE", "tipo_controrotaia": controrotaiaModeValue});
    }
  }

  /// Cambia il tipo controrotaia a runtime e invia SETMODE al robot.
  Future<bool> sendSetModeControrotaia(String newTipo) async {
    // Consentito solo in modalità prendi punti (joystick).
    if (pageState != LaserPanelState.joystick) return false;
    final normalized = _normalizeControrotaiaValue(newTipo);
    if (normalized == controrotaiaModeValue) return false;
    mySetState?.call(() {
      tipoControrotaia = normalized;
      // Metti l'app in attesa del HOMEREACH che il robot invierà dopo SETMODE.
      homeReachReceived = false;
    });
    _syncScostamentoFieldDefaultsForCurrentMode(force: true);
    _syncOffsetInizioDefaultsForCurrentMode(force: true);
    // Reset dei punti: si riparte da capo con il nuovo tipo.
    await resetPunti();
    dashboardClear?.call();
    notifyPointsOrderChanged();
    _applyDirectionDefaultsForTipo();
    await sendMessageToRobot(
        {"f": "SETMODE", "tipo_controrotaia": controrotaiaModeValue});
    return true;
  }

  String _normalizeControrotaiaValue(String tipo) {
    final raw = tipo.trim().toLowerCase();
    switch (raw) {
      case 'controrotaiasemplice':
      case 'controrotaia semplice':
      case 'semplice':
      case 'lunga':
      case '0':
        return 'controrotaiasemplice';
      case 'controrotaiadoppia':
      case 'controrotaia doppia':
      case 'doppia':
      case 'cuore':
      case '1':
        return 'controrotaiadoppia';
      case 'piano':
      case 'piano di rotolamento':
      case '2':
        return 'piano';
      default:
        return raw;
    }
  }

  void resetRobotSettings() {
    box.setString(value: null, key: Constants.HIVE_LASER_SERIAL_KEY);
    box.setString(value: null, key: Constants.HIVE_LASER_SETTINGS_KEY);
  }

  Future<void> playAlertSound() async {
    // setto volume al massimo
    if (!soundFXEnabled) return;
    VolumeService.setMaximumVolume();
    await AudioService.playBipSingoloSound();
  }

  Future<void> playActivationSound() async {
    // setto volume al massimo
    if (!soundFXEnabled) return;
    VolumeService.setMaximumVolume();
    await AudioService.playLaserActivationSound();
  }

  Future<void> playDeactivationSound() async {
    // setto volume al massimo
    if (!soundFXEnabled) return;
    VolumeService.setMaximumVolume();
    await AudioService.playLaserDectivationSound();
  }

  Future<void> loadPointsFromHistory(
      {required LaserPointsPackage pointsPackage}) async {
    // Carica i punti nel grafico senza automatizzare state/robot
    replacePunti(newPoints: pointsPackage.points);
    mySetState?.call(() {
      pageState = LaserPanelState.joystick;
    });

    // Ripristina safePosition se presente nel package
    if (pointsPackage.safePosition != null) {
      safePositionNotifier.value = pointsPackage.safePosition;
      final orientation = pointsPackage.safePosition!.orientation;
      if (orientation == "DX") {
        armPosition = true;
      } else if (orientation == "SX") {
        armPosition = false;
      }
    }

    // Rebound esplicito dopo caricamento da storico.
    // Se la home è già stata ricevuta, ricalcola le dashboardPosition dei punti
    // appena caricati (altrimenti _updateCanGeneratePoints le troverebbe null).
    if (homeReachReceived && homeReferencePosition != null) {
      dashboardSetHomeReferenceCenter?.call(
        homeReferencePosition!.x,
        isPianoRotolamento
            ? homeReferencePosition!.y * -1
            : homeReferencePosition!.z,
      );
    } else {
      dashboardRedrawPoints?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dashboardRedrawPoints?.call();
      });
    }

    // Se i punti sono ordinati, abilita il bottone "genera punti"
    final allPointsOrdered = pointsPackage.points.points.isNotEmpty &&
        pointsPackage.points.points.every((point) => point.order != null);
    if (allPointsOrdered) {
      setCanGeneratePoints(true);
    }
  }

  void goToPointsHistory({required BuildContext context}) {
    Pager.push(
        context: context,
        page: LaserPointsHistoryPage(laserPageController: this));
  }

  Future<void> salvaPointsToHistory() async {
    //
    //
    printLog("- - - > Salvo punti");
    //
    //
    if (points.isEmpty) {
      final effectiveContext = context;
      if (effectiveContext != null) {
        Messenger.infoDialog(
          effectiveContext,
          "Attenzione",
          "Nessun punto da salvare",
          "OK",
        );
      }
      printLog('[SAVE_POINTS] BLOCCO: lista punti vuota');
      return;
    }

    final effectiveContext = context;
    if (effectiveContext == null) {
      printLog(
          '[SAVE_POINTS] BLOCCO: context nullo, impossibile aprire dialog');
      return;
    }

    final currentPoints = pointsFreeFromJson(pointsFreeToJson(points));
    final safePositionSnapshot = currentSafePosition;
    final defaultLabelPrefix = "$controrotaiaModeValue - ";

    String? label;
    while (label == null || label.trim() == "") {
      printLog(
          '[SAVE_POINTS] Apro dialog etichetta, default=$defaultLabelPrefix');
      label = await showDialog<String>(
          context: effectiveContext,
          builder: (context) {
            return AskPointsLabelDialog(initialLabel: defaultLabelPrefix);
          });
      printLog('[SAVE_POINTS] Dialog chiuso, label=$label');

      // Se l'utente preme annulla, esce dal flusso
      if (label == null) {
        printLog('[SAVE_POINTS] Salvataggio annullato da utente');
        return;
      }
    }

    try {
      //
      //
      final response = await Api.request({
        "f": "saveLaserPunti",
        "seriale_robot": settings.serialeRobot,
        "nome": label.trim(),
        "punti": pointsFreeToJson(currentPoints),
        if (safePositionSnapshot != null)
          "safe_position": jsonEncode(safePositionSnapshot.toJson()),
      }, verbose: true);

      try {
        final decoded = jsonDecode(response.body);
        final ok = decoded is Map<String, dynamic>
            ? (decoded["ok"] == 1 || decoded["ok"] == true)
            : false;
        if (!ok) {
          final message = decoded is Map<String, dynamic>
              ? (decoded["message"]?.toString() ?? "Errore salvataggio punti")
              : "Errore salvataggio punti";
          throw ResponseError(code: 500, message: message);
        }
      } catch (e) {
        if (e is ResponseError) rethrow;
        throw ResponseError(
            code: 500,
            message: "Risposta salvataggio non valida: ${response.body}");
      }

      ultimiPuntiSalvati = currentPoints;
      // Snackbar rimosso
    } catch (e) {
      if (e is ResponseError && e.message.trim().isNotEmpty) {
        Messenger.showMessageGenericError(context, e.message, 2);
      } else {
        Messenger.showMessageGenericError(
            context, "Errore salvataggio punti", 2);
      }
    }
  }

  Future<List<LaserPointsPackage>> getPointsHistoryFromServer() async {
    final response = await Api.request({
      "f": "getLaserPunti",
      "seriale_robot": settings.serialeRobot,
    });

    final pointsPackages = laserPointsPackageListFromServerJson(response.body);
    if (pointsPackages.isNotEmpty) {
      ultimiPuntiSalvati = pointsPackages.first.points;
    }

    return pointsPackages;
  }

  Future<void> deletePointsFromHistory({required int id}) async {
    await Api.request({
      "f": "deleteLaserPunti",
      "id": id.toString(),
    });
  }

  void printLog(String log) {
    if (log.trim() != lastLogMessage.trim()) {
      lastLogMessage = log;
      mySetState?.call(() {
        logString = "$log\n$logString";
      });
    }
  }

  void setMoveToTrue() {
    mySetState?.call(() {
      canMoveRobot = true;
    });
  }

  void toggleLog() {
    mySetState?.call(
      () {
        showLogWindow = !showLogWindow;
      },
    );
  }

  double _parseDoubleOrDefault(String? value, double fallback) {
    if (value == null) return fallback;
    return double.tryParse(value.trim().replaceAll(",", ".")) ?? fallback;
  }

  String _parseDecimalStringOrDefault(String? value, double fallback) {
    return _parseDoubleOrDefault(value, fallback).toString();
  }

  int _currentStratoIndex() {
    if (strato < 0) return 0;
    if (strato >= offsetinizioController.length) {
      return offsetinizioController.length - 1;
    }
    return strato;
  }

  Map<String, dynamic> _buildLayeringPayloadByControrotaia({
    required int stratoIndex,
  }) {
    //
    //
    //
    //
    final stepLayerBase = _parseDoubleOrDefault(
      offsetStratoController[stratoIndex].text,
      offsetstrato[stratoIndex].toDouble(),
    );
    //
    //
    //
    //
    switch (controrotaiaModeValue) {
      //
      //
      //
      //
      case 'piano':
        return {
          "step_layer_x": _parseDoubleOrDefault(
            scostamentoStratoXValue,
            defaultStepLayerXByControrotaia,
          ),
          "step_layer_y": _parseDoubleOrDefault(
            scostamentoStratoZValue,
            defaultStepLayerZByControrotaia,
          ),
          "step_layer_z": stepLayerBase,
          "verso_cordone": "max_min",
          "ordine_cordoni": "max_min_y",
        };
      case 'controrotaiasemplice':
        return {
          "step_layer_x": _parseDoubleOrDefault(
            scostamentoStratoXValue,
            defaultStepLayerXByControrotaia,
          ),
          "step_layer_y": stepLayerBase,
          "step_layer_z": _parseDoubleOrDefault(
            scostamentoStratoZValue,
            defaultStepLayerZByControrotaia,
          ),
          "verso_cordone": "max_min",
          "ordine_cordoni": "min_max_z",
        };
      case 'controrotaiadoppia':
        return {
          "step_layer_x": _parseDoubleOrDefault(
            scostamentoStratoXValue,
            defaultStepLayerXByControrotaia,
          ),
          "step_layer_y": stepLayerBase * -1,
          "step_layer_z": _parseDoubleOrDefault(
            scostamentoStratoZValue,
            defaultStepLayerZByControrotaia,
          ),
          "verso_cordone": "min_max",
          "ordine_cordoni": armPosition == true ? "max_min_x" : "min_max_x",
        };
      default:
        return {
          "step_layer_x": _parseDoubleOrDefault(
            scostamentoStratoXValue,
            defaultStepLayerXByControrotaia,
          ),
          "step_layer_y": stepLayerBase,
          "step_layer_z": _parseDoubleOrDefault(
            scostamentoStratoZValue,
            defaultStepLayerZByControrotaia,
          ),
          "verso_cordone": "min_max",
          "ordine_cordoni": "min_max_z",
        };
    }
    //
    //
    //
    //
  }

  List<double> _buildElencoStepLayerPayload() {
    const maxItems = 10;
    final values = <double>[];
    for (var i = 0; i < maxItems; i++) {
      if (i >= offsetStratoController.length) {
        values.add(i < offsetstrato.length ? offsetstrato[i].toDouble() : 0.0);
        continue;
      }
      values.add(_parseDoubleOrDefault(
        offsetStratoController[i].text,
        i < offsetstrato.length ? offsetstrato[i].toDouble() : 0.0,
      ));
    }
    return values;
  }

  Future<void> sendPointsToFastAPI() async {
    print('[interpola] sendPointsToFastAPI triggered');
    if (context == null) {
      print('[interpola] aborted: context is null');
      return;
    }

    if (armPosition == null) {
      print('[interpola] aborted: armPosition is null');
      return;
    }

    if (!effectiveHasSafePosition) {
      Messenger.showMessageGenericError(
          context, "Safe Position non impostata", 2);
      print('[interpola] aborted: safe position not set');
      return;
    }

    mySetState?.call(() {
      sendingSimulationPoints = true;
    });
    sendingSimulationNotifier.value = true;
    viewerUrlNotifier.value = null;
    String? lastInterpolaUrl;

    try {
      //
      //
      // Entrambe le modalità usano ora l'ordinamento (perimetro mode re-abilitato per nuvola)
      final List<Point> effectivePoints = points.points
          .where((point) => point.order != null)
          .toList()
        ..sort((a, b) => a.order!.compareTo(b.order!));

      final puntiBase = effectivePoints
          .map((point) =>
              [point.x, point.y, point.z, point.j1, point.j2, point.j3])
          .toList();
      final ordine = List<int>.generate(puntiBase.length, (index) => index);
      final cordoneBase = [
        for (var i = 0; i < effectivePoints.length; i++)
          if (effectivePoints[i].isBase) i
      ];
      final cordoneLimite = [
        for (var i = 0; i < effectivePoints.length; i++)
          if (effectivePoints[i].isLimite) i
      ];

      if (modalitaNuvola) {
        final puntiSenzaOrdine =
            points.points.where((p) => p.order == null).length;
        if (puntiSenzaOrdine > 0) {
          Messenger.showMessageGenericError(
              context,
              "Perimetro incompleto: $puntiSenzaOrdine "
              "${puntiSenzaOrdine == 1 ? 'punto non ha' : 'punti non hanno'} "
              "un ordinamento assegnato",
              3);
          return;
        }
        if (cordoneBase.length < 2) {
          Messenger.showMessageGenericError(
              context, "Base non definita: seleziona almeno 2 punti BASE", 3);
          return;
        }
        if (cordoneLimite.length < 2) {
          Messenger.showMessageGenericError(context,
              "Limite non definito: seleziona almeno 2 punti LIMITE", 3);
          return;
        }
      } else {
        if (effectivePoints.length < 2) {
          Messenger.showMessageGenericError(
              context, "Seleziona almeno 2 punti prima di interpolare", 3);
          return;
        }
      }

      final stratoIndex = _currentStratoIndex();
      final larghezzaCordoneValue =
          _parseDoubleOrDefault(larghezzaCordone.text, defaultLarghezzaCordone);
      final sovrapposizioneValue = _parseDoubleOrDefault(
          sovrapposizioneCordone.text, defaultSovrapposizioneCordone);
      final stepCordoni =
          larghezzaCordoneValue * (1 - (sovrapposizioneValue / 100));
      final modalita =
          direzioneCordoniNotifier.value == 'h' ? 'orizzontale' : 'verticale';
      final layerPayload =
          _buildLayeringPayloadByControrotaia(stratoIndex: stratoIndex);
      final elencoStepLayer = _buildElencoStepLayerPayload();

      final safePositionDecoded = _safePositionPayloadForRobotCommands();

      final payload = {
        "punti_base": puntiBase,
        "ordine": ordine,
        "riempi_area": true,
        "execution_mode": "movel",
        "max_points_per_cordone": 5,
        "simplify_tolerance": 1.0,
        if (modalitaNuvola) ...{
          "cordone_base": cordoneBase,
          "cordone_limite": cordoneLimite,
          "ordine_perimetro": ordine,
        },
        "tipo_controrotaia": controrotaiaModeValue,
        "modalita": modalita,
        "step_cordoni": stepCordoni,
        "offsetinizio": _parseDoubleOrDefault(
            offsetinizioController[stratoIndex].text,
            offsetinizio[stratoIndex].toDouble()),
        "offsetfine": _parseDoubleOrDefault(
            offsetfineController[stratoIndex].text,
            offsetfine[stratoIndex].toDouble()),
        "strato": 0,
        "step_layer_x": layerPayload["step_layer_x"],
        "step_layer_y": layerPayload["step_layer_y"],
        "step_layer_z": layerPayload["step_layer_z"],
        "elenco_step_layer": elencoStepLayer,
        "verso_cordone": layerPayload["verso_cordone"],
        "ordine_cordoni": layerPayload["ordine_cordoni"],
        "safeposition": safePositionDecoded,
        "sovrapposizione_cordone": sovrapposizioneCordone.text,
        "larghezzacordone": larghezzaCordone.text,
        "min_length_cordoni": _parseDecimalStringOrDefault(
            minLengthCordoniController.text, defaultMinLengthCordoni),
        "alternata": alternata,
        "modalita_interpolazione": modalitaNuvola ? "nuvola" : "poligono",
        if (modalitaNuvola) ...{
          "use_nuvola": true,
          "quota_tassativa": true,
          "grid_only": true,
          "exact_tol": 0.001,
          "interp_method": nuvolaInterpMethodController.text.trim().isEmpty
              ? 'smooth'
              : nuvolaInterpMethodController.text.trim(),
          "smooth_kernel": "thin_plate",
          "smooth_lambda":
              double.tryParse(nuvolaSmoothLambdaController.text) ?? 0.000001,
          "interp_k": int.tryParse(nuvolaInterpKController.text) ?? 8,
          "interp_power": 2.0,
          "linear_candidate_k": 12,
          "debug_hull": false,
        },
      };

      final pointsToSend = jsonEncode(payload);
      final interpolaUrl = modalitaNuvola
          ? "http://${settings.ipServer}/interpola_nuvola"
          : "http://${settings.ipServer}/interpola";
      lastInterpolaUrl = interpolaUrl;
      print(
          ">>>INTERPOLA_REQUEST<<< url=$interpolaUrl | headers={Content-Type: application/json}");
      const chunkSize0 = 800;
      for (var i0 = 0; i0 < pointsToSend.length; i0 += chunkSize0) {
        final end0 = (i0 + chunkSize0 < pointsToSend.length)
            ? i0 + chunkSize0
            : pointsToSend.length;
        print(
            ">>>INTERPOLA_REQUEST<<< body[$i0-$end0] ${pointsToSend.substring(i0, end0)}");
      }
      final response = await http.post(Uri.parse(interpolaUrl),
          headers: {"Content-Type": "application/json"}, body: pointsToSend);

      print("[interpola] responseStatusCode=${response.statusCode}");
      print("[interpola] responseBody=${response.body}");
      print("[genera punti] status ${response.statusCode}");
      print("${response.statusCode}");
      final bodyStr = response.body;
      log(bodyStr);
      lastInterpolaResponseNotifier.value = bodyStr;
      const chunkSize = 800;
      for (var i = 0; i < bodyStr.length; i += chunkSize) {
        final end =
            (i + chunkSize < bodyStr.length) ? i + chunkSize : bodyStr.length;
        print("[genera punti] body[$i-$end] ${bodyStr.substring(i, end)}");
      }

      if (response.isSuccess) {
        final interpolaResponse = interpolaResponseFromJson(bodyStr);
        print("[genera punti] ok=${interpolaResponse.ok}");
        print("[genera punti] index=${interpolaResponse.index}");
        print("[genera punti] log_file=${interpolaResponse.logFile}");
        print("[genera punti] grafico_file=${interpolaResponse.graficoFile}");
        print("[genera punti] plot_json=${interpolaResponse.plotJson}");
        print("[genera punti] meta_json=${interpolaResponse.metaJson}");
        print("[genera punti] viewer_url=${interpolaResponse.viewerUrl}");
        final finalViewerUrl =
            '$serverBaseUrl${interpolaResponse.viewerUrl}${interpolaResponse.viewerUrl.contains('?') ? '&' : '?'}t=${DateTime.now().millisecondsSinceEpoch}';
        print("[genera punti URL] $finalViewerUrl");
        viewerUrlNotifier.value = finalViewerUrl;

        // New generated path => new welding run: clear executed layers and runtime progress.
        resetStratiEseguiti();
        mySetState?.call(() {
          startedWeldingOnce = false;
          stratoCominciato = false;
          paused = true;
          weldingStatus = weldingStatusInactive;
          cordone = 0;
          numerocordonitotale = 0;
          cordoneiniziale = 0;
          cordonefinale = 0;
          totalWeldedLength = 0;
          totalWeldingLength = 0;
          pageState = LaserPanelState.tipoSaldatura;
        });
        final scriptStr = interpolaResponse.script;
        for (var i = 0; i < scriptStr.length; i += chunkSize) {
          final end = (i + chunkSize < scriptStr.length)
              ? i + chunkSize
              : scriptStr.length;
          print(
              "[genera punti] script[$i-$end] ${scriptStr.substring(i, end)}");
        }
      } else {
        // Snackbar rimosso
        printLog("${response.statusCode} - $bodyStr");
      }
    } catch (e, stackTrace) {
      if (lastInterpolaUrl != null) {
        print('[interpola] failedUrl=$lastInterpolaUrl');
      }
      print("ip: $e");
      final isConnectionRefused =
          e.toString().toLowerCase().contains('connection refused');
      if (isConnectionRefused && context != null) {
        Messenger.showMessageGenericError(
          context,
          "Server interpola non raggiungibile: controlla IP/porta",
          3,
        );
      }
      print("[genera punti] errorType ${e.runtimeType}");
      print("[genera punti] error ${e.toString()}");
      print("[genera punti] stackTrace $stackTrace");
    } finally {
      mySetState?.call(() {
        sendingSimulationPoints = false;
      });
      sendingSimulationNotifier.value = false;
    }
  }

  Future<void> resetAllVariables() async {
    //
    //
    //
    await _confirmAndResetToInitialState(
      title: "CONFERMA",
      message: "RESETTARE TUTTO?",
      confirmLabel: "RESETTA",
      cancelLabel: "Indietro",
      logLabel: "--> RESET ALL <--",
    );
  }

  Future<void> _confirmAndResetToInitialState({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required String logLabel,
  }) async {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    final confirm = await Messenger.askMessageAlert(
            context, title, message, confirmLabel, cancelLabel) ??
        false;

    if (!confirm) return;

    printLog(logLabel);
    totalReset();
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  }

  void totalReset() {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    deleteSafePosition().then((_) {
      mySetState?.call(() {
        // reset frame
        frameWidth = 0;
        frameHeight = 0;
        frameSet = false;
        // resetto coordinate punti
        points = PointsFree(points: []);
        pointsFrameEpoch = null;
        hasFrameMismatch = false;
        lastFrameReason = null;
        notifyPointsOrderChanged();
        viewerUrlNotifier.value = null;
        lastInterpolaResponseNotifier.value = null;
        setCanGeneratePoints(false);
        allPointsRestored = false;
        allPointsSet = false;
        // sblocco movimento robot
        canMoveRobot = true;
        paused = false;
        weldingStatus = weldingStatusInactive;
        // reset strati eseguiti
        startedWeldingOnce = false;
        stratoCominciato = false;
        isStopping = false;
        resetStratiEseguiti();
        redrawPoints();
        // ripristino pagina
        pageState = LaserPanelState.joystick;
        mostraJoystick = false;
        verticalLock = false;
        _setPendingRobotTargetStatus(null);
        isGasActive = false;
        isWireActive = false;
        cordone = 0;
        strato = 0;
        numerocordonitotale = 0;
        cordoneiniziale = 0;
        cordonefinale = 0;
        totalWeldedLength = 0;
        totalWeldingLength = 0;
        pointSelectionModeNotifier.value = 'perimetro';
        dashboardResetVersion++;
        dashboardClear?.call();
      });
    });
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  }

  void closeSocket() {
    final currentSubscription = socketSubscription;
    socketSubscription = null;
    currentSubscription?.cancel();
    socket?.destroy();
    socket = null;
  }

  Future<void> stopCurrentCordone({required BuildContext context}) async {
    unfocusScreen();
    if (isStopping || !canStopWelding) return;
    final confirmed = await Messenger.askMessageAlert(
            context, "CONFERMA STOP", "ESEGUIRE STOP?", "STOP", "ANNULLA") ??
        false;
    if (confirmed) {
      mySetState?.call(() {
        _setPendingRobotTargetStatus('END');
      });
      await sendMessageToRobot({"f": "STOPCORDONE"});
    }
  }

  Future<void> enterPuliziaMode() async {
    final confirmed = await Messenger.askMessageAlert(context, "CONFERMA",
            "ENTRARE IN MODALITA' PULIZIA?", "CONFERMA", "ANNULLA") ??
        false;
    if (confirmed) {
      await sendMessageToRobot({"f": "PULIZIAMODE"});
    }
  }

  Future<void> sendArmPosition() async {
    if (armPosition == null) {
      return;
    }
    await sendMessageToRobot(
        {"f": "ARMPOSITION", "p": armPosition! ? "DX" : "SX"});
  }

  Future<void> enterMaintenanceMode() async {
    final confirmed = await Messenger.askMessageAlert(context, "CONFERMA",
            "ENTRARE IN MODALITA' MANUTENZIONE?", "CONFERMA", "ANNULLA") ??
        false;
    if (confirmed) {
      if (armPosition != null) {
        if (armPosition!) {
          await sendMessageToRobot({"f": "MAINTENANCEMODEDX"});
        } else {
          await sendMessageToRobot({"f": "MAINTENANCEMODESX"});
        }
      }
    }
  }

  Future<void> enterTransportMode() async {
    final confirmed = await Messenger.askMessageAlert(
            context,
            "ATTENZIONE",
            "PER LA POSIZIONE DI TRASPORTO IL ROBOT DEVE TROVARSI NELLA POSIZIONE GIUSTA\n\n\nCONFERMI?",
            "CONFERMA",
            "ANNULLA") ??
        false;
    if (confirmed) {
      if (armPosition != null) {
        if (armPosition!) {
          await sendMessageToRobot({"f": "TRANSPORTMODEDX"});
        } else {
          await sendMessageToRobot({"f": "TRANSPORTMODESX"});
        }
      }
    }
  }

  Future<void> shutDownFastAPIServer() async {
    final confirmed = await Messenger.askMessageAlert(context, "CONFERMA",
            "SPEGNERE IL SISTEMA DI CALCOLO?", "CONFERMA", "ANNULLA") ??
        false;
    if (confirmed) {
      await http.post(
        Uri.parse("http://${settings.ipServer}:8000/shutdown"),
      );
    }
  }

  void returnToPointSelectionMode() {
    mySetState?.call(() {
      mostraJoystick = false;
      pageState = LaserPanelState.joystick;
    });
  }

  Future<void> openPanelAlignmentConfig() async {
    if (context == null) return;
    final result = await showDialog<_PanelConfigResult>(
      context: context!,
      builder: (ctx) => _PanelAlignmentDialog(
        current: panelAlignment,
        showTakenPointsPanel: showTakenPointsPanel,
      ),
    );
    if (result != null) {
      final hasChanged = result.alignment != panelAlignment ||
          result.showTakenPointsPanel != showTakenPointsPanel;
      if (!hasChanged) return;
      mySetState?.call(() {
        panelAlignment = result.alignment;
        showTakenPointsPanel = result.showTakenPointsPanel;
      });
      savePanelConfig();
    }
  }

  void loadPanelConfig() {
    final savedAlignment =
        box.stringFor(key: Constants.HIVE_LASER_PANEL_ALIGNMENT_KEY);
    final savedShowPointsPanel =
        box.boolFor(key: Constants.HIVE_LASER_SHOW_POINTS_PANEL_KEY);

    panelAlignment = (savedAlignment == 'left' || savedAlignment == 'right')
        ? savedAlignment!
        : 'left';
    showTakenPointsPanel = savedShowPointsPanel ?? true;
  }

  void savePanelConfig() {
    box.setString(
      value: panelAlignment,
      key: Constants.HIVE_LASER_PANEL_ALIGNMENT_KEY,
    );
    box.setBoolean(
      value: showTakenPointsPanel,
      key: Constants.HIVE_LASER_SHOW_POINTS_PANEL_KEY,
    );
  }

  void togglePageState() {
    if (pageState == LaserPanelState.joystick) {
      mySetState?.call(() {
        allPointsSet = true;
        pageState = LaserPanelState.tipoSaldatura;
      });
    } else {
      mySetState?.call(() {
        pageState = LaserPanelState.joystick;
      });
    }
  }

  Future<void> removeRobotPage() async {
    if (isRemovingRobotPage) {
      return;
    }

    mySetState?.call(() {
      isRemovingRobotPage = true;
    });

    try {
      await hubController.removePageFor(robotSerial: settings.serialeRobot);
    } finally {
      mySetState?.call(() {
        isRemovingRobotPage = false;
      });
    }
  }

  void generateAreaPoints() {
    sendMessageToRobot({"f": "SETUPAREA"});
  }

  void unfocusScreen() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (context != null) {
      FocusScope.of(context!).unfocus();
    }
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> sendSetSafePosition({bool askConfirmation = true}) async {
    debugPrint(
      '[SET_SAFE_POSITION] Richiesta impostazione safe position ricevuta '
      'askConfirmation=$askConfirmation armPosition=$armPosition '
      'robotJT=[${posizioneRobot.jt1}, ${posizioneRobot.jt2}, ${posizioneRobot.jt3}, ${posizioneRobot.jt4}, ${posizioneRobot.jt5}, ${posizioneRobot.jt6}]',
    );

    final confirmed = askConfirmation
        ? await Messenger.askMessage(
                context,
                "Conferma",
                "Impostare la Safe Position? Verificare di non essere in collisione",
                "Imposta Safe Position",
                "Annulla") ??
            false
        : true;

    debugPrint('[SET_SAFE_POSITION] Esito conferma=$confirmed');

    if (confirmed) {
      if (armPosition == null) {
        debugPrint(
          '[SET_SAFE_POSITION] BLOCCO: armPosition null, impossibile impostare safe position',
        );
        Messenger.infoDialog(context, "Attenzione",
            "Posizione Destra / Sinistra del robot non impostata", "OK");
        return;
      }

      final fallbackSafePosition = SafePosition(
        orientation: armPosition! ? "DX" : "SX",
        position: [
          posizioneRobot.jt1,
          posizioneRobot.jt2,
          posizioneRobot.jt3,
          posizioneRobot.jt4,
          posizioneRobot.jt5,
          posizioneRobot.jt6,
        ],
      );

      debugPrint(
        '[SET_SAFE_POSITION] Posizione candidata locale '
        'orientation=${fallbackSafePosition.orientation} '
        'position=${fallbackSafePosition.position}',
      );

      const payload = {"f": "SETSAFEPOSITION"};
      debugPrint('[SET_SAFE_POSITION] Payload comando robot: $payload');

      await sendMessageToRobot(payload);
      debugPrint(
        '[SET_SAFE_POSITION] Invio completato, attendo ack robot SafePosition/RobotStatus',
      );
      // Snackbar rimosso
    }
  }

  Future<void> sendGoToSafePosition() async {
    final payload = {"f": "GOTOSAFEPOSITION"};
    final safePosition = currentSafePosition;
    debugPrint(
      '[SAFE_POSITION][GO] Richiesta VAI ricevuta '
      'armPosition=$armPosition '
      'safeOrientation=${safePosition?.orientation} '
      'safePosition=${safePosition?.position}',
    );
    debugPrint('[SAFE_POSITION][GO] Payload comando robot: $payload');
    await sendMessageToRobot(payload);
    debugPrint('[SAFE_POSITION][GO] Invio comando completato');
  }

  void loadSafePosition() {
    debugPrint('[SAFE_TRACE][LOCAL][LOAD] disabled');
  }

  void saveSafePosition() {
    debugPrint('[SAFE_TRACE][LOCAL][SAVE] disabled');
  }

  Future<void> deleteSafePosition() async {
    debugPrint('[SAFE_TRACE][LOCAL][DELETE] clear local+robot cache');
    safePositionNotifier.value = null;
    robotSafePositionCurrentRaw = null;
    appSafePositionMemoryRaw = null;
    robotSafePositionFlagNotifier.value = false;
    box.eraseKey(
        key:
            "${Constants.HIVE_LASER_SAFE_POSITION_KEY}_${settings.serialeRobot}");
    await sendMessageToRobot({"f": "CLEARSAFEPOSITION"});
  }

  // FREE DRAW AREA
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

  Future<void> addCurrentPoint({required BuildContext context}) async {
    if (!_ensureRobotReadyForAction(context, actionLabel: "prendere punti")) {
      return;
    }

    if (!canTakePoint) {
      return;
    }

    print("[getPoint] addCurrentPoint");
    Offset? dashboardPosition = dashboardGetPoint?.call();
    print("[getPoint] dashboardPosition: $dashboardPosition");

    if (dashboardPosition != null) {
      //
      //
      final hadGeneratedPoints = viewerUrlNotifier.value != null;
      if (hadGeneratedPoints && points.points.isNotEmpty) {
        points.resetPointsOrder();
        notifyPointsOrderChanged();
        viewerUrlNotifier.value = null;
        lastInterpolaResponseNotifier.value = null;
      }

      // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
      // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
      // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
      // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

      if (points.isEmpty) {
        pointsFrameEpoch = currentRobotFrameEpoch ?? 0;
        hasFrameMismatch = false;
        lastFrameReason = null;
      }

      final newPoint = Point(
          x: posizioneRobot.x,
          y: posizioneRobot.y,
          z: posizioneRobot.z,
          j1: posizioneRobot.j1,
          j2: posizioneRobot.j2,
          j3: posizioneRobot.j3,
          dashboardPosition: dashboardPosition);
      print("[getPoint] SETPOINT CALLED");
      _setCanTakePoint(false);
      try {
        await sendMessageToRobot({
          "f": "SETPOINT",
          "point": newPoint,
          "allontanamento_x": settings.scostamentoX,
          "allontanamento_y": settings.scostamentoY,
          "allontanamento_z": settings.scostamentoZ,
          "assisted":
              controllerMode == LaserControllerMode.movimentoAssistito ? 1 : 0
        });

        // Congela l'aggiornamento del cursore per 500ms per evitare salti
        // quando il cursore è stato appena aggiunto localmente
        freezeCursorUntil = DateTime.now().add(Duration(milliseconds: 500));
      } catch (e) {
        // Se l'invio fallisce non restare bloccati in attesa della getPoint.
        _setCanTakePoint(true);
        rethrow;
      }

      // Il punto viene aggiornato/rimbalzato solo all'ack getPoint del robot.
    } else {
      _setCanTakePoint(true);
      print("DASHBOARD POSITION IS NULL!!!");
    }
  }

  Future<void> undoLastPoint({required BuildContext context}) async {
    if (points.points.isEmpty) {
      // Snackbar rimosso
      return;
    }

    points.points.removeLast();
    if (points.points.isNotEmpty) {
      points.points.first.isFirst = true;
    }
    points.normalizeOrder();
    notifyPointsOrderChanged();

    // Resetta il freeze del cursore per tornare alla logica normale
    freezeCursorUntil = null;

    redrawPoints();
    mySetState?.call(() {});
    // Snackbar rimosso
  }

  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +

  Future<void> deleteAllPoints({required BuildContext context}) async {
    await _confirmAndResetToInitialState(
      title: "Conferma",
      message: "Eliminare tutti i punti?",
      confirmLabel: "Elimina",
      cancelLabel: "Annulla",
      logLabel: "--> DELETE ALL POINTS (FULL RESET) <--",
    );
    // Snackbar rimosso
  }

  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
  // + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - + - +
}

// Dialog per selezione allineamento pannello comandi
class _PanelAlignmentDialog extends StatefulWidget {
  final String current;
  final bool showTakenPointsPanel;
  const _PanelAlignmentDialog({
    required this.current,
    required this.showTakenPointsPanel,
  });

  @override
  State<_PanelAlignmentDialog> createState() => _PanelAlignmentDialogState();
}

class _PanelAlignmentDialogState extends State<_PanelAlignmentDialog> {
  late String _selected;
  late bool _showTakenPointsPanel;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _showTakenPointsPanel = widget.showTakenPointsPanel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Configurazione pannello',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AlignmentOption(
            value: 'left',
            selected: _selected,
            label: 'Destra',
            description: 'Cloche a destra',
            icon: Icons.align_horizontal_right,
            onTap: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 12),
          _AlignmentOption(
            value: 'right',
            selected: _selected,
            label: 'Sinistra',
            description: 'Cloche a sinistra',
            icon: Icons.align_horizontal_left,
            onTap: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _showTakenPointsPanel,
            title: const Text('Mostra elenco punti'),
            onChanged: (value) {
              setState(() {
                _showTakenPointsPanel = value ?? true;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.sagaBlue,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla',
              style: TextStyle(color: AppColors.sagaBlue)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sagaBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(
            _PanelConfigResult(
              alignment: _selected,
              showTakenPointsPanel: _showTakenPointsPanel,
            ),
          ),
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}

class _PanelConfigResult {
  final String alignment;
  final bool showTakenPointsPanel;

  const _PanelConfigResult({
    required this.alignment,
    required this.showTakenPointsPanel,
  });
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Resume Cordoni Dialog
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class _ResumeResult {
  final int count;

  /// true = prima (arretramento), false = dopo (avanzamento)
  final bool isPrima;
  _ResumeResult({required this.count, required this.isPrima});
}

class _ResumeCordoniDialog extends StatefulWidget {
  final int cordoneCorrente;
  final int numerocordonitotale;

  const _ResumeCordoniDialog({
    required this.cordoneCorrente,
    required this.numerocordonitotale,
  });

  @override
  State<_ResumeCordoniDialog> createState() => _ResumeCordoniDialogState();
}

class _ResumeCordoniDialogState extends State<_ResumeCordoniDialog> {
  bool _isPrima = true;
  late TextEditingController _ctrl;

  int get _maxPrima => widget.cordoneCorrente;
  int get _maxDopo {
    if (widget.numerocordonitotale > 0) {
      return widget.numerocordonitotale - widget.cordoneCorrente;
    }
    return 9999;
  }

  int get _currentMax => _isPrima ? _maxPrima : _maxDopo;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _clamp() {
    final v = int.tryParse(_ctrl.text) ?? 0;
    _ctrl.text = v.clamp(0, _currentMax).toString();
  }

  void _decrement() {
    final v = (int.tryParse(_ctrl.text) ?? 0) - 1;
    _ctrl.text = v.clamp(0, _currentMax).toString();
  }

  void _increment() {
    final v = (int.tryParse(_ctrl.text) ?? 0) + 1;
    _ctrl.text = v.clamp(0, _currentMax).toString();
  }

  @override
  Widget build(BuildContext context) {
    //
    //
    //
    const blue = AppColors.sagaBlue;
    final title = _isPrima ? 'Arretramento Cordoni' : 'Avanzamento Cordoni';
    final subtitle = _isPrima
        ? 'Torna indietro di N cordoni rispetto al cordone corrente (${widget.cordoneCorrente})'
        : 'Avanza di N cordoni rispetto al cordone corrente (${widget.cordoneCorrente})';
    final rangeHint = '0 — $_currentMax';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Radio Prima / Dopo ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _RadioOption(
                  label: 'Prima',
                  selected: _isPrima,
                  onTap: () => setState(() {
                    _isPrima = true;
                    _clamp();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RadioOption(
                  label: 'Dopo',
                  selected: !_isPrima,
                  onTap: () => setState(() {
                    _isPrima = false;
                    _clamp();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Testo contestuale ───────────────────────────────────
          Text(subtitle, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Intervallo: $rangeHint',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 12),
          // ── Stepper + TextField ─────────────────────────────────
          Row(
            children: [
              SizedBox(
                width: 42,
                child: ElevatedButton(
                  onPressed: _decrement,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(4),
                    backgroundColor: blue,
                    foregroundColor: blue,
                  ),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => _clamp(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: ElevatedButton(
                  onPressed: _increment,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(4),
                    backgroundColor: blue,
                    foregroundColor: blue,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.sagaBlue,
          ),
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annulla',
              style: TextStyle(color: AppColors.sagaBlue)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final v = int.tryParse(_ctrl.text);
            if (v == null) return;
            if (v < 0 || v > _currentMax) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Valore non compreso tra 0 e $_currentMax'),
                ),
              );
              return;
            }
            Navigator.of(context)
                .pop(_ResumeResult(count: v, isPrima: _isPrima));
          },
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  //
  //
  //
  final String label;
  final bool selected;
  final VoidCallback onTap;
  //
  //
  //
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  //
  //
  //
  @override
  Widget build(BuildContext context) {
    const blue = AppColors.sagaBlue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? blue.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? blue : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? blue : Colors.grey[500], size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? blue : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
//
//
class _AlignmentOption extends StatelessWidget {
  //
  //
  //
  final String value;
  final String selected;
  final String label;
  final String description;
  final IconData icon;
  final void Function(String) onTap;
  //
  //
  //
  const _AlignmentOption({
    required this.value,
    required this.selected,
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });
  //
  //
  //
  @override
  Widget build(BuildContext context) {
    //
    //
    //
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sagaBlue.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.sagaBlue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.sagaBlue : Colors.grey[600],
                size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.sagaBlue : Colors.black87,
                      )),
                  Text(description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.sagaBlue, size: 20),
          ],
        ),
      ),
    );
  }
  //
  //
  //
}
