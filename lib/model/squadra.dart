// To parse this JSON data, do
//
//     final squadra = squadraFromJson(jsonString);

import 'dart:convert';

Squadra squadraFromJson(String str) => Squadra.fromJson(json.decode(str));
String squadraToJson(Squadra data) => json.encode(data.toJson());
List<Squadra> squadreFromJson(String str) => List<Squadra>.from(json.decode(str).map((x) => Squadra.fromJson(x)));
String squadreToJson(List<Squadra> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Squadra {
    int id;
    String nome;
    int ordine;

    Squadra({
        required this.id,
        required this.nome,
        required this.ordine,
    });

    factory Squadra.fromJson(Map<String, dynamic> json) => Squadra(
        id: json["id"],
        nome: json["nome"],
        ordine: json["ordine"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "nome": nome,
        "ordine": ordine,
    };
}
