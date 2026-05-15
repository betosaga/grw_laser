import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/configuration/urls.dart';
import 'package:grw_laser/extensions/response_success_extension.dart';
import 'package:grw_laser/model/response/response_error.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/package_info_manager.dart';
import 'package:grw_laser/services/random_string.dart';
import 'package:grw_laser/services/user_session_nest.dart';

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class Api {
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  static bool isLoading = false;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  static bool verboseUnlocked = false;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  static bool errorrequest = false;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  static Future<http.Response> request(Map<String, String> dict,
      {bool verbose = false}) async {
    dict["codice"] = RandomString.generate(10);
    dict["app_data"] =
        "${PackageInfoManager.appversion} - api ${URLs.apiversion}";

    Map<String, String> headers = {"Client-Token": Constants.CLIENT_TOKEN};

    if (UserSessionNest.isLogged) {
      headers["Authorization"] = "Token ${UserSessionNest.utente!.userToken}";
    }
    //
    //

    try {
      final response =
          await http.post(URLs.apiurl, headers: headers, body: dict);
      if (verbose || verboseUnlocked) {
        dev.log("headers: $headers");
        dev.log("parameters: $dict");
        dev.log("response.body: ${response.body}");
        dev.log("response.statusCode: ${response.statusCode}");
      }

      //
      //
      //
      if (!response.isSuccess) {
        try {
          final responseError = responseErrorFromJson(response.body);
          return Future.error(responseError);
        } catch (e) {
          return Future.error(ResponseError(code: 498, message: e.toString()));
        }
      }

      return response;
    } on SocketException catch (e) {
      return Future.error(ResponseError(code: 499, message: e.toString()));
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  static Future<http.Response?> hrequestRobot(Map<String, String> dict,
      {bool verbose = false}) async {
    http.Response? response;

    try {
      final uri = Uri.parse(URLs.apiurlrobot + "/api/eval");
      response = await http.post(uri,
          body: json.encode(dict),
          headers: {"Content-Type": "application/json"});
    } on SocketException catch (e) {
      return Future.error(ResponseError(code: 497, message: e.toString()));
    } on ResponseError catch (e) {
      return Future.error(ResponseError(code: 498, message: e.toString()));
    } catch (e) {
      return Future.error(ResponseError(code: 499, message: e.toString()));
    }
    return response;
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  static Future<http.Response?> hrequestut(BuildContext context,
      StateSetter setState, Map<String, String> dict, Uri apiurlut) async {
    setState(() {
      isLoading = true;
      errorrequest = false;
    });

    http.Response? response;
    dict.putIfAbsent("codice", () => RandomString.generate(10));
    Map<String, String> headers = {"Client-Token": Constants.CLIENT_TOKEN};
    if (UserSessionNest.isLogged) {
      headers["Authorization"] =
          "Token ${UserSessionNest.utente?.userToken ?? ""}";
    }

    try {
      response = await http.post(
        apiurlut,
        headers: headers,
        body: dict,
      );
    } on SocketException catch (e) {
      // Display an alert, no internet
      Messenger.showMessageGeneric(
          context, "Errore di connessione (" + e.toString() + ")", 2);
      setState(() {
        isLoading = false;
        errorrequest = true;
      });
    }
    if (response != null) {
      if (response.statusCode == 200) {
        if (response.body.trim().length > 3 &&
            response.body.trim().substring(0, 4) == 'ERR_') {
          Messenger.showMessageGenericError(
              context, response.body.trim().substring(4), 0);
          setState(() {
            isLoading = false;
          });
        } else if (response.body.length > 3 &&
            response.body.substring(0, 4) == 'MSG_') {
          Messenger.showMessageGeneric(
              context, response.body.trim().substring(4), 2);
          setState(() {
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }

    return response;
  }
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}
