import 'package:flutter/material.dart';

class Navigation extends ChangeNotifier {
  int index = 0;
  bool visible = true;

  set setIndex(int val) {
    index = val;
    notifyListeners();
  }

  set setVisible(bool val) {
    if (visible != val) {
      visible = val;
      notifyListeners();
    }
  }

  Navigation();
}
