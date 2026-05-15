import 'dart:convert';

SafePosition safePositionFromJson(String str) =>
    SafePosition.fromJson(json.decode(str));

String safePositionToJson(SafePosition data) => json.encode(data.toJson());

class SafePosition {
  final String orientation;
  final List<double> position;

  SafePosition({required this.orientation, required this.position});

  Map<String, dynamic> toJson() {
    return {'orientation': orientation, 'position': position};
  }

  factory SafePosition.fromJson(Map<String, dynamic> dict) {
    final orientation = (dict["orientation"] ?? dict["DXSX"] ?? "").toString();

    dynamic rawPosition = dict["position"] ?? dict["PositionJ"] ?? dict["Position"];
    if (rawPosition is String) {
      rawPosition = json.decode(rawPosition);
    }

    if (rawPosition is! List) {
      throw FormatException("SafePosition.position non valido");
    }

    return SafePosition(
      orientation: orientation,
      position: List<double>.from(rawPosition.map((x) => (x as num).toDouble())),
    );
  }
}
