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
        codice: json["codice"],
        nome: json["nome"],
      );

  Map<String, dynamic> toJson() => {
        "codice": codice,
        "nome": nome,
      };
}
