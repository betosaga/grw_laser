import 'dart:convert';

ResponseError responseErrorFromJson(String str) => ResponseError.fromJson(json.decode(str));

String responseErrorToJson(ResponseError data) => json.encode(data.toJson());

class ResponseError {
    final int code;
    final String message;

    ResponseError({
        required this.code,
        required this.message,
    });

    factory ResponseError.fromJson(Map<String, dynamic> json) => ResponseError(
        code: json["code"],
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "code": code,
        "message": message,
    };
}
