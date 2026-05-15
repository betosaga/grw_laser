import 'package:flutter/material.dart';
import 'package:flutter_responsive_framework/flutter_responsive_framework.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub.dart';
import 'package:grw_laser/pages/login_page/login_page.dart';
import 'package:grw_laser/services/ui_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class GrwLaserApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveUIWidget(builder: (context, orientation, screenType) {
      return MaterialApp(
          title: 'GRW Laser',
          theme: UIBuilder.sagaTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Localizations.override(
              context: context,
              locale: const Locale('it'),
              child: child!,
            );
          },
          home: LoginPage(),
          routes: <String, WidgetBuilder>{
            '/home': (BuildContext context) => LaserPageHub(),
            '/login': (BuildContext context) => LoginPage(),
            '/laser': (BuildContext context) => LaserPageHub(),
          },
          supportedLocales: const [
            Locale('it', 'IT'),
          ],
          locale: Locale('it', 'IT'),
          debugShowCheckedModeBanner: false);
    });
  }
}
