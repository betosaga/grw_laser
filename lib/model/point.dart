import 'dart:convert';
import 'dart:ui';

Point pointFromJson(String str) => Point.fromJson(json.decode(str));

String pointToJson(Point data) => json.encode(data.toJson());

class Point {
  double x;
  double y;
  double z;
  double j1;
  double j2;
  double j3;
  double jt1;
  double jt2;
  double jt3;
  double jt4;
  double jt5;
  double jt6;
  Offset? dashboardPosition;
  int? order;
  bool isFirst = false;
  bool isSelected = false;
  bool isBase = false;
  bool isLimite = false;
  
  // Nuovo campo aggiungibile dopo l'istanziazione
  PointJ? positionJ;

  Point(
      {this.x = 0.0,
      this.y = 0.0,
      this.z = 0.0,
      this.j1 = 0.0,
      this.j2 = 0.0,
      this.j3 = 0.0,
      this.jt1 = 0.0,
      this.jt2 = 0.0,
      this.jt3 = 0.0,
      this.jt4 = 0.0,
      this.jt5 = 0.0,
      this.jt6 = 0.0,
      this.dashboardPosition = null,
      this.order = null,
      this.isFirst = false,
      this.positionJ});

  bool isDefault() {
    return x == 0 && y == 0 && z == 0 && j1 == 0 && j2 == 0 && j3 == 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'j1': j1,
      'j2': j2,
      'j3': j3,
      'jt1': jt1,
      'jt2': jt2,
      'jt3': jt3,
      'jt4': jt4,
      'jt5': jt5,
      'jt6': jt6,
      'order': order,
      'dashboard_position': dashboardPosition != null
          ? {"dx": dashboardPosition!.dx, "dy": dashboardPosition!.dy}
          : null,
      'is_first': isFirst,
      'position_j': positionJ?.toJson(), // Codifica positionJ se presente
    };
  }

  static Point fromJson(Map<String, dynamic> json) {
    print("[getPoint] asdf ${jsonEncode(json)}");
    
    final point = Point(
      x: json["x"]?.toDouble() ?? 0.0,
      y: json["y"]?.toDouble() ?? 0.0,
      z: json["z"]?.toDouble() ?? 0.0,
      j1: json["j1"]?.toDouble() ?? 0.0,
      j2: json["j2"]?.toDouble() ?? 0.0,
      j3: json["j3"]?.toDouble() ?? 0.0,
      jt1: json["jt1"]?.toDouble() ?? 0.0,
      jt2: json["jt2"]?.toDouble() ?? 0.0,
      jt3: json["jt3"]?.toDouble() ?? 0.0,
      jt4: json["jt4"]?.toDouble() ?? 0.0,
      jt5: json["jt5"]?.toDouble() ?? 0.0,
      jt6: json["jt6"]?.toDouble() ?? 0.0,
      dashboardPosition: json["dashboard_position"] != null
          ? Offset(json["dashboard_position"]["dx"]?.toDouble(),
              json["dashboard_position"]["dy"]?.toDouble())
          : null,
      order: json["order"],
      isFirst: json["is_first"] ?? false,
    );

    // Parsing di positionJ se presente nel JSON
    if (json["position_j"] != null) {
      point.positionJ = PointJ.fromJson(json["position_j"]);
    }

    print("[getPoint]: PARSATO CORRETTAMENTE");

    return point;
  }

  bool isEqualTo({required Point point}) {
    return this.x == point.x &&
        this.y == point.y &&
        this.z == point.z &&
        this.j1 == point.j1 &&
        this.j2 == point.j2 &&
        this.j3 == point.j3;
  }
}

// Assicurati che PointJ abbia un metodo fromJson per supportare il parsing sopra
class PointJ {
  double j1 = 0.0;
  double j2 = 0.0;
  double j3 = 0.0;
  double j4 = 0.0;
  double j5 = 0.0;
  double j6 = 0.0;

  PointJ(List<double> values) {
    if (values.isNotEmpty) j1 = values[0];
    if (values.length > 1) j2 = values[1];
    if (values.length > 2) j3 = values[2];
    if (values.length > 3) j4 = values[3];
    if (values.length > 4) j5 = values[4];
    if (values.length > 5) j6 = values[5];
  }

  // Costruttore factory per supportare Point.fromJson
  static PointJ fromJson(Map<String, dynamic> json) {
    return PointJ([
      json['j1']?.toDouble() ?? 0.0,
      json['j2']?.toDouble() ?? 0.0,
      json['j3']?.toDouble() ?? 0.0,
      json['j4']?.toDouble() ?? 0.0,
      json['j5']?.toDouble() ?? 0.0,
      json['j6']?.toDouble() ?? 0.0,
    ]);
  }

  Map<String, double> toJson() {
    return {
      'j1': j1,
      'j2': j2,
      'j3': j3,
      'j4': j4,
      'j5': j5,
      'j6': j6,
    };
  }
}