import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grw_laser/common_components/gradient_app_bar_background.dart';
import 'package:grw_laser/common_components/loading_spinner.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/model/response/response_error.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_parametro.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_robot_settings.dart';
import 'package:grw_laser/services/api.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserRobotParametriPage extends StatefulWidget {
  final LaserPageController laserPageController;

  const LaserRobotParametriPage({
    super.key,
    required this.laserPageController,
  });

  @override
  State<LaserRobotParametriPage> createState() =>
      _LaserRobotParametriPageState();
}

class _LaserRobotParametriPageState extends State<LaserRobotParametriPage> {
  final Map<String, TextEditingController> _controllers = {};
  List<LaserRobotParametro> _parametri = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _syncFromSettings(widget.laserPageController.settings);
    if (_parametri.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFromServer();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void _syncFromSettings(LaserRobotSettings settings) {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    _parametri = List<LaserRobotParametro>.from(settings.parametri)
      ..sort((a, b) {
        final categoryCompare = a.categoryLabel.compareTo(b.categoryLabel);
        if (categoryCompare != 0) return categoryCompare;
        final ordineCompare = a.ordine.compareTo(b.ordine);
        if (ordineCompare != 0) return ordineCompare;
        return a.parametro.compareTo(b.parametro);
      });

    for (final parametro in _parametri) {
      _controllers[parametro.parametro] =
          TextEditingController(text: _displayValue(parametro.valore));
    }
  }

  Future<void> _loadFromServer() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Api.request({
        "f": "getRobotLaserDetail",
        "seriale_robot":
            widget.laserPageController.settings.serialeRobot.trim(),
      }, verbose: false);

      final currentSettings = robotLaserSettingsFromJson(response.body);
      await widget.laserPageController.setRobotSettings(
        newSettings: currentSettings,
      );
      if (!mounted) return;
      setState(() {
        _syncFromSettings(widget.laserPageController.settings);
      });
    } catch (e) {
      if (e is ResponseError && e.message.trim().isNotEmpty && mounted) {
        Messenger.showMessageGenericError(context, e.message, 2);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _displayValue(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'true' : 'false';
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  bool _isNumericType(String tipo) {
    final normalized = tipo.trim().toLowerCase();
    return const {
      'int',
      'integer',
      'intero',
      'tinyint',
      'smallint',
      'bigint',
      'float',
      'double',
      'decimal',
      'number',
      'numeric',
      'numero',
    }.contains(normalized);
  }

  bool _isBoolType(String tipo) {
    final normalized = tipo.trim().toLowerCase();
    return const {'bool', 'boolean', 'bit'}.contains(normalized);
  }

  bool _isJsonType(String tipo) {
    final normalized = tipo.trim().toLowerCase();
    return const {'json', 'array', 'object', 'lista'}.contains(normalized);
  }

  dynamic _parseValueForParametro(
      LaserRobotParametro parametro, String rawValue) {
    final tipo = parametro.tipo.trim().toLowerCase();
    final value = rawValue.trim();

    if (_isNumericType(tipo)) {
      if (value.isEmpty) {
        if (parametro.nullable) {
          return null;
        }
        throw FormatException(
            'Il parametro ${parametro.parametro} non puo essere nullo');
      }
      if (const {
        'int',
        'integer',
        'intero',
        'tinyint',
        'smallint',
        'bigint'
      }.contains(tipo)) {
        return int.parse(value);
      }
      return double.parse(value.replaceAll(',', '.'));
    }

    if (_isBoolType(tipo)) {
      if (value.isEmpty) {
        if (parametro.nullable) {
          return null;
        }
        throw FormatException(
            'Il parametro ${parametro.parametro} non puo essere nullo');
      }
      final normalized = value.toLowerCase();
      if (const ['1', 'true', 'yes', 'si', 'on'].contains(normalized)) {
        return true;
      }
      if (const ['0', 'false', 'no', 'off'].contains(normalized)) {
        return false;
      }
      throw FormatException('Il parametro ${parametro.parametro} deve essere booleano');
    }

    if (_isJsonType(tipo)) {
      if (value.isEmpty) {
        if (parametro.nullable) {
          return null;
        }
        throw FormatException(
            'Il parametro ${parametro.parametro} non puo essere nullo');
      }
      return jsonDecode(value);
    }

    return rawValue;
  }

  dynamic _comparableValue(dynamic value) {
    if (value == null) return '__NULL__';
    if (value is bool) return value ? '1' : '0';
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  bool _isValueAllowed(dynamic value, dynamic allowed) {
    if (allowed == null || value == null) return true;

    if (allowed is List) {
      final target = _comparableValue(value);
      for (var option in allowed) {
        if (option is Map && option.containsKey('valore')) {
          option = option['valore'];
        } else if (option is Map && option.containsKey('value')) {
          option = option['value'];
        }
        if (_comparableValue(option) == target) {
          return true;
        }
      }
      return false;
    }

    if (allowed is Map) {
      for (final key in ['valori', 'values', 'opzioni', 'options']) {
        final nested = allowed[key];
        if (nested is List) {
          return _isValueAllowed(value, nested);
        }
      }

      if (value is num) {
        if (allowed.containsKey('min') &&
            value.toDouble() < double.parse(allowed['min'].toString())) {
          return false;
        }
        if (allowed.containsKey('max') &&
            value.toDouble() > double.parse(allowed['max'].toString())) {
          return false;
        }
      }
    }

    return true;
  }

  String? _validateParametro(LaserRobotParametro parametro) {
    final controller = _controllers[parametro.parametro];
    if (controller == null) {
      return 'Parametro ${parametro.parametro} non disponibile';
    }

    try {
      final parsedValue = _parseValueForParametro(parametro, controller.text);
      if (!_isValueAllowed(parsedValue, parametro.valoriAmmessi)) {
        return 'Valore non ammesso per ${parametro.parametro}';
      }
    } on FormatException catch (e) {
      return e.message;
    } catch (_) {
      return 'Valore non valido per ${parametro.parametro}';
    }

    return null;
  }

  Future<void> _saveParameters() async {
    final errors = <String>[];
    for (final parametro in _parametri) {
      final error = _validateParametro(parametro);
      if (error != null) {
        errors.add(error);
      }
    }

    if (errors.isNotEmpty) {
      Messenger.showMessageGenericError(context, errors.first, 2);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final payload = _parametri.map((parametro) {
        final controller = _controllers[parametro.parametro];
        final rawValue = controller?.text ?? '';
        final value = parametro.modificabile
            ? _parseValueForParametro(parametro, rawValue)
            : parametro.valore;
        return {
          'parametro': parametro.parametro,
          'valore': value,
        };
      }).toList();

      final response = await Api.request({
        "f": "setImpostazioniRobotLaser",
        "seriale_start": widget.laserPageController.settings.serialeRobot,
        "seriale_robot": widget.laserPageController.settings.serialeRobot,
        "ip_robot": widget.laserPageController.settings.ipRobot,
        "ip_server": widget.laserPageController.settings.ipServer,
        "pin_gas": widget.laserPageController.settings.pinGas,
        "pin_laser": widget.laserPageController.settings.pinLaser,
        "pin_massa": widget.laserPageController.settings.pinMassa,
        "allontanamento_x":
            widget.laserPageController.settings.scostamentoX.toString(),
        "allontanamento_y":
            widget.laserPageController.settings.scostamentoY.toString(),
        "allontanamento_z":
            widget.laserPageController.settings.scostamentoZ.toString(),
        "parametri": jsonEncode(payload),
      }, verbose: false);

      final currentSettings = robotLaserSettingsFromJson(response.body);
      await widget.laserPageController.setRobotSettings(
        newSettings: currentSettings,
      );
      if (!mounted) return;
      setState(() {
        _syncFromSettings(widget.laserPageController.settings);
      });
      Messenger.showSnackBar(context, textToShow: 'Parametri salvati correttamente');
    } catch (e) {
      if (e is ResponseError && e.message.trim().isNotEmpty && mounted) {
        Messenger.showMessageGenericError(context, e.message, 2);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Map<String, List<LaserRobotParametro>> _groupByCategory() {
    final grouped = <String, List<LaserRobotParametro>>{};
    for (final parametro in _parametri) {
      grouped.putIfAbsent(parametro.categoryLabel, () => []);
      grouped[parametro.categoryLabel]!.add(parametro);
    }
    return grouped;
  }

  Widget _buildParametroCard(LaserRobotParametro parametro) {
    final controller = _controllers[parametro.parametro]!;
    final isNumeric = _isNumericType(parametro.tipo);
    final isBool = _isBoolType(parametro.tipo);
    final isJson = _isJsonType(parametro.tipo);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parametro.parametro,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tipo: ${parametro.tipo} | Ordine: ${parametro.ordine} | ${parametro.modificabile ? 'Modificabile' : 'Bloccato'}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (parametro.personalizzato)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sagaBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Personalizzato',
                      style: TextStyle(
                        color: AppColors.sagaBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if ((parametro.descrizione ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                parametro.descrizione!.trim(),
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Valori ammessi: ${parametro.allowedValuesLabel}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            if (isBool)
              TextFormField(
                controller: controller,
                enabled: parametro.modificabile,
                decoration: const InputDecoration(
                  labelText: 'Valore',
                ),
                keyboardType: TextInputType.text,
              )
            else
              TextFormField(
                controller: controller,
                enabled: parametro.modificabile,
                decoration: InputDecoration(
                  labelText: 'Valore',
                  helperText: isJson
                      ? 'Inserisci JSON valido'
                      : (isNumeric
                          ? 'Inserisci un numero'
                          : 'Valore testuale'),
                ),
                keyboardType: isNumeric
                    ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                    : TextInputType.text,
                minLines: isJson ? 3 : 1,
                maxLines: isJson ? 6 : 1,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Listener(
          onPointerDown: (_) => Vibrator.shortVibration(),
          child: TextButton(
            child: const Icon(
              Icons.arrow_back_ios_new_sharp,
              color: Colors.white,
            ),
            onPressed: () => Pager.pop(context),
          ),
        ),
        actions: [
          Listener(
            onPointerDown: (_) => Vibrator.shortVibration(),
            child: TextButton.icon(
              onPressed: isLoading ? null : _loadFromServer,
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              label: const Text(
                'AGGIORNA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Listener(
            onPointerDown: (_) => Vibrator.shortVibration(),
            child: TextButton(
              onPressed: isLoading ? null : _saveParameters,
              child: const Text(
                'SALVA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const GradientAppBarBackground(),
        title: Text(
          'TUTTI I PARAMETRI - ${widget.laserPageController.settings.serialeRobot}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: LoadingSpinner(color: AppColors.sagaBlue),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: grouped.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${entry.value.length} parametri',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      children: entry.value
                          .map((parametro) => _buildParametroCard(parametro))
                          .toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
