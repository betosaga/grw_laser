import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_responsive_framework/flutter_responsive_framework.dart';
import 'package:grw_laser/common_components/app_logo.dart';
import 'package:grw_laser/common_components/loading_spinner.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/extensions/color_with_alpha_double.dart';
import 'package:grw_laser/model/response/response_error.dart';
import 'package:grw_laser/model/squadra.dart';
import 'package:grw_laser/services/api.dart';
import 'package:grw_laser/services/db_manager.dart';
import 'package:grw_laser/services/device_id_service.dart';
import 'package:grw_laser/services/device_info_manager.dart';
import 'package:grw_laser/services/hive_disk_encoder.dart';
import 'package:grw_laser/services/launch_url_service.dart';
import 'package:grw_laser/services/lists_store.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/tts_service.dart';
import 'package:grw_laser/services/user_session_nest.dart';
import 'package:grw_laser/services/vibrator.dart';
import 'package:grw_laser/services/size_config.dart';
import 'package:grw_laser/services/crypto.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  var controllerpassword = TextEditingController();
  var controllerusername = TextEditingController();
  Map<String, dynamic> deviceData = <String, dynamic>{};
  bool progress = false;
  bool locatorenabled = false;
  String checkGeo = "";
  bool caricando = false;
  bool click = false;
  TextStyle h = TextStyle();
  TextStyle l = TextStyle();
  String errormessage = "";
  bool aggiornamento = false;
  String aggiornamentoLink = "";
  String linkaggiornamenti = "";

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWeb => kIsWeb;

  bool isUpdateAvailable = false;

  final box = HiveDiskEncoder();

  Future<bool> login(String username, String password) async {
    bool re = false;

    mySetState(() {
      progress = true;
    });

    try {
      final response = await Api.request({
        "f": Constants.DEBUGMODE ? "doLoginFakeForTheAdmins" : "doLogin",
        "u": username.trim(),
        "p": Crypto.c(password),
        "d": await DeviceIdService.getDeviceID() ?? "",
        "pkg": DeviceInfoManager.packageName,
        "plf": Platform.isIOS ? "iOS" : "android"
      }, verbose: true);

      // salvo l'utente
      UserSessionNest.buildUtenteFromData(data: response.body);

      if (UserSessionNest.isLogged) {
        await getSquadre();
        re = true;
      }
    } catch (e) {
      if (e is ResponseError) {
        if (e.message.trim() != "")
          Messenger.showMessageGenericError(context, e.message, 2);
      }
    }

    mySetState(() {
      progress = false;
    });

    return re;
  }

  Future<void> getSquadre() async {
    try {
      final response = await Api.request({
        "f": "getSquadre",
      });
      final dati = jsonDecode(response.body);
      ListsStore.listaSquadre.clear();
      for (int i = 0; i < dati.length; i++) {
        ListsStore.listaSquadre.add(new Squadra(
          id: dati[i]['id'],
          nome: dati[i]['nome'].toString(),
          ordine: dati[i]['ordine'],
        ));
      }
    } catch (e) {
      if (e is ResponseError) {
        if (e.message.trim() != "")
          Messenger.showMessageGenericError(context, e.message, 2);
      }
    }
  }

  Future<bool> verificaAggiornamenti() async {
    bool updatesAvailable = false;
    mySetState(() {
      click = true;
    });

    try {
      //
      //
      //
      final response = await Api.request({
        "f": "getUpdates",
        "version": DeviceInfoManager.version,
        "build": DeviceInfoManager.buildNumber,
        "packagename": DeviceInfoManager.packageName,
        "platform": Platform.isIOS ? "iOS" : "android"
      }, verbose: false);
      //
      //
      //
      final dati = jsonDecode(response.body);
      //
      //
      //
      mySetState(() {
        click = false;
      });
      //
      //
      //
      if (dati['update'] == 1) {
        updatesAvailable = true;
        aggiornamento = true;
        if (dati['createdb'] == 1) {
          await ListsStore.eraseAllData();
          DBManager.newBuildNumber = int.parse(dati['build']);
        }

        mySetState(() {
          isUpdateAvailable = true;
          aggiornamentoLink =
              dati['linkandroid'] != "" ? dati['linkandroid'] : dati['linkiOS'];
          linkaggiornamenti = dati['linkaggiornamenti'] ?? "";
        });
      } else if (dati['update'] == 0) {
        if (dati['createdb'] == 1 &&
            DBManager.buildCreateDB != int.parse(dati['build'])) {
          await ListsStore.eraseAllData();
          DBManager.newBuildNumber = int.parse(dati['build']);
        }

        aggiornamento = false;
        mySetState(() {
          isUpdateAvailable = false;
        });

        // verifico presenza utente:
        UserSessionNest.loadSessionFromDisk();
        if (UserSessionNest.isLogged) {
          Pager.setFirstPageHome(context: context);
        } else {
          print("User Is Not Logged");
        }
      }

      DBManager.dbversion = dati['dbversion'];
      if (DBManager.dbversionpref == null) {
        DBManager.dbversionpref = dati['dbversion'];
      }
    } catch (e) {
      print(e.toString());

      aggiornamento = false;
      mySetState(() {
        isUpdateAvailable = false;
        click = false;
      });

      if (e is ResponseError) {
        if (e.message.trim() != "")
          Messenger.showMessageGenericError(context, e.message, 2);
      }
    }
    return updatesAvailable;
  }

  Future<void> showAggiornamentoPopup() async {
    while (true) {
      await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                "Nuova versione disponibile",
              ),
              content: Text("Clicca qui per scaricarla"),
              actions: [
                TextButton(
                    onPressed: () => LaunchUrlService.launch(linkaggiornamenti),
                    child: Text("Aggiorna"))
              ],
            );
          });
    }
  }

  @override
  void initState() {
    progress = false;
    mySetState(() {
      click = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      DBManager.dbversionpref =
          box.integerFor(key: Constants.DB_VERSION_STORED_KEY);
      DBManager.buildCreateDB =
          box.integerFor(key: Constants.BUILD_CREATE_STORED_KEY);

      final updatesAvailable = await verificaAggiornamenti();
      if (updatesAvailable) {
        showAggiornamentoPopup();
      } else {
        await TTSService.init();
        checkGeo = "CONTROLLO ABILITAZIONI IN CORSO";
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    h = Theme.of(context)
        .textTheme
        .bodyLarge!
        .copyWith(fontWeight: FontWeight.w500);
    return PopScope(
      canPop: false,
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(children: <Widget>[
            Image.asset(
              'images/BACKGROUND-SAGA-REPORTS.jpg',
              colorBlendMode: BlendMode.darken,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Column(
              children: <Widget>[
                Divider(height: 10.h, color: Colors.transparent),
                AppLogo(
                  size: 160,
                ),
                Divider(height: 7.h, color: Colors.transparent),
                Container(
                    margin: EdgeInsets.only(left: 4.h, right: 4.h),
                    decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFcfd7dd)),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withAlphaFromOpacity(alpha: 0.7)),
                    child: Column(children: <Widget>[
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 5.h),
                        child: TextField(
                          controller: controllerusername,
                          autocorrect: false,
                          autofocus: false,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w700,
                            fontFamily: "OpenSans-Regular",
                          ),
                          decoration: InputDecoration(
                              labelText: 'USERNAME',
                              labelStyle: TextStyle(
                                fontSize: FontSizeHelper.NORMAL_TEXT_MEDIUM,
                                fontWeight: FontWeight.w700,
                                fontFamily: "OpenSans-Regular",
                                letterSpacing: 2,
                                color: Colors.grey[800],
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blue[400]!, width: 2.px),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blue[400]!, width: 2.px),
                              )),
                        ),
                      ),
                      Divider(height: 2.h, color: Colors.transparent),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 5.h),
                        child: TextField(
                          controller: controllerpassword,
                          autocorrect: false,
                          autofocus: false,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w700,
                            fontFamily: "OpenSans-Regular",
                          ),
                          obscureText: true,
                          decoration: InputDecoration(
                              labelText: 'PASSWORD',
                              labelStyle: TextStyle(
                                fontSize: FontSizeHelper.NORMAL_TEXT_MEDIUM,
                                fontWeight: FontWeight.w700,
                                fontFamily: "OpenSans-Regular",
                                letterSpacing: 2,
                                color: Colors.grey[800],
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blue[400]!, width: 2.px),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blue[400]!, width: 2.px),
                              )),
                        ),
                      ),
                      Divider(height: 5.h, color: Colors.transparent),
                      click
                          ? LoadingSpinner(color: Colors.blue)
                          : isUpdateAvailable
                              ? Container()
                              : Container(
                                  height: 7.h,
                                  child: TextButton(
                                    onPressed: () async {
                                      if (!isUpdateAvailable) {
                                        if (!click) {
                                          Vibrator.shortVibration();
                                          mySetState(() {
                                            click = true;
                                          });

                                          if (controllerusername
                                                  .text.isNotEmpty &&
                                              controllerpassword
                                                  .text.isNotEmpty) {
                                            bool loginResult = await login(
                                                controllerusername.text.trim(),
                                                controllerpassword.text.trim());

                                            if (loginResult) {
                                              mySetState(() {
                                                click = false;
                                              });
                                              if (UserSessionNest.isLogged) {
                                                if (Constants.GODMODE) {
                                                  TTSService.speak(
                                                      "benvenuto signor iddio onnipotente");
                                                } else {
                                                  TTSService.speak("benvenuto " +
                                                      (Constants.DEBUGMODE
                                                          ? "Signore"
                                                          : UserSessionNest
                                                                  .utente!.nome
                                                                  .toString() +
                                                              UserSessionNest
                                                                  .utente!
                                                                  .cognome
                                                                  .toString()));
                                                }

                                                Pager.setFirstPageHome(
                                                    context: context);
                                              }
                                            } else {

                                              mySetState(() {
                                                click = false;
                                              });
                                            }
                                          } else {
                                            Messenger.showMessageGeneric(
                                                context,
                                                "Non hai inserito Username e Password",
                                                2);
                                            mySetState(() {
                                              click = false;
                                            });
                                          }
                                        }
                                      } else {
                                        Messenger.showMessageGeneric(
                                            context,
                                            "Per effettuare il login devi prima aggiornare l'app all'ultima versione cliccando in fondo alla pagina.",
                                            4);
                                        mySetState(() {
                                          click = false;
                                        });
                                      }
                                    },
                                    child: Ink(
                                      decoration: BoxDecoration(
                                          color:
                                              Color.fromARGB(255, 82, 142, 196),
                                          borderRadius:
                                              BorderRadius.circular(10.0)),
                                      child: Container(
                                          width: 250.px,
                                          alignment: Alignment.center,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Text(
                                                "Login",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: FontSizeHelper
                                                      .NORMAL_TEXT_LARGE,
                                                  fontFamily:
                                                      "OpenSans-Regular",
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 10.px),
                                                      child: Container(
                                                          height: 25.px,
                                                          width: 25.px,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    89,
                                                                    98,
                                                                    153),
                                                          ),
                                                          child: Icon(
                                                            Icons.arrow_forward,
                                                            color: Colors.white,
                                                          )))
                                                ],
                                              )
                                            ],
                                          )),
                                    ),
                                  ),
                                ),
                      if (Constants.DEBUGMODE)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Divider(height: 10, color: Colors.transparent),
                            Text(
                              "UNLOCKED",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black),
                            ),
                            Divider(height: 10, color: Colors.transparent),
                          ],
                        ),
                      Divider(height: 20, color: Colors.transparent),
                      caricando ? LoadingSpinner() : Container(),
                      SizedBox(
                        height: 20,
                      )
                    ])),
              ],
            ),
          ])),
    );
  }

  void mySetState(VoidCallback? f) {
    if (f == null) return;
    if (mounted) {
      setState(f);
    }
  }
}
