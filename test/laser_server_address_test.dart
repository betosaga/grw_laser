import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/model/laser_server_address.dart';

void main() {
  test('stored port overrides the catalog default for the same host', () {
    expect(
      LaserServerAddress.resolve(
        legacy: '192.168.10.13:8824',
        host: '192.168.10.13',
        port: 8000,
      ),
      '192.168.10.13:8824',
    );
  });
  test('a different host does not inherit a default port', () {
    expect(
      LaserServerAddress.resolve(
        legacy: '192.168.10.13:8824',
        host: '192.168.10.14',
        port: 8000,
      ),
      '192.168.10.14',
    );
  });
  test('a saved bare IP remains bare despite old host and port parameters', () {
    for (final host in ['192.168.10.13', '192.168.10.13:8824']) {
      expect(
        LaserServerAddress.resolve(
          legacy: '192.168.10.13',
          host: host,
          port: 8000,
        ),
        '192.168.10.13',
      );
    }
  });
  test('removing an explicit port does not restore the previous port', () {
    expect(
      LaserServerAddress.resolve(
        legacy: '192.168.10.13:8824',
        host: '192.168.10.13',
        port: 8000,
        hostChanged: true,
      ),
      '192.168.10.13',
    );
  });
  test('explicit standard ports and schemes are preserved', () {
    for (final address in [
      'http://example.com:80',
      'https://example.com:443',
      '[::1]:8824',
    ]) {
      expect(LaserServerAddress.resolve(legacy: address), address);
    }
  });
  test('editing host and separate port replaces the previous address', () {
    expect(
      LaserServerAddress.resolve(
        legacy: '192.168.10.13:8824',
        host: '192.168.10.13:9001',
        port: 8000,
        hostChanged: true,
      ),
      '192.168.10.13:9001',
    );
    expect(
      LaserServerAddress.resolve(
        legacy: '192.168.10.13:8824',
        host: '192.168.10.13:8824',
        port: 9002,
        portChanged: true,
      ),
      '192.168.10.13:9002',
    );
  });
}
