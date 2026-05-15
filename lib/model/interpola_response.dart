import 'dart:convert';

InterpolaResponse interpolaResponseFromJson(String str) =>
    InterpolaResponse.fromJson(json.decode(str));

String interpolaResponseToJson(InterpolaResponse data) =>
    json.encode(data.toJson());

class InterpolaResponse {
  final bool ok;
  final int index;
  final String logFile;
  final String graficoFile;
  final String plotJson;
  final String metaJson;
  final String viewerUrl;
  final String script;

  InterpolaResponse({
    required this.ok,
    required this.index,
    required this.logFile,
    required this.graficoFile,
    required this.plotJson,
    required this.metaJson,
    required this.viewerUrl,
    required this.script,
  });

  factory InterpolaResponse.fromJson(Map<String, dynamic> json) =>
      InterpolaResponse(
        ok: json["ok"] as bool,
        index: json["index"] as int,
        logFile: json["log_file"] as String,
        graficoFile: json["grafico_file"] as String,
        plotJson: json["plot_json"] as String,
        metaJson: json["meta_json"] as String,
        viewerUrl: json["viewer_url"] as String,
        script: json["script"] as String,
      );

  Map<String, dynamic> toJson() => {
        "ok": ok,
        "index": index,
        "log_file": logFile,
        "grafico_file": graficoFile,
        "plot_json": plotJson,
        "meta_json": metaJson,
        "viewer_url": viewerUrl,
        "script": script,
      };
}
