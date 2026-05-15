
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/configuration/urls.dart';
import 'package:grw_laser/extensions/response_success_extension.dart';
import 'package:grw_laser/model/response/response_error.dart';
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
}
