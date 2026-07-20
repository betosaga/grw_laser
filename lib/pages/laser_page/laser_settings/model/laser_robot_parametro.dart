import 'dart:convert';

class LaserRobotParametro {
  final String parametro;
  final String tipo;
  final bool nullable;

  /// Valore effettivo condiviso tra le viste e i payload del robot.
  dynamic valore;
  final dynamic valoreDefault;
  final dynamic valoriAmmessi;
  final String? categoria;
  final String? descrizione;
  final int ordine;
  final bool modificabile;
  final bool personalizzato;

  LaserRobotParametro({
    required this.parametro,
    required this.tipo,
    required this.nullable,
    required this.valore,
    required this.valoreDefault,
    required this.valoriAmmessi,
    required this.categoria,
    required this.descrizione,
    required this.ordine,
    required this.modificabile,
    required this.personalizzato,
  });

  static String stringOrEmpty(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static bool boolOrDefault(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (['1', 'true', 'yes', 'si', 'on'].contains(normalized)) return true;
    if (['0', 'false', 'no', 'off'].contains(normalized)) return false;
    return defaultValue;
  }

  factory LaserRobotParametro.fromJson(Map<String, dynamic> json) {
    return LaserRobotParametro(
      parametro: stringOrEmpty(json['parametro']),
      tipo: stringOrEmpty(json['tipo']),
      nullable: boolOrDefault(json['nullable']),
      valore: json['valore'],
      valoreDefault: json['valore_default'],
      valoriAmmessi: json['valori_ammessi'],
      categoria: json['categoria']?.toString(),
      descrizione: json['descrizione']?.toString(),
      ordine: _intOrDefault(json['ordine']),
      modificabile: boolOrDefault(json['modificabile']),
      personalizzato: boolOrDefault(json['personalizzato']),
    );
  }

  static int _intOrDefault(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static String _valueToDisplay(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'true' : 'false';
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }

  String get displayValue => _valueToDisplay(valore);

  String get displayDefaultValue => _valueToDisplay(valoreDefault);

  String get categoryLabel => (categoria == null || categoria!.trim().isEmpty)
      ? 'Generale'
      : categoria!.trim();

  String get allowedValuesLabel {
    final allowed = valoriAmmessi;
    if (allowed == null) return 'Nessun vincolo';
    if (allowed is List) {
      return allowed.map(_valueToDisplay).join(', ');
    }
    if (allowed is Map) {
      return jsonEncode(allowed);
    }
    return allowed.toString();
  }

  Map<String, dynamic> toJson() => {
        'parametro': parametro,
        'tipo': tipo,
        'nullable': nullable,
        'valore': valore,
        'valore_default': valoreDefault,
        'valori_ammessi': valoriAmmessi,
        'categoria': categoria,
        'descrizione': descrizione,
        'ordine': ordine,
        'modificabile': modificabile,
        'personalizzato': personalizzato,
      };
}
