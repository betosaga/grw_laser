// To parse this JSON data, do
//
//     final laserRobotModalita = laserRobotModalitaFromJson(jsonString);

import 'dart:convert';

LaserRobotModalita laserRobotModalitaFromJson(String str) =>
    LaserRobotModalita.fromJson(json.decode(str));

String laserRobotModalitaToJson(LaserRobotModalita data) =>
    json.encode(data.toJson());

class LaserRobotModalita {
  String codice;
  String nome;

  LaserRobotModalita({
    required this.codice,
    required this.nome,
  });

  factory LaserRobotModalita.fromJson(Map<String, dynamic> json) =>
      LaserRobotModalita(
        codice: _normalizeCodice(json["codice"]),
        nome: (json["nome"] ?? "").toString().trim(),
      );

  static String _normalizeCodice(dynamic value) {
    final codice = (value ?? '').toString().trim().toLowerCase();
    // Il database usa questo alias; il protocollo robot usa "piano".
    return codice == 'piano-rotolamento' ? 'piano' : codice;
  }

  Map<String, dynamic> toJson() => {
        "codice": codice,
        "nome": nome,
      };
}
