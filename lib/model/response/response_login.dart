// To parse this JSON data, do
//
//     final loginResponse = loginResponseFromJson(jsonString);

import 'dart:convert';

LoginResponse loginResponseFromJson(String str) => LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
    final int id;
    final String username;
    final String email;
    final String nome;
    final String cognome;
    final String cellulare;
    final String tipoutente;
    final String avatar;
    final int idsquadra;

    LoginResponse({
        required this.id,
        required this.username,
        required this.email,
        required this.nome,
        required this.cognome,
        required this.cellulare,
        required this.tipoutente,
        required this.avatar,
        required this.idsquadra,
    });

    factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        id: json["id"],
        username: json["username"] ?? "",
        email: json["email"] ?? "",
        nome: json["nome"] ?? "",
        cognome: json["cognome"] ?? "",
        cellulare: json["cellulare"] ?? "",
        tipoutente: json["tipoutente"] ?? "",
        avatar: json["avatar"] ?? "",
        idsquadra: json["idsquadra"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "nome": nome,
        "cognome": cognome,
        "cellulare": cellulare,
        "tipoutente": tipoutente,
        "avatar": avatar,
        "idsquadra": idsquadra,
    };
}
