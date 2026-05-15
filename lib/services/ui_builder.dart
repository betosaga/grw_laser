import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/size_config.dart';

enum KeyboardType {
  fullKeyboard,
  timeKeyboard,
  numbersKeyboard,
  progressivaKeyboard,
  visitaLinea
}

class UIBuilder {
  static final fontm = 18.0;
  static final fontxxs = fontxs - 1;
  static final fontxs = fonts - 2;
  static final fonts = fontm - 2;
  static final fontl = fontm + 2;
  static final fontxl = fontl + 10;
  static final fontxxl = fontxl + 15;

  static InputDecoration deco = InputDecoration(
      counterText: "",
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(
        color: Colors.white,
        backgroundColor: Colors.white,
      ),
      errorStyle: TextStyle(height: 0),
      focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(10)),
      errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!, width: 2),
          borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!, width: 2),
          borderRadius: BorderRadius.circular(10)),
      contentPadding: EdgeInsets.all(10.0));

  static InputDecoration decolabel(String label, IconData icon) {
    return InputDecoration(
      labelStyle: TextStyle(color: Colors.black),
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: Colors.black,
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 2)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey[700]!, width: 2),
      ),
    );
  }

  static Widget campoNonEditabile(
      {required String titolo, required TextEditingController controller}) {
    return Container();
  }

  static Widget campo(context, int ncontrol, String titolo, String sottotitolo,
      TextEditingController controller, KeyboardType k) {
    return TextFormField(
      readOnly: true,
      onEditingComplete: () {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      onTap: () async {
        await UIBuilder.tastiera(context, titolo, sottotitolo, controller, k);
      },
      maxLength: 3,
      autovalidateMode: AutovalidateMode.always,
      validator: (value) {
        if (value!.length < ncontrol)
          return "";
        else
          return null;
      },
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly
      ],
      textAlign: TextAlign.end,
      controller: controller,
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(fontWeight: FontWeight.w500),
      decoration: deco.copyWith(hintText: "0"),
    );
  }

  static Widget titolo(String titolo, Color color, TextStyle h) {
    return Container(
        padding: EdgeInsets.only(left: 20, top: 5, bottom: 5, right: 5),
        width: SizeConfig.safeBlockHorizontal * 100,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              titolo,
              style: h.copyWith(color: Colors.white),
            ),
          ],
        ));
  }

  static Widget sezione(
    context,
    String titolo,
    String sottotitolo,
  ) {
    return Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Center(
                  child: Text(titolo.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall)),
              Center(
                  child: Text(sottotitolo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium))
            ]));
  }

  static Widget sezioneInfo(
    context,
    String sottotitolo,
  ) {
    return Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Center(
                  child: Text(sottotitolo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontSize: 14)))
            ]));
  }

  static Widget letterButton(
      String n, TextEditingController controller, double nvert, double noriz) {
    return AnimatedOpacity(
      // If the widget is visible, animate to 0.0 (invisible).
      // If the widget is hidden, animate to 1.0 (fully visible).
      opacity: 1.0,
      duration: Duration(milliseconds: 1500),
      // The green box must be a child of the AnimatedOpacity widget.
      child: Padding(
          padding: EdgeInsets.all(2),
          child: Material(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0)),
            //elevation: 4,
            color: Colors.transparent, // button color
            child: InkWell(
              splashColor: Colors.green, // inkwell color
              child: SizedBox(
                width: SizeConfig.safeBlockHorizontal * noriz,
                height: SizeConfig.safeBlockHorizontal * nvert,
                child: Center(
                    child: Text(n,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: UIBuilder.fontm))),
              ),
              onTap: () {
                controller.text = controller.text + n;
                // int posizione = controller.selection.base.offset;
                // controller.text = controller.text.substring(0, posizione) + n + controller.text.substring(posizione);
                //   var posizione = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              },
            ),
          )),
    );
  }

  static Future<void> tastiera(context, String titolo, String sottotitolo,
      TextEditingController controller, KeyboardType k) async {
    List<Widget> fullKeyboard() {
      List<Widget> l = [];

      l.add(
        Wrap(
          children: <Widget>[
            letterButton('!', controller, 6.7, 6.7),
            letterButton('%', controller, 6.7, 6.7),
            letterButton('-', controller, 6.7, 6.7),
            letterButton('_', controller, 6.7, 6.7),
            letterButton('+', controller, 6.7, 6.7),
            letterButton('/', controller, 6.7, 6.7),
            letterButton(':', controller, 6.7, 6.7),
            letterButton('?', controller, 6.7, 6.7),
            letterButton('\'', controller, 6.7, 6.7),
            Padding(
                padding: EdgeInsets.all(2),
                child: Material(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    elevation: 4,
                    color: Colors.green, // button color
                    child: SizedBox(
                        width: SizeConfig.safeBlockHorizontal * 6.7,
                        height: SizeConfig.safeBlockHorizontal * 6.7,
                        child: IconButton(
                          padding: EdgeInsets.all(1),
                          splashColor: Colors.green, // inkwell color
                          icon: Icon(
                            Icons.arrow_left,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (controller.text.isNotEmpty)
                              controller.text = controller.text
                                  .substring(0, controller.text.length - 1);
                          },
                        )))),
            letterButton('à', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('1', controller, 6.7, 6.7),
            letterButton('2', controller, 6.7, 6.7),
            letterButton('3', controller, 6.7, 6.7),
            letterButton('4', controller, 6.7, 6.7),
            letterButton('5', controller, 6.7, 6.7),
            letterButton('6', controller, 6.7, 6.7),
            letterButton('7', controller, 6.7, 6.7),
            letterButton('8', controller, 6.7, 6.7),
            letterButton('9', controller, 6.7, 6.7),
            letterButton('0', controller, 6.7, 6.7),
            letterButton('è', controller, 6.7, 6.7),
          ],
        ),
      );

      l.add(
        Wrap(
          children: <Widget>[
            letterButton('Q', controller, 6.7, 6.7),
            letterButton('W', controller, 6.7, 6.7),
            letterButton('E', controller, 6.7, 6.7),
            letterButton('R', controller, 6.7, 6.7),
            letterButton('T', controller, 6.7, 6.7),
            letterButton('Y', controller, 6.7, 6.7),
            letterButton('U', controller, 6.7, 6.7),
            letterButton('I', controller, 6.7, 6.7),
            letterButton('O', controller, 6.7, 6.7),
            letterButton('P', controller, 6.7, 6.7),
            letterButton('ì', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('A', controller, 6.7, 6.7),
            letterButton('S', controller, 6.7, 6.7),
            letterButton('D', controller, 6.7, 6.7),
            letterButton('F', controller, 6.7, 6.7),
            letterButton('G', controller, 6.7, 6.7),
            letterButton('H', controller, 6.7, 6.7),
            letterButton('J', controller, 6.7, 6.7),
            letterButton('K', controller, 6.7, 6.7),
            letterButton('L', controller, 6.7, 6.7),
            letterButton('@', controller, 6.7, 6.7),
            letterButton('ò', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('Z', controller, 7, 7),
            letterButton('X', controller, 7, 7),
            letterButton('C', controller, 7, 7),
            letterButton('V', controller, 7, 7),
            Padding(
                padding: EdgeInsets.all(2),
                child: Material(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    elevation: 4,
                    color: Colors.green, // button color
                    child: SizedBox(
                        width: SizeConfig.safeBlockHorizontal * 6.7,
                        height: SizeConfig.safeBlockHorizontal * 6.7,
                        child: IconButton(
                          padding: EdgeInsets.all(0),
                          splashColor: Colors.green, // inkwell color
                          icon: Icon(
                            Icons.space_bar,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            controller.text = controller.text + " ";
                          },
                        )))),
            letterButton('B', controller, 6.5, 6.5),
            letterButton('N', controller, 6.5, 6.5),
            letterButton('M', controller, 6.5, 6.5),
            letterButton(',', controller, 6.5, 6.5),
            letterButton('.', controller, 6.5, 6.5),
            letterButton('ù', controller, 6.5, 6.5),
          ],
        ),
      );

      return l;
    }

    List<Widget> timeKeyboard() {
      List<Widget> l = [];

      l.add(
        Wrap(
          children: <Widget>[
            letterButton('7', controller, 6.7, 6.7),
            letterButton('8', controller, 6.7, 6.7),
            letterButton('9', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('4', controller, 6.7, 6.7),
            letterButton('5', controller, 6.7, 6.7),
            letterButton('6', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('1', controller, 6.7, 6.7),
            letterButton('2', controller, 6.7, 6.7),
            letterButton('3', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton(':', controller, 6.7, 6.7),
            letterButton('0', controller, 6.7, 6.7),
            Padding(
                padding: EdgeInsets.all(2),
                child: Material(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    elevation: 4,
                    color: Colors.green, // button color
                    child: SizedBox(
                        width: SizeConfig.safeBlockHorizontal * 8,
                        height: SizeConfig.safeBlockHorizontal * 8,
                        child: IconButton(
                          padding: EdgeInsets.all(1),
                          splashColor: Colors.green, // inkwell color
                          icon: Icon(
                            Icons.arrow_left,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (controller.text.isNotEmpty)
                              controller.text = controller.text
                                  .substring(0, controller.text.length - 1);
                          },
                        )))),
          ],
        ),
      );

      return l;
    }

    List<Widget> progressivaKeyboard() {
      List<Widget> l = [];

      l.add(
        Wrap(
          children: <Widget>[
            letterButton('7', controller, 6.7, 6.7),
            letterButton('8', controller, 6.7, 6.7),
            letterButton('9', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('4', controller, 6.7, 6.7),
            letterButton('5', controller, 6.7, 6.7),
            letterButton('6', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('1', controller, 6.7, 6.7),
            letterButton('2', controller, 6.7, 6.7),
            letterButton('3', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('+', controller, 6.7, 6.7),
            letterButton('0', controller, 6.7, 6.7),
            Padding(
                padding: EdgeInsets.all(2),
                child: Material(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    elevation: 4,
                    color: Colors.green, // button color
                    child: SizedBox(
                        width: SizeConfig.safeBlockHorizontal * 8,
                        height: SizeConfig.safeBlockHorizontal * 8,
                        child: IconButton(
                          padding: EdgeInsets.all(1),
                          splashColor: Colors.green, // inkwell color
                          icon: Icon(
                            Icons.arrow_left,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (controller.text.isNotEmpty)
                              controller.text = controller.text
                                  .substring(0, controller.text.length - 1);
                          },
                        )))),
          ],
        ),
      );

      return l;
    }

    List<Widget> numbersKeyboard() {
      List<Widget> l = [];

      l.add(
        Wrap(
          children: <Widget>[
            letterButton('7', controller, 6.7, 6.7),
            letterButton('8', controller, 6.7, 6.7),
            letterButton('9', controller, 6.7, 6.7),
            letterButton('/', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('4', controller, 6.7, 6.7),
            letterButton('5', controller, 6.7, 6.7),
            letterButton('6', controller, 6.7, 6.7),
            letterButton('*', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('1', controller, 6.7, 6.7),
            letterButton('2', controller, 6.7, 6.7),
            letterButton('3', controller, 6.7, 6.7),
            letterButton('-', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('.', controller, 6.7, 6.7),
            letterButton('0', controller, 6.7, 6.7),
            Padding(
                padding: EdgeInsets.all(2),
                child: Material(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    elevation: 4,
                    color: Colors.green, // button color
                    child: SizedBox(
                        width: SizeConfig.safeBlockHorizontal * 8,
                        height: SizeConfig.safeBlockHorizontal * 8,
                        child: IconButton(
                          padding: EdgeInsets.all(1),
                          splashColor: Colors.green, // inkwell color
                          icon: Icon(
                            Icons.arrow_left,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (controller.text.isNotEmpty)
                              controller.text = controller.text
                                  .substring(0, controller.text.length - 1);
                          },
                        )))),
            letterButton('+', controller, 7, 7),
          ],
        ),
      );

      return l;
    }

    List<Widget> visitaLinea() {
      List<Widget> l = [];

      l.add(
        Wrap(
          children: <Widget>[
            letterButton('A', controller, 6.7, 6.7),
            letterButton('B', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('7', controller, 6.7, 6.7),
            letterButton('8', controller, 6.7, 6.7),
            letterButton('9', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('4', controller, 6.7, 6.7),
            letterButton('5', controller, 6.7, 6.7),
            letterButton('6', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('1', controller, 6.7, 6.7),
            letterButton('2', controller, 6.7, 6.7),
            letterButton('3', controller, 6.7, 6.7),
          ],
        ),
      );
      l.add(
        Wrap(
          children: <Widget>[
            letterButton('.', controller, 6.7, 6.7),
            letterButton('0', controller, 6.7, 6.7),
            Padding(
                padding: EdgeInsets.all(2),
                child: Material(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    elevation: 4,
                    color: Colors.green, // button color
                    child: SizedBox(
                        width: SizeConfig.safeBlockHorizontal * 8,
                        height: SizeConfig.safeBlockHorizontal * 8,
                        child: IconButton(
                          padding: EdgeInsets.all(1),
                          splashColor: Colors.green, // inkwell color
                          icon: Icon(
                            Icons.arrow_left,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (controller.text.isNotEmpty)
                              controller.text = controller.text
                                  .substring(0, controller.text.length - 1);
                          },
                        )))),
          ],
        ),
      );

      return l;
    }

    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }

    SystemChannels.textInput.invokeMethod('TextInput.hide');
    controller.text = "";
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => AlertDialog(
                insetPadding: EdgeInsets.all(0),
                contentPadding: EdgeInsets.all(0),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Container(
                    padding: EdgeInsets.all(0),
                    height: SizeConfig.safeBlockVertical * 40,
                    width: SizeConfig.safeBlockHorizontal * 85,
                    child: Column(children: [
                      UIBuilder.sezione(context, titolo, sottotitolo),
                      TextFormField(
                        readOnly: true,
                        textAlign: TextAlign.center,
                        controller: controller,
                      ),
                      Divider(height: 10, color: Colors.transparent),
                      Container(
                        child: Column(
                            children: k == KeyboardType.timeKeyboard
                                ? timeKeyboard()
                                : k == KeyboardType.numbersKeyboard
                                    ? numbersKeyboard()
                                    : k == KeyboardType.progressivaKeyboard
                                        ? progressivaKeyboard()
                                        : k == KeyboardType.visitaLinea
                                            ? visitaLinea()
                                            : fullKeyboard()),
                      ),
                    ])),
                actions: <Widget>[
                  InkWell(
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10.0)),
                        constraints: BoxConstraints(
                          maxWidth: SizeConfig.blockSizeHorizontal * 25,
                          minHeight: SizeConfig.blockSizeVertical * 5,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "ANNULLA",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontSize: UIBuilder.fontm),
                        ),
                      ),
                      onTap: () {
                        controller.text = "";
                        Pager.pop(context);
                      }),
                  InkWell(
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue[900],
                            borderRadius: BorderRadius.circular(10.0)),
                        constraints: BoxConstraints(
                          maxWidth: SizeConfig.blockSizeHorizontal * 25,
                          minHeight: SizeConfig.blockSizeVertical * 5,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "CONFERMA",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontSize: UIBuilder.fontm),
                        ),
                      ),
                      onTap: () => Pager.pop(context, controller.text)),
                ])).then((val) {});
  }

  static final ThemeData sagaTheme = ThemeData(
    iconTheme: IconThemeData(color: Colors.white),
    fontFamily: "Oswald",
    textTheme: TextTheme(bodyLarge: TextStyle(fontSize: 16)),
    brightness: Brightness.light,
    inputDecorationTheme: InputDecorationTheme(
      contentPadding:
          EdgeInsets.only(top: 12.0, bottom: 12.0, left: 10.0, right: 10.0),
      isCollapsed: false,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Color(AppColors.blueNormal),
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Color(AppColors.blueNormal),
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
  );
}
