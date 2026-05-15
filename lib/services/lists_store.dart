import 'dart:convert';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/model/attrezzatura_ut.dart';
import 'package:grw_laser/model/dtp.dart';
import 'package:grw_laser/model/linea.dart';
import 'package:grw_laser/model/operatore.dart';
import 'package:grw_laser/model/produttore.dart';
import 'package:grw_laser/model/squadra.dart';
import 'package:grw_laser/model/stazione.dart';
import 'package:grw_laser/model/tipo_filo.dart';
import 'package:grw_laser/model/tipo_saldatura_ut.dart';
import 'package:grw_laser/model/tipo_scambio.dart';
import 'package:grw_laser/model/tipo_scambio_vl.dart';
import 'package:grw_laser/model/umlv.dart';
import 'package:grw_laser/services/hive_disk_encoder.dart';

class ListsStore {
  static final box = HiveDiskEncoder();
  static List<Stazione> listaStazioni = [];
  static List<Stazione> listaStazionifilter = [];
  static List<Linea> listaLinea = [];
  static List<Linea> listaLineafilter = [];
  static List<DTP> listaDTP = [];
  static List<TipoScambio> listaTipoScambio = [];
  static List<TipoScambioVL> listaTipoScambioVL = [];
  static List<String> listaDifetti = [];
  static List<Produttore> listaProduttore = [];
  static List<Produttore> listaProduttoreUT = [];
  static List<Operatore> listaOperatori = [];
  static List<int> listaIDOperatori = [];
  static List<Squadra> listaSquadreUT = [];
  static List<TipoFilo> listaTipoFilo = [];
  static List<TipoSaldaturaUT> listaTipoSaldaturaUT = [];
  static List<AttrezzaturaUT> listaAttrezzaturaUT = [];
  static List<String> listaDestinariUT = [];
  static List<Squadra> listaSquadre = [];
  static List<String> listaMotivazioni = [];
  static List<UMLV> listaUMLV = [];
  static List<UMLV> listaUMLVfiltrata = [];

  static bool loaded = false;

  static final keysToBeChecked = [
    "stazioni",
    "linee",
    "dtp",
    "tipo_scambio",
    "tipo_scambio_vl",
    "difetti",
    "produttori",
    "produttori_ut",
    "operatori",
    "squadre_ut",
    "squadre",
    "tipo_filo",
    "tipo_saldatura",
    "attrezzatura_ut",
    "destinatari_ut",
    "umlv",
  ];

  static bool checkStorePresence() {
    final data = box.stringFor(key: Constants.STORED_APP_DATA_KEY);
    return data != null;
  }

  static Future<void> eraseAllData() async {
    await box.eraseKey(key: Constants.STORED_APP_DATA_KEY);
    listaStazioni = [];
    listaStazionifilter = [];
    listaLinea = [];
    listaLineafilter = [];
    listaDTP = [];
    listaTipoScambio = [];
    listaTipoScambioVL = [];
    listaDifetti = [];
    listaProduttore = [];
    listaProduttoreUT = [];
    listaOperatori = [];
    listaIDOperatori = [];
    listaSquadreUT = [];
    listaTipoFilo = [];
    listaTipoSaldaturaUT = [];
    listaAttrezzaturaUT = [];
    listaDestinariUT = [];
    listaSquadre = [];
    listaMotivazioni = [];
    listaUMLV = [];
    listaUMLVfiltrata = [];
    loaded = false;
  }

  static void decodeAndStore({required String data}) {
    //
    //
    //
    try {
      final dataDecoded = jsonDecode(data);

      bool testPassed = true;
      for (int i = 0; i < keysToBeChecked.length; i++) {
        if (dataDecoded[keysToBeChecked[i]] == null) {
          print("INDICE '" + keysToBeChecked[i] + "' MANCANTE");
          testPassed = false;
          break;
        }
      }
      //
      //
      //

      // print("TEST SUPERATO: $testPassed");

      //
      //
      //
      if (testPassed) {
        // print("SALVO CONTENUTO SU DISCO");
        _storeData(dataToStore: data);
      }

      // importo i dati
      parseAndLoadData(dataDecoded: dataDecoded);
    } catch (e) {
      print(e);
    }
    //
    //
    //
  }

  static void _storeData({required String dataToStore}) {
    box.setString(value: dataToStore, key: Constants.STORED_APP_DATA_KEY);
  }

  static void elaborate(
      {required String dataKey,
      required dynamic dataPackage,
      bool store = false}) {
    try {
      switch (dataKey) {
        case "stazioni":
          listaStazioni.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaStazioni.add(Stazione(
                  id: dataPackage[i]['id'],
                  stazione: dataPackage[i]['stazione'],
                  comunelocalita: dataPackage[i]['comune_localita'],
                  provincia: dataPackage[i]['provincia'],
                  network: dataPackage[i]['network']));
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "linee":
          listaLinea.clear();

          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaLinea.add(Linea(
                  id: dataPackage[i]['id'],
                  linea: dataPackage[i]['linea'] ?? ""));
            } catch (e) {
              print(e.toString());
            }
          }

          break;
        case "dtp":
          listaDTP.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaDTP.add(
                  DTP(id: dataPackage[i]['id'], dtp: dataPackage[i]['dtp']));
            } catch (e) {
              print(e.toString());
            }
          }

          break;
        case "tipo_scambio":
          listaTipoScambio.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              // print(jsonEncode(dataPackage));
              listaTipoScambio.add(TipoScambio(
                  id: dataPackage[i]['id'],
                  tipoScambio: dataPackage[i]['tiposcambio'].toString(),
                  categoriaScambio:
                      dataPackage[i]['categoriascambio'].toString(),
                  disegno: dataPackage[i]['disegno'].toString()));
            } catch (e) {
              print(e.toString());
              print(jsonEncode(dataPackage[i]));
            }
          }
          break;
        case "tipo_scambio_vl":
          listaTipoScambioVL.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaTipoScambioVL.add(TipoScambioVL(
                  tipoScambio: dataPackage[i]['tiposcambio'].toString(),
                  tipoScambiovisitalinea:
                      dataPackage[i]['tiposcambiovisitalinea'].toString(),
                  disegno: dataPackage[i]['disegno'].toString()));
            } catch (e) {
              print(e.toString());
            }
          }

          break;
        case "difetti":
          listaDifetti.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaDifetti.add(dataPackage[i]['difetto'].toString());
            } catch (e) {
              print(e.toString());
              print(jsonEncode(dataPackage[i]));
            }
          }

          break;
        case "produttori":
          listaProduttore.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaProduttore.add(Produttore(
                  costruttore: dataPackage[i]['costruttore'].toString(),
                  ut: dataPackage[i]['ut'] is int
                      ? dataPackage[i]['ut']
                      : int.parse(dataPackage[i]['ut'])));
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "produttori_ut":
          listaProduttoreUT.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaProduttoreUT.add(Produttore(
                  costruttore: dataPackage[i]['costruttore'].toString(),
                  ut: dataPackage[i]['ut'] is int
                      ? dataPackage[i]['ut']
                      : int.parse(dataPackage[i]['ut'])));
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "operatori":
          listaOperatori.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaOperatori.add(Operatore(
                  id: dataPackage[i]['id'] is int
                      ? dataPackage[i]['id']
                      : int.parse(dataPackage[i]['id']),
                  nome: dataPackage[i]['nome'].toString(),
                  cognome: dataPackage[i]['cognome'].toString(),
                  abilitazione: dataPackage[i]['abilitazione'].toString(),
                  apme: dataPackage[i]['apme'].toString(),
                  abilitazioneut: dataPackage[i]['abilitazioneut'].toString()));
            } catch (e) {
              print(e.toString());
            }
          }

          break;
        case "squadre_ut":
          listaSquadreUT.clear();

          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaSquadreUT.add(Squadra(
                  id: int.parse(dataPackage[i]['id'].toString()),
                  nome: dataPackage[i]['nome'].toString(),
                  ordine: 0));
            } catch (e) {
              print(e.toString());
            }
          }

          break;
        case "squadre":
          listaSquadre.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaSquadre.add(Squadra(
                  id: int.parse(dataPackage[i]['id'].toString()),
                  nome: dataPackage[i]['nome'].toString(),
                  ordine: dataPackage[i]['ordine']));
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "tipo_filo":
          listaTipoFilo.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaTipoFilo.add(TipoFilo(
                  id: dataPackage[i]['id'] is int
                      ? dataPackage[i]['id']
                      : int.parse(dataPackage[i]['id']),
                  tipofilo: dataPackage[i]['tipofilo'].toString(),
                  abbreviazione: dataPackage[i]['abbreviazione'],
                  wps: dataPackage[i]['wps']));
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "tipo_saldatura":
          listaTipoSaldaturaUT.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaTipoSaldaturaUT.add(TipoSaldaturaUT(
                  id: dataPackage[i]['id'] is int
                      ? dataPackage[i]['id']
                      : int.parse(dataPackage[i]['id']),
                  tiposaldatura: dataPackage[i]['tiposaldatura'],
                  abbreviazione: dataPackage[i]['abbreviazione']));
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "attrezzatura_ut":
          listaAttrezzaturaUT.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaAttrezzaturaUT.add(AttrezzaturaUT(
                  id: dataPackage[i]['id'] is int
                      ? dataPackage[i]['id']
                      : int.parse(dataPackage[i]['id']),
                  modello: dataPackage[i]['modello'].toString(),
                  seriale: dataPackage[i]['seriale'].toString(),
                  omologazionerfi:
                      dataPackage[i]['omologazionerfi'].toString()));
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "destinatari_ut":
          listaDestinariUT.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaDestinariUT.add(dataPackage[i].toString());
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "motivazioni":
          listaMotivazioni.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaMotivazioni.add(dataPackage[i]);
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case "umlv":
          listaUMLV.clear();
          for (int i = 0; i < dataPackage.length; i++) {
            try {
              listaUMLV.add(UMLV(
                  id: dataPackage[i]['id'] is int
                      ? dataPackage[i]['id']
                      : int.parse(dataPackage[i]['id']),
                  iddtp: int.parse(dataPackage[i]['iddtp'].toString()),
                  umlv: dataPackage[i]['umlv'],
                  riferimento: dataPackage[i]['riferimento']));
            } catch (e) {
              print(e.toString());
            }
          }
          break;
      }

      if (store) {
        storeData();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  static void parseAndLoadData({required Map<String, dynamic> dataDecoded}) {
    final bool printing = false;
    try {
      // STAZIONI
      if (printing) print("parsing STAZIONI");
      final stazioni = dataDecoded["stazioni"];
      elaborate(dataKey: "stazioni", dataPackage: stazioni);
      // LINEE
      if (printing) print("parsing LINEE");
      final linee = dataDecoded["linee"];
      elaborate(dataKey: "linee", dataPackage: linee);
      // DTP
      if (printing) print("parsing DTP");
      final dtp = dataDecoded["dtp"];
      elaborate(dataKey: "dtp", dataPackage: dtp);
      // TIPO SCAMBIO
      if (printing) print("parsing TIPO SCAMBIO");
      final tipoScambio = dataDecoded["tipo_scambio"];
      elaborate(dataKey: "tipo_scambio", dataPackage: tipoScambio);
      // TIPO SCAMBIO VL
      if (printing) print("parsing TIPO SCAMBIO VL");
      final tipoScambioVL = dataDecoded["tipo_scambio_vl"];
      elaborate(dataKey: "tipo_scambio_vl", dataPackage: tipoScambioVL);
      // DIFETTI
      if (printing) print("parsing DIFETTI");
      final difetti = dataDecoded["difetti"];
      elaborate(dataKey: "difetti", dataPackage: difetti);
      // PRODUTTORI
      if (printing) print("parsing PRODUTTORI");
      final produttori = dataDecoded['produttori'];
      elaborate(dataKey: "produttori", dataPackage: produttori);
      // PRODUTTORI UT
      if (printing) print("parsing PRODUTTORI UT");
      final produttori_ut = dataDecoded['produttori_ut'];
      elaborate(dataKey: "produttori_ut", dataPackage: produttori_ut);
      // OPERATORI
      if (printing) print("parsing OPERATORI");
      final operatori = dataDecoded['operatori'];
      elaborate(dataKey: "operatori", dataPackage: operatori);
      // SQUADRE UT
      if (printing) print("parsing SQUADRE UT");
      final squadreUT = dataDecoded['squadre_ut'];
      elaborate(dataKey: "squadre_ut", dataPackage: squadreUT);
      // SQUADRE
      if (printing) print("parsing SQUADRE");
      final squadre = dataDecoded['squadre'];
      elaborate(dataKey: "squadre", dataPackage: squadre);
      // TIPO FILO
      if (printing) print("parsing TIPO FILO");
      final tipoFilo = dataDecoded["tipo_filo"];
      elaborate(dataKey: "tipo_filo", dataPackage: tipoFilo);
      // TIPO SALDATURA
      if (printing) print("parsing TIPO SALDATURA");
      final tipoSaldatura = dataDecoded["tipo_saldatura"];
      elaborate(dataKey: "tipo_saldatura", dataPackage: tipoSaldatura);
      // ATTREZZATURA UT
      if (printing) print("parsing ATTREZZATURA UT");
      final attrezzaturaUT = dataDecoded["attrezzatura_ut"];
      elaborate(dataKey: "attrezzatura_ut", dataPackage: attrezzaturaUT);
      // DESTINATARI UT
      if (printing) print("parsing DESTINATARI UT");
      final destinatariUT = dataDecoded["destinatari_ut"];
      elaborate(dataKey: "destinatari_ut", dataPackage: destinatariUT);
      // MOTIVAZIONI
      if (printing) print("parsing MOTIVAZIONI");
      final motivazioni = dataDecoded["motivazioni"];
      elaborate(dataKey: "motivazioni", dataPackage: motivazioni);
      // UMLV
      if (printing) print("parsing UMLV");
      final umlv = dataDecoded["umlv"];
      elaborate(dataKey: "umlv", dataPackage: umlv);
    } catch (e) {
      print(e.toString());
    }
  }

  static void loadFromDisk() {
    //
    //
    print("LOAD FROM DISK");
    //
    //

    final data = box.stringFor(key: Constants.STORED_APP_DATA_KEY);
    if (data != null) {
      //
      //
      print("LIST STORE is present");
      // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      try {
        final dataDecoded = jsonDecode(data);
        parseAndLoadData(dataDecoded: dataDecoded);
      } catch (e) {
        print(e.toString());
      }
      // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      //
      //
    } else {
      print("LIST STORE data is null");
    }
  }

  static void storeData() {
    Map<String, dynamic> dataToStore = {};
    //
    //
    //
    List<Map<String, dynamic>> listaStazioniEncoding = [];
    listaStazioni.forEach((stazione) {
      listaStazioniEncoding.add({
        "id": stazione.id,
        "stazione": stazione.stazione,
        "comune_localita": stazione.comunelocalita,
        "provincia": stazione.provincia,
        "network": stazione.network
      });
    });
    dataToStore["stazioni"] = listaStazioniEncoding;
    // LINEE
    List<Map<String, dynamic>> listaLineeEncoding = [];
    listaLinea.forEach((linea) {
      listaLineeEncoding.add({
        "id": linea.id,
        "stazione": linea.linea,
      });
    });
    dataToStore["linee"] = listaLineeEncoding;
    // DTP
    List<Map<String, dynamic>> listaDTPEncoding = [];
    listaDTP.forEach((dtp) {
      listaDTPEncoding.add({
        "id": dtp.id,
        "dtp": dtp.dtp,
      });
    });
    dataToStore["dtp"] = listaDTPEncoding;
    // TIPO SCAMBIO
    List<Map<String, dynamic>> listaTipoScambioEncoding = [];
    listaTipoScambio.forEach((tipoScambio) {
      listaTipoScambioEncoding.add({
        "id": tipoScambio.id,
        "tiposcambio": tipoScambio.tipoScambio,
        "categoriascambio": tipoScambio.categoriaScambio,
        "disegno": tipoScambio.disegno
      });
    });
    dataToStore["tipo_scambio"] = listaTipoScambioEncoding;
    // TIPO SCAMBIO
    List<Map<String, dynamic>> listaTipoScambioVLEncoding = [];
    listaTipoScambioVL.forEach((tipoScambioVL) {
      listaTipoScambioEncoding.add({
        "tiposcambio": tipoScambioVL.tipoScambio,
        "tiposcambiovisitalinea": tipoScambioVL.tipoScambiovisitalinea,
        "disegno": tipoScambioVL.disegno
      });
    });
    dataToStore["tipo_scambio_vl"] = listaTipoScambioVLEncoding;
    // DIFETTI
    List<String> difettiEncoding = [];
    listaDifetti.forEach((difetto) {
      difettiEncoding.add(difetto);
    });
    dataToStore["difetti"] = difettiEncoding;
    // PRODUTTORI
    List<Map<String, dynamic>> listaProduttoriEncoding = [];
    listaProduttore.forEach((produttore) {
      listaProduttoriEncoding
          .add({"costruttore": produttore.costruttore, "ut": produttore.ut});
    });
    dataToStore["produttori"] = listaProduttoriEncoding;
    // PRODUTTORI UT
    List<Map<String, dynamic>> listaProduttoriUTEncoding = [];
    listaProduttoreUT.forEach((produttore) {
      listaProduttoriUTEncoding
          .add({"costruttore": produttore.costruttore, "ut": produttore.ut});
    });
    dataToStore["produttori_ut"] = listaProduttoriUTEncoding;
    // OPERATORI
    List<Map<String, dynamic>> listaOperatoriUTEncoding = [];
    listaOperatori.forEach((operatore) {
      listaOperatoriUTEncoding.add({
        "id": operatore.id,
        "nome": operatore.nome,
        "cognome": operatore.cognome,
        "abilitazione": operatore.abilitazione,
        "apme": operatore.apme,
        "abilitazioneut": operatore.abilitazioneut
      });
    });
    dataToStore["operatori"] = listaOperatoriUTEncoding;
    // SQUADRE UT
    List<Map<String, dynamic>> listaSquadreUTEncoding = [];
    listaSquadreUT.forEach((squadraUT) {
      listaSquadreUTEncoding.add({"id": squadraUT.id, "nome": squadraUT.nome});
    });
    dataToStore["squadre_ut"] = listaSquadreUTEncoding;
    // SQUADRE
    List<Map<String, dynamic>> listaSquadreEncoding = [];
    listaSquadre.forEach((squadra) {
      listaSquadreEncoding.add(
          {"id": squadra.id, "nome": squadra.nome, "ordine": squadra.ordine});
    });
    dataToStore["squadre"] = listaSquadreEncoding;
    // TIPO FILO
    List<Map<String, dynamic>> listaTipoFiloEncoding = [];
    listaTipoFilo.forEach((tipoFilo) {
      listaTipoFiloEncoding.add({
        "id": tipoFilo.id,
        "tipofilo": tipoFilo.tipofilo,
        "abbreviazione": tipoFilo.abbreviazione,
        "wps": tipoFilo.wps
      });
    });
    dataToStore["tipo_filo"] = listaTipoFiloEncoding;
    // TIPO SALDATURA
    List<Map<String, dynamic>> tipoSaldaturaEncoding = [];
    listaTipoSaldaturaUT.forEach((tipoSaldatura) {
      tipoSaldaturaEncoding.add({
        "id": tipoSaldatura.id,
        "tiposaldatura": tipoSaldatura.tiposaldatura,
        "abbreviazione": tipoSaldatura.abbreviazione
      });
    });
    dataToStore["tipo_saldatura"] = tipoSaldaturaEncoding;
    // ATTREZZATURA UT
    List<Map<String, dynamic>> attrezzaturaUTEncoding = [];
    listaAttrezzaturaUT.forEach((attrezzatura) {
      attrezzaturaUTEncoding.add({
        "id": attrezzatura.id,
        "modello": attrezzatura.modello,
        "seriale": attrezzatura.seriale,
        "omologazionerfi": attrezzatura.omologazionerfi
      });
    });
    dataToStore["attrezzatura_ut"] = attrezzaturaUTEncoding;
    // DESTINATARI UT
    List<String> destinatariUTEncoding = [];
    listaDestinariUT.forEach((destinatario) {
      destinatariUTEncoding.add(destinatario);
    });
    dataToStore["destinatari_ut"] = destinatariUTEncoding;
    // MOTIVAZIONI
    List<String> motivazioniEncoding = [];
    listaMotivazioni.forEach((motivazione) {
      motivazioniEncoding.add(motivazione);
    });
    dataToStore["motivazioni"] = motivazioniEncoding;
    // UMLV
    List<Map<String, dynamic>> umlvEncoding = [];
    listaUMLV.forEach((umlv) {
      umlvEncoding.add({
        "id": umlv.id,
        "iddtp": umlv.iddtp,
        "umlv": umlv.umlv,
        "riferimento": umlv.riferimento
      });
    });
    dataToStore["umlv"] = umlvEncoding;

    try {
      final dataEncoded = jsonEncode(dataToStore);
      _storeData(dataToStore: dataEncoded);
    } catch (e) {
      print(e.toString());
    }
  }

  static void printListLengths() {
    print("listaStazioni ${listaStazioni.length}");
    print("listaStazionifilter ${listaStazionifilter.length}");
    print("listaLinea ${listaLinea.length}");
    print("listaLineafilter ${listaLineafilter.length}");
    print("listaDTP ${listaDTP.length}");
    print("listaTipoScambio ${listaTipoScambio.length}");
    print("listaTipoScambioVL ${listaTipoScambioVL.length}");
    print("listaDifetti ${listaDifetti.length}");
    print("listaProduttore ${listaProduttore.length}");
    print("listaProduttoreUT ${listaProduttoreUT.length}");
    print("listaOperatori ${listaOperatori.length}");
    print("listaIDOperatori ${listaIDOperatori.length}");
    print("listaSquadreUT ${listaSquadreUT.length}");
    print("listaTipoFilo ${listaTipoFilo.length}");
    print("listaTipoSaldaturaUT ${listaTipoSaldaturaUT.length}");
    print("listaAttrezzaturaUT ${listaAttrezzaturaUT.length}");
    print("listaDestinariUT ${listaDestinariUT.length}");
    print("listaSquadre ${listaSquadre.length}");
    print("listaMotivazioni ${listaMotivazioni.length}");
    print("listaUMLV ${listaUMLV.length}");
    print("listaUMLVfiltrata ${listaUMLVfiltrata.length}");
  }
}
