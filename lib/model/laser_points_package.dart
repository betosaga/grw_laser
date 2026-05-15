import 'dart:convert';
import 'package:grw_laser/model/points_free.dart';
import 'package:grw_laser/pages/laser_page/model/safe_position.dart';

// Single
LaserPointsPackage laserPointsPackageFromJson(String str) =>
    LaserPointsPackage.fromJson(json.decode(str));

String laserPointsPackageToJson(LaserPointsPackage data) =>
    json.encode(data.toJson());

// List
List<LaserPointsPackage> laserPointsPackageListFromJson(String str) =>
    List<LaserPointsPackage>.from(
        json.decode(str).map((x) => LaserPointsPackage.fromJson(x)));
String laserPointsPackageListToJson(List<LaserPointsPackage> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

List<LaserPointsPackage> laserPointsPackageListFromServerJson(String str) {
  final decoded = json.decode(str);
  if (decoded is! List) return [];

  return decoded
      .map((item) => LaserPointsPackage.fromServerJson(item))
      .toList();
}

class LaserPointsPackage {
  final int? id;
  final DateTime datetime;
  final PointsFree points;
  final String label;
  final SafePosition? safePosition;

  LaserPointsPackage(
      {this.id,
      required this.datetime,
      required this.points,
      required this.label,
      this.safePosition});

  factory LaserPointsPackage.fromJson(Map<String, dynamic> json) {
    SafePosition? safePosition;
    final safeRaw = json["safe_position"];
    if (safeRaw != null) {
      try {
        final safeMap = safeRaw is String
            ? Map<String, dynamic>.from(jsonDecode(safeRaw))
            : Map<String, dynamic>.from(safeRaw as Map);
        safePosition = SafePosition.fromJson(safeMap);
      } catch (_) {}
    }
    return LaserPointsPackage(
        id: json["id"] == null ? null : int.tryParse(json["id"].toString()),
        datetime: DateTime.parse(json["datetime"]),
        points: PointsFree.fromJson(json["points"]),
        label: json["label"],
        safePosition: safePosition);
  }

  factory LaserPointsPackage.fromServerJson(dynamic payload) {
    final map = payload is Map<String, dynamic>
        ? payload
        : Map<String, dynamic>.from(payload as Map);

    final puntiRaw = map["punti"];
    final puntiJson = puntiRaw is String ? json.decode(puntiRaw) : puntiRaw;
    final dateRaw = (map["dataora"] ?? map["datetime"] ?? "").toString();

    SafePosition? safePosition;
    final safeRaw = map["safe_position"];
    if (safeRaw != null) {
      try {
        final safeMap = safeRaw is String
            ? Map<String, dynamic>.from(json.decode(safeRaw))
            : Map<String, dynamic>.from(safeRaw as Map);
        safePosition = SafePosition.fromJson(safeMap);
      } catch (_) {}
    }

    return LaserPointsPackage(
      id: map["id"] == null ? null : int.tryParse(map["id"].toString()),
      datetime: DateTime.tryParse(dateRaw) ?? DateTime.now(),
      points: PointsFree.fromJson(Map<String, dynamic>.from(puntiJson)),
      label: (map["nome"] ?? map["label"] ?? "").toString(),
      safePosition: safePosition,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "datetime": datetime.toIso8601String(),
        "points": points.toJson(),
        "label": label,
        if (safePosition != null) "safe_position": safePosition!.toJson(),
      };
}
