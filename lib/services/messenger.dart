import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/size_config.dart';
import 'package:grw_laser/services/ui_builder.dart';

class Messenger {
  static void showSnackBar(BuildContext? context,
      {required String textToShow}) {
    if (context != null && context.mounted) {
      final snackBar = SnackBar(content: Text(textToShow));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  static void showSnackBarError(BuildContext? context,
      {required String textToShow}) {
    if (context != null && context.mounted) {
      final snackBar = SnackBar(
        content: Text(textToShow),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  static Future<bool?> askMessage(
      context, String title, String m, String atrue, String afalse) async {
    if (!context.mounted) return null;
    Widget cancelButton = TextButton(
      child: Text(afalse, style: TextStyle(color: Colors.red)),
      onPressed: () => Pager.pop(context, false),
    );
    Widget continueButton = TextButton(
      child: Text(atrue, style: TextStyle(color: Colors.black)),
      onPressed: () => Pager.pop(context, true),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(m),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<bool?> infoDialog(
      context, String title, String m, String atrue) async {
    if (!context.mounted) return null;

    Widget continueButton = TextButton(
      child: Text(atrue, style: TextStyle(color: Colors.black)),
      onPressed: () => Pager.pop(context, true),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(m),
      actions: [
        continueButton,
      ],
    );

    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<void> showRemoteNotification(
      {required BuildContext context,
      required String title,
      required String body,
      required Function(Flushbar<dynamic>)? onTap}) async {
    if (!context.mounted) return;
    final f = Flushbar(
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      reverseAnimationCurve: Curves.decelerate,
      forwardAnimationCurve: Curves.elasticOut,
      backgroundColor: AppColors.sagaBlue,
      boxShadows: [
        BoxShadow(
            color: Colors.white, offset: Offset(0.0, 2.0), blurRadius: 3.0)
      ],
      //  backgroundGradient: LinearGradient(colors: [Colors.blueAccent, Colors.white]),
      isDismissible: true,
      duration: Duration(seconds: 3),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Theme.of(context).primaryColor,
      titleText: Text(
        title,
        style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        textAlign: TextAlign.left,
      ),
      messageText: Text(body,
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );

    f.show(context);
  }

  static Future<bool?> askMessageAlert(
      context, String title, String m, String atrue, String afalse) async {
    if (!context.mounted) return null;
    Widget cancelButton = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.grey,
      ),
      child: Text(afalse, style: TextStyle(color: Colors.red)),
      onPressed: () => Pager.pop(context, false),
    );
    Widget continueButton = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        disabledForegroundColor: Colors.grey,
      ),
      child: Text(atrue),
      onPressed: () => Pager.pop(context, true),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(m),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    return await showDialog<bool?>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        ) ??
        false;
  }

  static Future<bool?> askTorchUnmountedConfirm(
      context, String title, String m, String atrue, String afalse) async {
    if (!context.mounted) return null;
    Widget cancelButton = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.grey,
      ),
      child: Text(afalse, style: TextStyle(fontSize: 20, color: Colors.red)),
      onPressed: () => Pager.pop(context, false),
    );
    Widget continueButton = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        disabledForegroundColor: Colors.grey,
      ),
      child: Text(atrue,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      onPressed: () => Pager.pop(context, true),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
      alignment: Alignment.center,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            "images/torch.jpeg",
            width: 280,
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            m,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          )
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<int?> askNumeroCordone(
      context,
      String title,
      String m,
      String atrue,
      String afalse,
      String currentCordone,
      int cordoneIniziale,
      int cordoneFinale) async {
    if (!context.mounted) return null;
    final numeroCordoneController = TextEditingController(text: currentCordone);
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text(afalse, style: TextStyle(color: Colors.red)),
      onPressed: () => Pager.pop(context, null),
    );
    Widget continueButton = TextButton(
      child: Text(atrue, style: TextStyle(color: Colors.black)),
      onPressed: () {
        int? finalValue;

        try {
          finalValue = int.parse(numeroCordoneController.text);
        } catch (e) {}

        if (finalValue != null) {
          if (finalValue >= cordoneIniziale && finalValue <= cordoneFinale) {
            Pager.pop(context, finalValue);
          } else {
            Messenger.showSnackBarError(context,
                textToShow:
                    "Valore cordone non compreso tra 0 e $cordoneFinale");
          }
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(m),
          Row(
            children: [
              SizedBox(
                width: 42,
                child: ElevatedButton(
                  onPressed: () {
                    try {
                      final currentValue =
                          int.parse(numeroCordoneController.text);
                      if (currentValue > cordoneIniziale) {
                        numeroCordoneController.text = "${currentValue - 1}";
                      } else {
                        numeroCordoneController.text = "$cordoneIniziale";
                      }
                    } catch (e) {
                      numeroCordoneController.text = "0";
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(4),
                    backgroundColor: AppColors.sagaBlue, // <-- Button color
                    foregroundColor: AppColors.sagaBlue, // <-- Splash color
                  ),
                  child: Icon(Icons.remove, color: Colors.white),
                ),
              ),
              SizedBox(
                width: 8,
              ),
              Expanded(
                child: TextField(
                  controller: numeroCordoneController,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 8,
              ),
              SizedBox(
                width: 42,
                child: ElevatedButton(
                  onPressed: () {
                    try {
                      final currentValue =
                          int.parse(numeroCordoneController.text);
                      if (currentValue < cordoneFinale) {
                        numeroCordoneController.text = "${currentValue + 1}";
                      } else {
                        numeroCordoneController.text = "$cordoneFinale";
                      }
                    } catch (e) {
                      numeroCordoneController.text = "0";
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(4),
                    backgroundColor: AppColors.sagaBlue, // <-- Button color
                    foregroundColor: AppColors.sagaBlue, // <-- Splash color
                  ),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          )
        ],
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<bool?> askMessageAlert2(
      context, String title, String m, String atrue, String afalse) async {
    if (!context.mounted) return null;
    Widget cancelButton = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        disabledForegroundColor: Colors.grey,
      ),
      child: Text(afalse),
      onPressed: () => Pager.pop(context, false),
    );
    Widget continueButton = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        disabledForegroundColor: Colors.grey,
      ),
      child: Text(atrue),
      onPressed: () => Pager.pop(context, true),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(m),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            cancelButton,
            continueButton,
          ],
        )
      ],
    );

    // show the dialog
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<bool?> askMessageTaratura(
      context, String title, String m, String atrue, String afalse) async {
    if (!context.mounted) return null;
    Widget taraturaButton = SizedBox(
        width: 100,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            disabledForegroundColor: Colors.grey,
          ),
          child:
              Text(afalse.toUpperCase(), style: TextStyle(color: Colors.white)),
          onPressed: () => Pager.pop(context, false),
        ));

    Widget esameButton = SizedBox(
        width: 100,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            disabledForegroundColor: Colors.grey,
          ),
          child: Text(atrue.toUpperCase()),
          onPressed: () => Pager.pop(context, true),
        ));

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        m,
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            taraturaButton,
            esameButton,
          ],
        )
      ],
    );
    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<bool?> showDefaultConfirm(
      context, String title, String m, String atrue, String afalse) async {
    if (!context.mounted) return null;
    Widget cancelButton = SizedBox(
        width: 100,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.grey,
          ),
          child:
              Text(afalse, style: TextStyle(color: Colors.black, fontSize: 22)),
          onPressed: () => Pager.pop(context, false),
        ));

    Widget continueButton = SizedBox(
        width: 100,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.sagaBlue,
            disabledForegroundColor: Colors.grey,
          ),
          child: Text(
            atrue,
            style: TextStyle(fontSize: 22),
          ),
          onPressed: () => Pager.pop(context, true),
        ));

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 16,
          )
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          m,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            cancelButton,
            continueButton,
          ],
        )
      ],
    );
    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<bool?> askMessageConf(
      context, String title, String m, String atrue, String afalse) async {
    if (!context.mounted) return null;
    Widget cancelButton = SizedBox(
        width: 100,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            disabledForegroundColor: Colors.grey,
          ),
          child: Text(afalse, style: TextStyle(color: Colors.white)),
          onPressed: () => Pager.pop(context, false),
        ));

    Widget continueButton = SizedBox(
        width: 100,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            disabledForegroundColor: Colors.grey,
          ),
          child: Text(atrue),
          onPressed: () => Pager.pop(context, true),
        ));

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
          ),
          Divider(height: 20, color: Colors.transparent),
          SizedBox(width: 300, child: Image.asset('images/targhetta.jpg'))
        ],
      ),
      content: Text(
        m,
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            cancelButton,
            continueButton,
          ],
        )
      ],
    );
    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<bool?> showInfo(
      context, String title, String m, bool error) async {
    if (!context.mounted) return null;
    Widget cancelButton = TextButton(
      child: Text("OK"),
      onPressed: () => Pager.pop(context, false),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: SizedBox(
          height: 250,
          child: Column(
            children: [
              error
                  ? Icon(
                      Icons.clear,
                      size: 120,
                      color: Colors.red,
                    )
                  : Icon(
                      Icons.thumb_up_rounded,
                      size: 120,
                      color: Colors.green,
                    ),
              Text(m)
            ],
          )),
      actions: [
        cancelButton,
      ],
    );

    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<bool?> showInfo2(
      context, String title, String m, double value) async {
    if (!context.mounted) return null;
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("OK"),
      onPressed: () => Pager.pop(context, false),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: SizedBox(
          height: 200,
          child: Column(
            children: [
              Divider(
                height: 20,
                color: Colors.transparent,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0%'),
                  Text('10%'),
                  Text('20%'),
                  Text('30%'),
                  Text('40%'),
                  Text('50%'),
                  Text('60%'),
                  Text('70%'),
                  Text('80%'),
                  Text('90%'),
                  Text('100%'),
                ],
              ),
              LinearProgressIndicator(
                value: value,
                minHeight: 15,
              ),
              Divider(
                height: 20,
                color: Colors.transparent,
              ),
            ],
          )),
      actions: [
        cancelButton,
      ],
    );

    // show the dialog
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static void showMessageGeneric(context, messaggio, d) {
    if (!context.mounted) return;
    final f = Flushbar(
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      reverseAnimationCurve: Curves.decelerate,
      forwardAnimationCurve: Curves.elasticOut,
      backgroundColor: Colors.white,
      boxShadows: [
        BoxShadow(color: Colors.blue, offset: Offset(0.0, 2.0), blurRadius: 3.0)
      ],
      //  backgroundGradient: LinearGradient(colors: [Color(verdemedio), Colors.white]),
      isDismissible: false,
      duration: Duration(seconds: d),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.blue,
      titleText: Text(
        "Attenzione",
        style: TextStyle(color: Colors.blueGrey, fontSize: UIBuilder.fontl),
        textAlign: TextAlign.center,
      ),
      messageText: Text(
        messaggio,
        style: TextStyle(color: Colors.blueGrey, fontSize: UIBuilder.fontl),
        textAlign: TextAlign.center,
      ),
    );
    f.show(context);
  }

  static void showMessageGenericError(context, messaggio, d) {
    if (!context.mounted) return;
    final f = Flushbar(
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      reverseAnimationCurve: Curves.decelerate,
      forwardAnimationCurve: Curves.elasticOut,
      backgroundColor: Colors.red,
      boxShadows: [
        BoxShadow(color: Colors.red, offset: Offset(0.0, 2.0), blurRadius: 3.0)
      ],
      isDismissible: false,
      mainButton: InkWell(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
            constraints: BoxConstraints(
              maxWidth: SizeConfig.blockSizeHorizontal * 25,
              minHeight: SizeConfig.blockSizeVertical * 5,
            ),
            alignment: Alignment.center,
            child: Text(
              "CHIUDI",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.red[700], fontSize: UIBuilder.fontm),
            ),
          ),
          onTap: () async {
            Pager.pop(context);
          }),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.red,
      titleText: Text(
        "Attenzione",
        style: TextStyle(color: Colors.white, fontSize: UIBuilder.fontl),
        textAlign: TextAlign.center,
      ),
      messageText: Text(
        messaggio,
        style: TextStyle(color: Colors.white, fontSize: UIBuilder.fontl),
        textAlign: TextAlign.center,
      ),
    );

    f.show(context);
  }
}
