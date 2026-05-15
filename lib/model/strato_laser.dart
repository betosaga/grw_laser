import 'dart:convert';

StratoLaser stratoLaserFromJson(String str) =>
    StratoLaser.fromJson(json.decode(str));
String stratoLaserToJson(StratoLaser data) => json.encode(data.toJson());

List<StratoLaser> stratoLaserListFromJson(String str) => List<StratoLaser>.from(
    json.decode(str).map((x) => StratoLaser.fromJson(x)));

String stratoLaserListToJson(List<StratoLaser> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class StratoLaser {
  bool eseguito;
  String durata;
  int lastCordone;

  StratoLaser({this.eseguito = false, this.durata = "", this.lastCordone = 0});

  factory StratoLaser.fromJson(Map<String, dynamic> json) => StratoLaser(
        eseguito: json["eseguito"],
        durata: json["durata"],
        lastCordone: json["lastCordone"],
      );

  Map<String, dynamic> toJson() =>
      {"eseguito": eseguito, "durata": durata, "lastCordone": lastCordone};

  String getDurataFormatted() {
    final raw = durata.trim();
    if (raw.isEmpty) return "";

    if (raw.contains(':')) {
      return raw;
    }

    final normalized = raw.replaceAll(',', '.');
    final parsedSeconds = double.tryParse(normalized);
    if (parsedSeconds == null || parsedSeconds.isNaN || parsedSeconds < 0) {
      return "";
    }

    final totalSeconds = parsedSeconds.floor();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
