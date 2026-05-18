import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/model/laser_points_package.dart';
import 'package:grw_laser/model/response/response_error.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserPointsHistoryPage extends StatefulWidget {
  final LaserPageController laserPageController;

  LaserPointsHistoryPage({super.key, required this.laserPageController});
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  State<LaserPointsHistoryPage> createState() => _LaserPointsHistoryPageState();
}

class _LaserPointsHistoryPageState extends State<LaserPointsHistoryPage> {
  List<LaserPointsPackage> pointsList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Listener(
            onPointerDown: (_) => Vibrator.shortVibration(),
            child: TextButton(
            child: Icon(
              Icons.arrow_back_ios_new_sharp,
              color: Colors.white,
            ),
            onPressed: () => Pager.pop(context),
          )),
          backgroundColor: AppColors.sagaBlue,
          title: Text("STORICO PUNTI", style: TextStyle(color: Colors.white)),
          actions: [
            Listener(
              onPointerDown: (_) => Vibrator.shortVibration(),
              child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: fetchHistory,
            )),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : pointsList.isEmpty
                ? Center(
                    child: Text(
                      "NESSUN SET DI PUNTI PRESENTE",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    itemCount: pointsList.length,
                    itemBuilder: (context, index) {
                      final currentPointPackage = pointsList[index];
                      return InkWell(
                        onLongPress: () {
                          Vibrator.mediumVibration();
                          caricaPuntiSelezionati(package: currentPointPackage);
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          tileColor: index % 2 == 1
                              ? Colors.white
                              : Colors.black.withAlpha(40),
                          title: Text(
                            "${currentPointPackage.label} - ${widget.dateFormat.format(currentPointPackage.datetime)}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Listener(
                                  onPointerDown: (_) => Vibrator.longVibration(),
                                  child: IconButton(
                                  onPressed: () => deletePointsAt(index: index),
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ))),
                              SizedBox(
                                width: 20,
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      );
                    }));
  }

  Future<void> caricaPuntiSelezionati(
      {required LaserPointsPackage package}) async {
    // log(jsonEncode(package));
    final confirm = await Messenger.askMessage(context, "Conferma",
        "Caricare i punti selezionati?", "CARICA", "Torna indietro");

    if (confirm ?? false) {
      await widget.laserPageController
          .loadPointsFromHistory(pointsPackage: package);
      Pager.pop(context);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.laserPageController.dashboardRedrawPoints?.call();
      });
    }
  }

  Future<void> deletePointsAt({required int index}) async {
    final confirm = await Messenger.askMessageAlert(context, "Conferma",
        "Eliminare i punti selezionati?", "Elimina", "Indietro");

    if (confirm ?? false) {
      final package = pointsList[index];
      if (package.id == null) {
        Messenger.showMessageGenericError(
            context, "Impossibile eliminare: id non presente", 2);
        return;
      }

      try {
        await widget.laserPageController
            .deletePointsFromHistory(id: package.id!);
        mySetState(() {
          pointsList.removeAt(index);
        });
        showSnackBar(textToShow: "Punti eliminati");
      } catch (e) {
        if (e is ResponseError && e.message.trim().isNotEmpty) {
          Messenger.showMessageGenericError(context, e.message, 2);
        } else {
          Messenger.showMessageGenericError(
              context, "Errore eliminazione punti", 2);
        }
      }
    }
  }

  Future<void> fetchHistory() async {
    mySetState(() {
      isLoading = true;
    });

    try {
      final fetched =
          await widget.laserPageController.getPointsHistoryFromServer();
      mySetState(() {
        pointsList = fetched;
      });
    } catch (e) {
      if (e is ResponseError && e.message.trim().isNotEmpty) {
        Messenger.showMessageGenericError(context, e.message, 2);
      } else {
        Messenger.showMessageGenericError(context, "Errore recupero punti", 2);
      }
    } finally {
      mySetState(() {
        isLoading = false;
      });
    }
  }

  void showSnackBar({required String textToShow}) {
    final snackBar = SnackBar(content: Text(textToShow));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void mySetState(VoidCallback? f) {
    if (f == null) return;
    if (mounted) {
      setState(f);
    }
  }
}
