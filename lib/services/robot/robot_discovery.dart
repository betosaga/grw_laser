import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:grw_laser/configuration/constants.dart';

import 'robot_json_buffer.dart';

/// Visible in debug builds only when LASER_DEBUG is enabled.
void logRobotScan(String message) {
  if (kDebugMode && Constants.LASER_DEBUG) {
    developer.log(message, name: 'ROBOT SCAN');
  }
}

typedef DiscoveryConnector =
    Future<Socket> Function(
      String host,
      int port,
      Duration timeout,
      String localAddress,
    );

class DiscoveredRobot {
  const DiscoveredRobot({
    required this.ip,
    required this.serial,
    required this.model,
  });

  final String ip;
  final String serial;
  final String model;
  String get serverSerial => '$serial-$model';
}

class RobotDiscoveryException implements Exception {
  const RobotDiscoveryException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Passive discovery: never sends commands or uses the robot control session.
/// A discovery instance owns one scan and can be cancelled when its UI closes.
class RobotDiscovery {
  RobotDiscovery({
    Future<String?> Function()? localAddressProvider,
    DiscoveryConnector? connector,
    void Function(String)? onLog,
    this.concurrency = 32,
    this.connectTimeout = const Duration(seconds: 1),
    this.infoTimeout = const Duration(seconds: 5),
  }) : assert(concurrency > 0),
       _localAddressProvider = localAddressProvider ?? _localAddress,
       _connector = connector ?? _connect,
       _onLog = onLog ?? logRobotScan;

  final Future<String?> Function() _localAddressProvider;
  final DiscoveryConnector _connector;
  final void Function(String) _onLog;
  static int _nextScanId = 0;
  final int _scanId = ++_nextScanId;
  int _openPorts = 0;

  void _log(String message) => _onLog('[scan #$_scanId] $message');
  final int concurrency;
  final Duration connectTimeout;
  final Duration infoTimeout;
  final Set<Socket> _sockets = {};
  final Set<Completer<DiscoveredRobot?>> _pending = {};
  bool _cancelled = false;
  bool _started = false;

  bool get isCancelled => _cancelled;

  static Future<Socket> _connect(
    String host,
    int port,
    Duration timeout,
    String localAddress,
  ) =>
      Socket.connect(host, port, timeout: timeout, sourceAddress: localAddress);

  static Future<String?> _localAddress() async => selectLocalAddress(
    await NetworkInterface.list(type: InternetAddressType.IPv4),
  );

  /// Prefer Wi-Fi, then Ethernet. Never scan cellular, VPN or peer-to-peer
  /// interfaces (pdp_ip, rmnet, utun, awdl, llw, etc.).
  static String? selectLocalAddress(List<NetworkInterface> interfaces) {
    final lan = interfaces
        .where((i) => RegExp(r'^(en\d+|eth\d+|wlan\d+)$').hasMatch(i.name))
        .toList();
    int priority(NetworkInterface i) =>
        i.name == 'en0' || i.name.startsWith('wlan') ? 0 : 1;
    lan.sort((a, b) {
      final order = priority(a).compareTo(priority(b));
      return order != 0 ? order : a.index.compareTo(b.index);
    });
    for (final interface in lan) {
      for (final address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4 &&
            !address.isLoopback &&
            !address.isLinkLocal &&
            address.address != '0.0.0.0') {
          return address.address;
        }
      }
    }
    return null;
  }

  /// Deliberately bounded to x.y.z.1–254, even on a larger LAN. Network and
  /// broadcast addresses, and the tablet itself, are not robot candidates.
  static List<String> hostsForAddress(String localAddress) {
    final address = InternetAddress.tryParse(localAddress);
    if (address == null ||
        address.type != InternetAddressType.IPv4 ||
        address.isLoopback ||
        address.isLinkLocal ||
        address.rawAddress.first == 0 ||
        address.rawAddress.first >= 224) {
      throw const RobotDiscoveryException('Indirizzo IPv4 locale non valido.');
    }
    final prefix = address.address.split('.').take(3).join('.');
    return [
      for (var host = 1; host <= 254; host++)
        if ('$prefix.$host' != address.address) '$prefix.$host',
    ];
  }

  Future<List<DiscoveredRobot>> scan() async {
    if (_started) throw StateError('Scansione già avviata');
    _started = true;
    if (_cancelled) return [];
    final elapsed = Stopwatch()..start();
    _log('Ricerca indirizzo IPv4 locale...');
    final localAddress = await _localAddressProvider();
    if (_cancelled) return [];
    if (localAddress == null) {
      _log('ERRORE: nessun indirizzo LAN disponibile.');
      throw const RobotDiscoveryException(
        'Nessuna rete locale disponibile. Collega il tablet alla rete Wi-Fi o Ethernet dei robot.',
      );
    }
    final hosts = hostsForAddress(localAddress);
    _log(
      'IP tablet: $localAddress; intervallo: ${hosts.first}–${hosts.last}; '
      '${hosts.length} IP da verificare, porta 20002, concorrenza $concurrency, '
      'timeout TCP ${connectTimeout.inMilliseconds} ms, '
      'attesa RobotInfo ${infoTimeout.inMilliseconds} ms.',
    );
    final found = <DiscoveredRobot>[];
    var next = 0;
    Future<void> worker() async {
      while (!_cancelled && next < hosts.length) {
        final host = hosts[next++];
        final robot = await _probe(host, localAddress);
        if (!_cancelled && robot != null) found.add(robot);
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
    _log(
      '${_cancelled ? 'ANNULLATA' : 'COMPLETATA'} in ${elapsed.elapsedMilliseconds} ms: '
      '$next/${hosts.length} IP tentati, $_openPorts porte 20002 aperte, '
      '${found.length} robot identificati.',
    );
    if (_cancelled) return [];
    // Stable ordering also makes duplicate identities deterministic.
    found.sort(
      (a, b) => int.parse(
        a.ip.split('.').last,
      ).compareTo(int.parse(b.ip.split('.').last)),
    );
    return found;
  }

  Future<DiscoveredRobot?> _probe(String host, String localAddress) async {
    Socket? socket;
    StreamSubscription<String>? subscription;
    Timer? timer;
    final result = Completer<DiscoveredRobot?>();
    void finish([DiscoveredRobot? robot]) {
      if (!result.isCompleted) result.complete(robot);
    }

    final elapsed = Stopwatch()..start();
    _log('TENTATIVO $host:20002');
    try {
      socket = await _connector(host, 20002, connectTimeout, localAddress);
      _openPorts++;
      _log('PORTA APERTA $host:20002 (TCP ${elapsed.elapsedMilliseconds} ms).');
      // Own asynchronous output errors even though discovery sends no data.
      unawaited(
        socket.done.then<void>(
          (_) {},
          onError: (Object error) {
            if (!result.isCompleted && !_cancelled) {
              _log('ERRORE SOCKET $host:20002: $error');
            }
            finish();
          },
        ),
      );
      if (_cancelled) {
        _log('SCARTATO $host:20002: connessione completata dopo annullamento.');
        return null;
      }
      _sockets.add(socket);
      _pending.add(result);
      // Absolute deadline from TCP connection, not reset by other messages.
      _log(
        'ATTESA RobotInfo da $host:20002 (max ${infoTimeout.inMilliseconds} ms).',
      );
      timer = Timer(infoTimeout, () {
        _log(
          'TIMEOUT RobotInfo $host:20002: nessuna identità valida ricevuta, IP scartato.',
        );
        finish();
      });
      final buffer = RobotJsonBuffer();
      subscription = socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              try {
                for (final raw in buffer.add(chunk)) {
                  try {
                    final decoded = jsonDecode(raw);
                    if (decoded is! Map || decoded['MSG'] is! Map) continue;
                    final msg = decoded['MSG'] as Map;
                    if (msg['f'] != 'RobotInfo') continue;
                    final serial = _identifier(msg['Serial']);
                    final model = _identifier(msg['Model']);
                    if (serial == null || model == null) {
                      _log(
                        'RobotInfo INCOMPLETO $host:20002: Serial o Model assente/non valido; continuo ad attendere.',
                      );
                      continue;
                    }
                    _log(
                      'ROBOT TROVATO $host:20002: Serial=$serial, Model=$model, chiave=$serial-$model.',
                    );
                    finish(
                      DiscoveredRobot(ip: host, serial: serial, model: model),
                    );
                    break;
                  } on FormatException catch (error) {
                    _log(
                      'JSON NON VALIDO $host:20002: $error; continuo ad attendere.',
                    );
                    // Ignore a malformed frame; a later RobotInfo may be valid.
                  }
                }
              } on FormatException catch (error) {
                _log('FLUSSO NON VALIDO $host:20002: $error; IP scartato.');
                finish(); // Invalid UTF-8/framing or an oversized message.
              }
            },
            onError: (Object error) {
              if (!result.isCompleted && !_cancelled) {
                _log('ERRORE RICEZIONE $host:20002: $error; IP scartato.');
              }
              finish();
            },
            onDone: () {
              if (!result.isCompleted && !_cancelled) {
                _log(
                  'DISCONNESSO $host:20002 prima di RobotInfo; IP scartato.',
                );
              }
              finish();
            },
            cancelOnError: true,
          );
      return await result.future;
    } on SocketException catch (error) {
      _log(
        'TCP NON DISPONIBILE $host:20002 dopo ${elapsed.elapsedMilliseconds} ms: $error',
      );
      return null;
    } on TimeoutException catch (error) {
      _log(
        'TIMEOUT TCP $host:20002 dopo ${elapsed.elapsedMilliseconds} ms: $error',
      );
      return null;
    } finally {
      timer?.cancel();
      _pending.remove(result);
      if (socket != null) {
        _sockets.remove(socket);
        socket.destroy();
        _log('SOCKET CHIUSO $host:20002');
      }
      await subscription?.cancel();
    }
  }

  static String? _identifier(dynamic value) {
    if (value is! String && value is! num) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  void cancel() {
    if (!_cancelled && (_sockets.isNotEmpty || _pending.isNotEmpty)) {
      _log('ANNULLAMENTO: chiusura di ${_sockets.length} socket di ricerca.');
    }
    _cancelled = true;
    for (final pending in _pending) {
      if (!pending.isCompleted) pending.complete(null);
    }
    for (final socket in _sockets) {
      socket.destroy();
    }
  }
}
