// To parse this JSON data, do
//
//     final responseSuccess = responseSuccessFromJson(jsonString);

import 'dart:convert';

ResponseSuccess responseSuccessFromJson(String str) => ResponseSuccess.fromJson(json.decode(str));

String responseSuccessToJson(ResponseSuccess data) => json.encode(data.toJson());

class ResponseSuccess {
    final String message;

    ResponseSuccess({
        required this.message,
    });

    factory ResponseSuccess.fromJson(Map<String, dynamic> json) => ResponseSuccess(
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
    };
}
