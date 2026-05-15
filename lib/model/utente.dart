import 'dart:convert';

Utente utenteFromJson(String str) => Utente.fromJson(json.decode(str));
String utenteToJson(Utente data) => json.encode(data.toJson());

//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
class Utente {
  //
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //
  int id;
  String userToken;
  int? idsocieta;
  String nome;
  String cognome;
  String username;
  String? avatar;
  String email;
  int idsquadra;
  String abilitazione;
  String? abilitazioneUT;
  String apme;
  String? squadra;
  String? squadraUT;
  String? squadraFX;
  int idsquadraUT;
  int idsquadraFX;
  String tipoutente;
  int modificaparametrirobot;
  List<String> permessi;
  //
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //
  Utente(
      {required this.id,
      required this.userToken,
      required this.idsocieta,
      required this.nome,
      required this.cognome,
      required this.username,
      required this.avatar,
      required this.email,
      required this.idsquadra,
      required this.abilitazione,
      required this.abilitazioneUT,
      required this.apme,
      required this.squadra,
      required this.squadraUT,
      required this.squadraFX,
      required this.idsquadraUT,
      required this.idsquadraFX,
      required this.tipoutente,
      required this.modificaparametrirobot,
      required this.permessi});
  //
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //
  factory Utente.fromJson(Map<String, dynamic> json) => Utente(
        id: json["id"],
        userToken: json["user_token"],
        idsocieta: json["idsocieta"],
        nome: json["nome"],
        cognome: json["cognome"],
        username: json["username"],
        avatar: json["avatar"],
        email: json["email"],
        idsquadra: json["idsquadra"],
        abilitazione: json["abilitazione"],
        abilitazioneUT: json["abilitazioneUT"],
        apme: json["apme"],
        squadra: json["squadra"],
        squadraUT: json["squadraUT"],
        squadraFX: json["squadraFX"],
        idsquadraUT: json["idsquadraUT"],
        idsquadraFX: json["idsquadraFX"],
        tipoutente: json["tipoutente"],
        modificaparametrirobot: json["modifica_parametri_robot"],
        permessi: json["permessi"] != null
            ? List<String>.from(json["permessi"].map((x) => x))
            : [],
      );
  //
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //
  Map<String, dynamic> toJson() => {
        "id": id,
        "user_token": userToken,
        "idsocieta": idsocieta,
        "nome": nome,
        "cognome": cognome,
        "username": username,
        "avatar": avatar,
        "email": email,
        "idsquadra": idsquadra,
        "abilitazione": abilitazione,
        "abilitazioneUT": abilitazioneUT,
        "apme": apme,
        "squadra": squadra,
        "squadraUT": squadraUT,
        "squadraFX": squadraFX,
        "idsquadraUT": idsquadraUT,
        "idsquadraFX": idsquadraFX,
        "tipoutente": tipoutente,
        "modifica_parametri_robot": modificaparametrirobot,
        "permessi": List<dynamic>.from(permessi.map((x) => x)),
      };
  //
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //
}
