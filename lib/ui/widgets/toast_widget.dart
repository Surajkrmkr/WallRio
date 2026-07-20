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
    if (Platform.isIOS) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      // CNToastPosition.center leaves both top/bottom null in the package's
      // Positioned.fill, which collapses it to the Stack's default
      // top-start alignment instead of actually centering (package bug) —
      // .top sets a real offset and avoids it.
      CNToast.show(
          context: context, message: msg, position: CNToastPosition.top);
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
