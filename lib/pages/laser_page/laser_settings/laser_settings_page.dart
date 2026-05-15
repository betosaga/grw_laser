import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:grw_laser/common_components/loading_spinner.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/response/response_error.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/components/laser_robot_position_banner.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/laser_diagnostics_page.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/components/laser_robot_compact_field.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/components/laser_robot_setting_row.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_limite.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/services/api.dart';
import 'package:grw_laser/services/hive_disk_encoder.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class _LaserLimiteFormData {
  //
  //
  //
  int? id;
  final TextEditingController limiteZDownController;
  final TextEditingController stepUpController;
  final TextEditingController stepDownController;
  final TextEditingController stepUpSxController;
  final TextEditingController stepUpDxController;
  final TextEditingController stepDownSxController;
  final TextEditingController stepDownDxController;
  final TextEditingController stepLeftController;
  final TextEditingController stepRightController;
  final TextEditingController stepYController;
  String tipoControrotaia;
  //
  //
  //
  _LaserLimiteFormData({
    required this.id,
    required this.limiteZDownController,
    required this.stepUpController,
    required this.stepDownController,
    required this.stepUpSxController,
    required this.stepUpDxController,
    required this.stepDownSxController,
    required this.stepDownDxController,
    required this.stepLeftController,
    required this.stepRightController,
    required this.stepYController,
    required this.tipoControrotaia,
  });
  //
  //
  //
  void dispose() {
    limiteZDownController.dispose();
    stepUpController.dispose();
    stepDownController.dispose();
    stepUpSxController.dispose();
    stepUpDxController.dispose();
    stepDownSxController.dispose();
    stepDownDxController.dispose();
    stepLeftController.dispose();
    stepRightController.dispose();
    stepYController.dispose();
  }
}

class LaserSettingsPage extends StatefulWidget {
  final LaserPageController laserPageController;
  const LaserSettingsPage({required this.laserPageController});

  @override
  State<LaserSettingsPage> createState() => _LaserSettingsPageState();
}

//
//
//
class _LaserSettingsPageState extends State<LaserSettingsPage> {
  //
  //
  //
  bool isLoading = false;
  //
  //
  //
  final box = HiveDiskEncoder();
  //
  //
  //
  final serialeRobotEditingController = TextEditingController();
  final ipRobotEditingController = TextEditingController();
  final ipServerEditingController = TextEditingController();
  final pinGasEditingController = TextEditingController();
  final pinLaserEditingController = TextEditingController();
  final pinMassaEditingController = TextEditingController();
  final scostamentoXEditingController = TextEditingController();
  final scostamentoYEditingController = TextEditingController();
  final scostamentoZEditingController = TextEditingController();
  final List<_LaserLimiteFormData> limiteRows = [];

  final double fieldSpacing = 20.0;

  @override
  void initState() {
    // prendo settings aggiornate dal server
    serialeRobotEditingController.text =
        widget.laserPageController.settings.serialeRobot;
    ipRobotEditingController.text = widget.laserPageController.settings.ipRobot;
    ipServerEditingController.text =
        widget.laserPageController.settings.ipServer;
    pinGasEditingController.text = widget.laserPageController.settings.pinGas;
    pinLaserEditingController.text =
        widget.laserPageController.settings.pinLaser;
    pinMassaEditingController.text =
        widget.laserPageController.settings.pinMassa;
    scostamentoXEditingController.text =
        widget.laserPageController.settings.scostamentoX.toString();
    scostamentoYEditingController.text =
        widget.laserPageController.settings.scostamentoY.toString();
    scostamentoZEditingController.text =
        widget.laserPageController.settings.scostamentoZ.toString();
    _setLimitiRowsFromSettings(widget.laserPageController.settings);
    super.initState();
  }

  @override
  void dispose() {
    serialeRobotEditingController.dispose();
    ipRobotEditingController.dispose();
    ipServerEditingController.dispose();
    pinGasEditingController.dispose();
    pinLaserEditingController.dispose();
    pinMassaEditingController.dispose();
    scostamentoXEditingController.dispose();
    scostamentoYEditingController.dispose();
    scostamentoZEditingController.dispose();
    for (final row in limiteRows) {
      row.dispose();
    }
    super.dispose();
  }

  _LaserLimiteFormData _newLimiteFormData({LaserRobotLimite? limite}) {
    final current = limite ?? const LaserRobotLimite();
    return _LaserLimiteFormData(
      id: current.id,
      limiteZDownController:
          TextEditingController(text: current.limiteZDown.toString()),
      stepUpController:
          TextEditingController(text: _formatDouble(current.stepUp)),
      stepDownController:
          TextEditingController(text: _formatDouble(current.stepDown)),
      stepUpSxController:
          TextEditingController(text: _formatDouble(current.stepUpSx)),
      stepUpDxController:
          TextEditingController(text: _formatDouble(current.stepUpDx)),
      stepDownSxController:
          TextEditingController(text: _formatDouble(current.stepDownSx)),
      stepDownDxController:
          TextEditingController(text: _formatDouble(current.stepDownDx)),
      stepLeftController:
          TextEditingController(text: _formatDouble(current.stepLeft)),
      stepRightController:
          TextEditingController(text: _formatDouble(current.stepRight)),
      stepYController:
          TextEditingController(text: _formatDouble(current.stepY)),
      tipoControrotaia: _normalizeTipoControrotaia(current.tipoControrotaia),
    );
  }

  void _setLimitiRowsFromSettings(LaserRobotSettings settings) {
    for (final row in limiteRows) {
      row.dispose();
    }
    limiteRows.clear();

    if (settings.limiti.isNotEmpty) {
      for (final limite in settings.limiti) {
        limiteRows.add(_newLimiteFormData(limite: limite));
      }
      return;
    }

    limiteRows.add(_newLimiteFormData(
      limite: LaserRobotLimite(
        limiteZDown: settings.limiteZDown,
        stepUp: settings.stepUp,
        stepDown: settings.stepDown,
        stepUpSx: settings.stepUpSx,
        stepUpDx: settings.stepUpDx,
        stepDownSx: settings.stepDownSx,
        stepDownDx: settings.stepDownDx,
        stepLeft: settings.stepLeft,
        stepRight: settings.stepRight,
        stepY: settings.stepY,
        tipoControrotaia: settings.tipoControrotaia,
      ),
    ));
  }

  String get _currentTipo => _normalizeTipoControrotaia(
      widget.laserPageController.controrotaiaModeValue);

  List<int> _selectedTipoRowIndexes() {
    final indexes = <int>[];
    for (var i = 0; i < limiteRows.length; i++) {
      if (_normalizeTipoControrotaia(limiteRows[i].tipoControrotaia) ==
          _currentTipo) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  String _tipoControrotaiaLabel(String tipo) {
    switch (tipo) {
      case 'controrotaiadoppia':
        return 'Controrotaia Doppia';
      case 'piano':
        return 'Piano di Rotolamento';
      default:
        return 'Controrotaia Semplice';
    }
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

  String _formatDouble(double value) {
    final normalized = value.toStringAsFixed(3);
    return normalized.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _normalizeNumericInput(String text) {
    return text.trim().replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    final selectedTipoIndexes = _selectedTipoRowIndexes();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Listener(
            onPointerDown: (_) => Vibrator.shortVibration(),
            child: TextButton(
              child: Icon(
                Icons.arrow_back_ios_new_sharp,
                color: Colors.white,
              ),
              onPressed: () => Pager.pop(context),
            )),
        actions: [
          Listener(
              onPointerDown: (_) => Vibrator.shortVibration(),
              child: TextButton.icon(
                onPressed: () {
                  Pager.push(
                    context: context,
                    page: LaserDiagnosticsPage(
                      laserPageController: widget.laserPageController,
                      initialRobotIp: ipRobotEditingController.text.trim(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.monitor_heart,
                  color: Colors.white,
                ),
                label: const Text(
                  'DIAGNOSTICA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          Listener(
              onPointerDown: (_) => Vibrator.shortVibration(),
              child: TextButton(
                  onPressed: updateSettingsFromServer,
                  child: Icon(
                    Icons.update,
                    color: Colors.white,
                  ))),
          Listener(
              onPointerDown: (_) => Vibrator.shortVibration(),
              child: TextButton(
                  onPressed: saveSettings,
                  child: Text(
                    "SALVA",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  )))
        ],
        backgroundColor: AppColors.sagaBlue,
        title: Text(
          "IMPOSTAZIONI ROBOT LASER - ${widget.laserPageController.settings.serialeRobot}",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: isLoading
            ? Center(
                child: LoadingSpinner(
                  color: AppColors.sagaBlue,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'IP ROBOT: ',
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: fieldSpacing),
                          Expanded(
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              controller: ipRobotEditingController,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LaserRobotSettingRow(
                        title: "IP SERVER: ",
                        elementsSpacing: fieldSpacing,
                        controller: ipServerEditingController),
                    LaserRobotSettingRow(
                        title: "PIN GAS: ",
                        elementsSpacing: fieldSpacing,
                        controller: pinGasEditingController),
                    LaserRobotSettingRow(
                        title: "PIN LASER: ",
                        elementsSpacing: fieldSpacing,
                        controller: pinLaserEditingController),
                    LaserRobotSettingRow(
                        title: "PIN MASSA: ",
                        elementsSpacing: fieldSpacing,
                        controller: pinMassaEditingController),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SCOSTAMENTI",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: LaserRobotCompactField(
                                  title: 'SCOSTAMENTO X',
                                  controller: scostamentoXEditingController,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LaserRobotCompactField(
                                  title: 'SCOSTAMENTO Y',
                                  controller: scostamentoYEditingController,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LaserRobotCompactField(
                                  title: 'SCOSTAMENTO Z',
                                  controller: scostamentoZEditingController,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIMITI (${selectedTipoIndexes.length})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tipo Controrotaia: ${_tipoControrotaiaLabel(_currentTipo)}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            mySetState(() {
                              limiteRows.add(_newLimiteFormData(
                                  limite: LaserRobotLimite(
                                      tipoControrotaia: _currentTipo)));
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Aggiungi riga'),
                        ),
                      ],
                    ),
                    Center(
                      child: LaserRobotPositionBanner(
                        controller: widget.laserPageController,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(selectedTipoIndexes.length,
                        (filteredIndex) {
                      final rowIndex = selectedTipoIndexes[filteredIndex];
                      final row = limiteRows[rowIndex];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Riga limite ${filteredIndex + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                  'Conferma eliminazione'),
                                              content: Text(
                                                  'Eliminare la riga limite ${filteredIndex + 1}?'),
                                              actions: [
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppColors.sagaBlue),
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(false),
                                                  child: const Text('ANNULLA'),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.red.shade700,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(true),
                                                  child: const Text('ELIMINA'),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                      if (!confirmed) return;
                                      mySetState(() {
                                        final toDelete =
                                            limiteRows.removeAt(rowIndex);
                                        toDelete.dispose();
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('ELIMINA'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'LIM Z DOWN',
                                      controller: row.limiteZDownController,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP UP',
                                      controller: row.stepUpController,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP DOWN',
                                      controller: row.stepDownController,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP UP SX',
                                      controller: row.stepUpSxController,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP UP DX',
                                      controller: row.stepUpDxController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP DOWN SX',
                                      controller: row.stepDownSxController,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP DOWN DX',
                                      controller: row.stepDownDxController,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP LEFT',
                                      controller: row.stepLeftController,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP RIGHT',
                                      controller: row.stepRightController,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LaserRobotCompactField(
                                      title: 'STEP Y',
                                      controller: row.stepYController,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }

  void writeDataToDisk({required LaserRobotSettings writingSettings}) {
    // read settings from disk:
    final settingsString =
        box.stringFor(key: Constants.HIVE_LASER_SETTINGS_LIST_KEY);
    if (settingsString != null && settingsString != "") {
      try {
        final currentSettingsList =
            robotLaserSettingsListFromJson(settingsString);

        for (int i = 0; i < currentSettingsList.length; i++) {
          final currentSettings = currentSettingsList[i];

          if (currentSettings.serialeRobot == writingSettings.serialeRobot) {
            // aggiorno i campi
            currentSettingsList[i] = writingSettings;
            break;
          }
        }

        final currentEncoded =
            robotLaserSettingsListToJson(currentSettingsList);
        box.setString(
            value: currentEncoded, key: Constants.HIVE_LASER_SETTINGS_LIST_KEY);
      } catch (e) {
        print("Failed to parse Settings String From Disk");
      }
    }
  }

  void updateFields({required LaserRobotSettings settings}) {
    serialeRobotEditingController.text = settings.serialeRobot;
    ipRobotEditingController.text = settings.ipRobot;
    ipServerEditingController.text = settings.ipServer;
    pinGasEditingController.text = settings.pinGas;
    pinLaserEditingController.text = settings.pinLaser;
    pinMassaEditingController.text = settings.pinMassa;
    scostamentoXEditingController.text = settings.scostamentoX.toString();
    scostamentoYEditingController.text = settings.scostamentoY.toString();
    scostamentoZEditingController.text = settings.scostamentoZ.toString();
    _setLimitiRowsFromSettings(settings);
  }

  Future<void> updateSettingsFromServer() async {
    mySetState(() {
      isLoading = true;
    });

    try {
      final response = await Api.request({
        "f": "getImpostazioniRobotLaser",
        "seriale_robot": widget.laserPageController.settings.serialeRobot
      }, verbose: false);

      final currentSettings = robotLaserSettingsFromJson(response.body);

      writeDataToDisk(writingSettings: currentSettings);
      updateFields(settings: currentSettings);
      widget.laserPageController.setRobotSettings(newSettings: currentSettings);
    } catch (e) {
      if (e is ResponseError) {
        if (e.message.trim() != "")
          Messenger.showMessageGenericError(context, e.message, 2);
      }
    } finally {
      mySetState(() {
        isLoading = false;
      });
    }
  }

  void fetchSettings() async {
    //
    mySetState(() {
      isLoading = true;
    });

    try {
      final response = await Api.request({
        "f": "getImpostazioniRobotLaser",
        "seriale_robot": widget.laserPageController.settings.serialeRobot
      }, verbose: false);

      final currentSettings = robotLaserSettingsFromJson(response.body);
      updateFields(settings: currentSettings);
    } catch (e) {
      if (e is ResponseError) {
        if (e.message.trim() != "")
          Messenger.showMessageGenericError(context, e.message, 2);
      }
    } finally {
      mySetState(() {
        isLoading = false;
      });
    }
  }

  void saveSettings() async {
    //
    //
    //
    if (serialeRobotEditingController.text.trim() == "") {
      Messenger.showMessageGenericError(
          context, "Inserire un seriale robot valido", 2);

      return;
    }

    mySetState(() {
      isLoading = true;
    });

    try {
      final limitiPayload = limiteRows
          .map((row) => {
                if (row.id != null) 'id': row.id,
                'limite_z_down':
                    _normalizeNumericInput(row.limiteZDownController.text),
                'step_up': _normalizeNumericInput(row.stepUpController.text),
                'step_down':
                    _normalizeNumericInput(row.stepDownController.text),
                'step_up_sx':
                    _normalizeNumericInput(row.stepUpSxController.text),
                'step_up_dx':
                    _normalizeNumericInput(row.stepUpDxController.text),
                'step_down_sx':
                    _normalizeNumericInput(row.stepDownSxController.text),
                'step_down_dx':
                    _normalizeNumericInput(row.stepDownDxController.text),
                'step_left':
                    _normalizeNumericInput(row.stepLeftController.text),
                'step_right':
                    _normalizeNumericInput(row.stepRightController.text),
                'step_y': _normalizeNumericInput(row.stepYController.text),
                'tipo_controrotaia':
                    _normalizeTipoControrotaia(row.tipoControrotaia),
              })
          .toList();

      //
      //
      final payload = <String, String>{
        "f": "setImpostazioniRobotLaser",
        "seriale_start": widget.laserPageController.settings.serialeRobot,
        "seriale_robot": widget.laserPageController.settings.serialeRobot,
        "ip_robot": ipRobotEditingController.text,
        "ip_server": ipServerEditingController.text,
        "pin_gas": pinGasEditingController.text,
        "pin_laser": pinLaserEditingController.text,
        "pin_massa": pinMassaEditingController.text,
        "allontanamento_x":
            _normalizeNumericInput(scostamentoXEditingController.text),
        "allontanamento_y":
            _normalizeNumericInput(scostamentoYEditingController.text),
        "allontanamento_z":
            _normalizeNumericInput(scostamentoZEditingController.text),
        "limiti": jsonEncode(limitiPayload),
      };

      final response = await Api.request(payload, verbose: false);

      //
      //
      final currentSettings = robotLaserSettingsFromJson(response.body);
      //
      writeDataToDisk(writingSettings: currentSettings);
      updateFields(settings: currentSettings);
      //
      //
      widget.laserPageController.setRobotSettings(newSettings: currentSettings);
      //
      //
    } catch (e) {
      print(e.toString());
      if (e is ResponseError) {
        if (e.message.trim() != "")
          Messenger.showMessageGenericError(context, e.message, 2);
      }
    } finally {
      mySetState(() {
        isLoading = false;
      });
    }
  }

  void mySetState(VoidCallback? f) {
    if (f == null) return;
    if (mounted) {
      setState(f);
    }
  }
}
