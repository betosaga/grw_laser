import 'dart:convert';

TipoFilo tipoFiloFromJson(String str) => TipoFilo.fromJson(json.decode(str));

String tipoFiloToJson(TipoFilo data) => json.encode(data.toJson());

class TipoFilo {
  TipoFilo({
    required this.id,
    required this.tipofilo,
    required this.abbreviazione,
    required this.wps,
  });
  int id;
  String tipofilo;
  String abbreviazione;
  String wps;

  factory TipoFilo.fromJson(Map<String, dynamic> json) => TipoFilo(
        id: json["id"],
        tipofilo: json["tipo_filo"],
        abbreviazione: json["abbreviazione"],
        wps: json["wps"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "tipo_filo": tipofilo,
        "abbreviazione": abbreviazione,
        "wps": wps,
      };
}
