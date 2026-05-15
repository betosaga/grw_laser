import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page_hub/laser_page_hub.dart';
import 'package:grw_laser/pages/login_page/login_page.dart';

class Pager {
  static void setFirstPageLogin({required BuildContext context}) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
      (route) => false,
    );
  }

  static void setFirstPageHome({required BuildContext context}) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => LaserPageHub(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(0, -1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
      (route) => false,
    );
  }

  static void setFirstPageHomeImmediate({required BuildContext context}) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => LaserPageHub(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
      (route) => false,
    );
  }

  static void setFirstPageNamed(
      {required BuildContext context, required String pageName}) {
    Navigator.of(context).pushNamedAndRemoveUntil(pageName, (route) {
      return false;
    });
  }

  static void setFirstPage(
      {required BuildContext context, required Widget page}) {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
      builder: (context) {
        return page;
      },
    ), (route) {
      return false;
    });
  }

  static void pushAfter(
      {required BuildContext context,
      required Widget page,
      required String afterNamed}) {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (BuildContext context) => page),
        ModalRoute.withName(afterNamed));
  }

  static void pushAfterPredicate(
      {required BuildContext context,
      required Widget page,
      required bool Function(Route<dynamic>) predicate}) {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (BuildContext context) => page), predicate);
  }

  static void pushNamedAfterFirst(
      {required BuildContext context,
      required String pageNamed,
      required Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(context, pageNamed, (route) {
      return route.isFirst;
    }, arguments: arguments);
  }

  static void pushAfterNamed(
      {required BuildContext context,
      required String pageNamed,
      required String afterNamed}) {
    Navigator.pushNamedAndRemoveUntil(
        context, pageNamed, ModalRoute.withName(afterNamed));
  }

  static Future<T?> push<T extends Object?>(
      {required BuildContext context,
      required Widget page,
      bool modal = false,
      bool popBefore = false,
      Function(BuildContext)? beforeBuild}) {
    if (popBefore) {
      pop(context);
    }
    if (beforeBuild != null) {
      beforeBuild(context);
    }
    return Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: modal,
        builder: (context) {
          return page;
        }));
  }

  static Future<T?> pushNamed<T extends Object?>(
      {required BuildContext context,
      required String page,
      bool modal = false,
      bool popBefore = false,
      Object? arguments = null}) {
    if (popBefore) {
      pop(context);
    }
    return Navigator.of(context).pushNamed(page, arguments: arguments);
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T?>(result);
  }

  static void goToFirstPage(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
