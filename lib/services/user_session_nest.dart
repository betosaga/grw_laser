import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/utente.dart';
import 'package:grw_laser/services/hive_disk_encoder.dart';

class UserSessionNest {
  static Utente? utente;
  static bool get isLogged => utente != null;

  static void buildUtenteFromData({required String data}) {
    try {
      utente = utenteFromJson(data);
      storeSessionToDisk();
    } catch (e) {
      print("Error Parsing Utente: $e");
    }
  }

  static void setUtente({required Utente newUtente}) {
    utente = newUtente;
    storeSessionToDisk();
  }

  static void storeSessionToDisk() {
    if (isLogged) {
      final utenteJson = utenteToJson(utente!);
      final box = HiveDiskEncoder();
      box.setString(value: utenteJson, key: Constants.HIVE_USER_DATA_KEY);
    }
  }

  static void loadSessionFromDisk() {
    final box = HiveDiskEncoder();
    final utenteJson = box.stringFor(key: Constants.HIVE_USER_DATA_KEY);
    if (utenteJson != null && utenteJson.trim() != "") {
      try {
        utente = utenteFromJson(utenteJson);
      } catch (e) {
        print("Error Parsing Utente: $e");
      }
    } else {
      // utente json is null
    }
  }

  static Future<void> eraseSession() async {
    utente = null;
    final box = HiveDiskEncoder();
    await box.eraseKey(key: Constants.HIVE_USER_DATA_KEY);
  }

  static void set({required List<String> permissions}) {
    if (!isLogged) return;
    utente!.permessi = permissions;
    storeSessionToDisk();
  }

  static bool has({required String permission}) {
    bool result = false;
    if (utente != null) {
      result = utente!.permessi.contains(permission);
    }
    return result;
  }
}
