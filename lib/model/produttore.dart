
class Produttore {
  Produttore({this.costruttore, this.ut});

  String? costruttore;
  int? ut;

  Map<String, dynamic> toJson() {
    return {
      'costruttore': "",
      'ut': 0,
    };
  }
}
