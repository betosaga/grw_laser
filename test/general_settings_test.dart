import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/general_settings/general_settings_page.dart';
import 'package:grw_laser/services/general_settings.dart';
import 'package:grw_laser/services/user_session_nest.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('grw-general-settings-');
    Hive.init(directory.path);
  });
  setUp(() async {
    await Hive.openBox(Constants.HIVE_BOX_NAME);
    await Hive.box(Constants.HIVE_BOX_NAME).clear();
    Constants.ROBOT_SEARCH_MODE = 'FLAT';
  });
  tearDown(() async {
    await Hive.close();
    Constants.ROBOT_SEARCH_MODE = 'FLAT';
  });
  tearDownAll(() async => directory.delete(recursive: true));

  test(
    'missing and invalid stored values restore FLAT, overriding runtime defaults',
    () async {
      final box = Hive.box(Constants.HIVE_BOX_NAME);
      for (final value in [null, '', 'invalid', 'scan', true, 42]) {
        await box.put(Constants.HIVE_ROBOT_SEARCH_MODE_KEY, value);
        Constants.ROBOT_SEARCH_MODE = 'SCAN';
        GeneralSettings.restore();
        expect(GeneralSettings.robotSearchMode, 'FLAT');
        expect(Constants.ROBOT_SEARCH_MODE, 'FLAT');
      }
    },
  );

  test('each mode survives logout and closing/reopening storage', () async {
    for (final mode in ['SCAN', 'FLAT']) {
      await GeneralSettings.setRobotSearchMode(mode);
      expect(Constants.ROBOT_SEARCH_MODE, mode);
      await UserSessionNest.eraseSession();
      await Hive.close();
      Constants.ROBOT_SEARCH_MODE = 'invalid';
      await Hive.openBox(Constants.HIVE_BOX_NAME);
      GeneralSettings.restore();
      expect(Constants.ROBOT_SEARCH_MODE, mode);
    }
  });

  testWidgets(
    'selecting a mode saves it and reopening the page retains the selection',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GeneralSettingsPage()));
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        'FLAT',
      );
      for (final entry in {'Scansione': 'SCAN', 'Piatta': 'FLAT'}.entries) {
        await tester.runAsync(() async {
          await tester.tap(find.text(entry.key));
          await Hive.box(Constants.HIVE_BOX_NAME).flush();
        });
        await tester.pumpAndSettle();
        expect(Constants.ROBOT_SEARCH_MODE, entry.value);
        expect(
          Hive.box(
            Constants.HIVE_BOX_NAME,
          ).get(Constants.HIVE_ROBOT_SEARCH_MODE_KEY),
          entry.value,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(const MaterialApp(home: GeneralSettingsPage()));
        expect(
          tester
              .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
              .groupValue,
          entry.value,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed save keeps the active mode and offers retry', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GeneralSettingsPage()));
    await tester.runAsync(Hive.close);
    await tester.tap(find.text('Scansione'));
    await tester.pumpAndSettle();
    expect(Constants.ROBOT_SEARCH_MODE, 'FLAT');
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'FLAT',
    );
    expect(
      find.text('Impossibile salvare la modalità di ricerca. Riprova.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
