
class Operatore {
  Operatore({required this.id, required this.nome, required this.cognome, required this.abilitazione, required this.apme, required this.abilitazioneut});

  int id;
  String nome;
  String cognome;
  String abilitazione;
  String apme;
  String abilitazioneut;

  Map<String, dynamic> toJson() {
    return {
      'id': 0,
      'nome': "",
      'cognome': "",
      'abilitazione': "",
      'apme': "",
      'abilitazioneut': "",
    };
  }
}