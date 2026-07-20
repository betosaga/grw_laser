import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/pages/laser_page/laser_settings/laser_robot_parametri_page.dart';

void main() {
  test('le sezioni numerate vengono ordinate per numero', () {
    final sections = [
      '10. Movimenti generali',
      '2. Geometria percorso',
      '1. Lavorazione',
      '28. Sicurezza avanzata',
      '9. I/O digitali',
    ]..sort(compareLaserRobotSectionLabels);

    expect(sections, [
      '1. Lavorazione',
      '2. Geometria percorso',
      '9. I/O digitali',
      '10. Movimenti generali',
      '28. Sicurezza avanzata',
    ]);
  });

  test('le sezioni senza numero restano ordinate alfabeticamente', () {
    final sections = ['Saldatura', 'Generale']
      ..sort(compareLaserRobotSectionLabels);

    expect(sections, ['Generale', 'Saldatura']);
  });

  test('la numerazione visualizzata non lascia buchi', () {
    expect(
      laserRobotSectionDisplayLabel(
        '44. Parametri avanzati consigliati',
        43,
      ),
      '43. Parametri avanzati consigliati',
    );
  });

  test('le sezioni senza numero non vengono rinominate', () {
    expect(laserRobotSectionDisplayLabel('Generale', 43), 'Generale');
  });
}
