import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/services/robot/robot_discovery.dart';

import 'support/fake_robot_socket.dart';

class _Address implements InterfaceAddress {
  _Address(String ip) : value = InternetAddress(ip);
  final InternetAddress value;
  @override
  String get address => value.address;
  @override
  InternetAddressType get type => value.type;
  @override
  bool get isLoopback => value.isLoopback;
  @override
  bool get isLinkLocal => value.isLinkLocal;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Interface implements NetworkInterface {
  _Interface(this.name, this.index, List<String> ips)
    : addresses = ips.map(_Address.new).toList();
  @override
  final String name;
  @override
  final int index;
  @override
  final List<InterfaceAddress> addresses;
}

void main() {
  test('only scans the local /24 hosts, excluding tablet and broadcast', () {
    final hosts = RobotDiscovery.hostsForAddress('192.168.10.42');
    expect(hosts.length, 253);
    expect(hosts.first, '192.168.10.1');
    expect(hosts.last, '192.168.10.254');
    expect(hosts, isNot(contains('192.168.10.42')));
    expect(hosts, everyElement(startsWith('192.168.10.')));
    for (final invalid in ['::1', '127.0.0.1', 'bad', '0.0.0.0', '224.0.0.1']) {
      expect(
        () => RobotDiscovery.hostsForAddress(invalid),
        throwsA(isA<RobotDiscoveryException>()),
      );
    }
  });

  test('uses Wi-Fi or Ethernet, never cellular, VPN or peer-to-peer', () {
    final ignored = [
      _Interface('pdp_ip0', 1, ['10.1.1.1']),
      _Interface('utun0', 2, ['10.2.2.2']),
      _Interface('awdl0', 3, ['10.3.3.3']),
      _Interface('lo0', 4, ['127.0.0.1']),
    ];
    expect(RobotDiscovery.selectLocalAddress(ignored), isNull);
    expect(
      RobotDiscovery.selectLocalAddress([
        ...ignored,
        _Interface('en0', 5, ['fe80::1', '192.168.10.42']),
      ]),
      '192.168.10.42',
    );
    expect(
      RobotDiscovery.selectLocalAddress([
        _Interface('eth0', 1, ['192.168.2.9']),
        _Interface('wlan0', 2, ['192.168.3.8']),
      ]),
      '192.168.3.8',
    );
    expect(
      RobotDiscovery.selectLocalAddress([
        _Interface('en5', 5, ['192.168.4.6']),
      ]),
      '192.168.4.6',
    );
  });

  test('requires a LAN address before making any connection', () async {
    final scanner = RobotDiscovery(
      localAddressProvider: () async => null,
      connector: (_, _, _, _) async => fail('Must not connect'),
    );
    await expectLater(scanner.scan(), throwsA(isA<RobotDiscoveryException>()));
  });

  test(
    'parses fragmented RobotInfo and ignores unrelated or incomplete messages',
    () async {
      final socket = FakeRobotSocket();
      final attempted = <String>[];
      final scanner = RobotDiscovery(
        localAddressProvider: () async => '192.168.10.42',
        connector: (host, port, timeout, source) async {
          attempted.add(host);
          expect(port, 20002);
          expect(source, '192.168.10.42');
          if (host != '192.168.10.5') throw const SocketException('closed');
          socket.receive(
            '{bad}{"MSG":{"f":"Position","Serial":"wrong","Model":"wrong"}}',
          );
          socket.message({'f': 'RobotInfo', 'Serial': 'incomplete'});
          socket.receive('{"MSG":{"f":"Robot');
          socket.receive('Info","Serial":" 123 ","Model":" GRW "}}');
          return socket;
        },
      );
      final found = await scanner.scan();
      expect(attempted.toSet().length, 253);
      expect(found.single.serverSerial, '123-GRW');
      expect(found.single.ip, '192.168.10.5');
      expect(socket.destroyed, isTrue);
      expect(socket.writes, isEmpty);
    },
  );

  testWidgets(
    'waits five seconds AFTER connecting; other traffic does not extend the deadline',
    (tester) async {
      final socket = FakeRobotSocket();
      final connection = Completer<Socket>();
      final scanner = RobotDiscovery(
        localAddressProvider: () async => '192.168.10.42',
        connector: (host, _, _, _) async {
          if (host != '192.168.10.1') throw const SocketException('closed');
          return connection.future;
        },
      );
      List<DiscoveredRobot>? found;
      final scan = scanner.scan().then((result) => found = result);
      await tester.pump(const Duration(seconds: 3));
      connection.complete(socket);
      await tester.pump();
      socket.message({'f': 'Position', 'Serial': 'x', 'Model': 'y'});
      await tester.pump(const Duration(seconds: 4));
      expect(found, isNull);
      expect(socket.destroyed, isFalse);
      socket.message({'f': 'RobotInfo', 'Serial': '', 'Model': 'GRW'});
      await tester.pump(const Duration(seconds: 1));
      await scan;
      expect(found, isEmpty);
      expect(socket.destroyed, isTrue);
    },
  );

  testWidgets(
    'limits concurrent probes and cancels sockets and late connections',
    (tester) async {
      final sockets = <FakeRobotSocket>[];
      final lateConnection = Completer<Socket>();
      var calls = 0;
      final scanner = RobotDiscovery(
        concurrency: 3,
        localAddressProvider: () async => '192.168.10.42',
        connector: (_, _, _, _) async {
          calls++;
          if (calls == 3) return lateConnection.future;
          final socket = FakeRobotSocket();
          sockets.add(socket);
          return socket;
        },
      );
      final result = scanner.scan();
      await tester.pump();
      expect(calls, 3);
      scanner.cancel();
      final lateSocket = FakeRobotSocket();
      lateConnection.complete(lateSocket);
      await tester.pump();
      expect(await result, isEmpty);
      expect(calls, 3);
      expect(sockets.every((s) => s.destroyed), isTrue);
      expect(lateSocket.destroyed, isTrue);
    },
  );

  test('EOF, malformed UTF-8 and socket errors discard candidates', () async {
    final sockets = <FakeRobotSocket>[];
    final scanner = RobotDiscovery(
      localAddressProvider: () async => '192.168.10.42',
      connector: (host, _, _, _) async {
        final last = int.parse(host.split('.').last);
        if (last > 4) throw const SocketException('closed');
        final socket = FakeRobotSocket();
        sockets.add(socket);
        if (last == 1) {
          unawaited(socket.input.close());
        } else if (last == 2) {
          socket.input.addError(const SocketException('reset'));
        } else if (last == 4) {
          socket.input.add(Uint8List.fromList([0xff]));
        } else {
          socket.receive('{"MSG":{"f":"RobotInfo","Serial":{},"Model":[]}}');
          unawaited(socket.input.close());
        }
        return socket;
      },
    );
    expect(await scanner.scan(), isEmpty);
    expect(sockets.every((s) => s.destroyed), isTrue);
  });
}
