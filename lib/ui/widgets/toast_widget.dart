import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/services/packages/export.dart';

class ToastWidget {
  /// Attached to MaterialApp so the iOS toast can resolve an OverlayState
  /// without threading a BuildContext through every call site.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void showToast(String msg) {
    if (Platform.isIOS || Platform.isMacOS) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        try {
          CNToast.show(
              context: context, message: msg, position: CNToastPosition.top);
          return;
        } catch (_) {}
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        } catch (_) {}
      }
      return;
    }
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
