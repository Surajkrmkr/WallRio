import 'package:flutter/material.dart';

class Navigation extends ChangeNotifier {
  int index = 0;
  bool visible = true;

  // One long-lived controller per bottom tab so scroll offsets survive tab
  // switches and pushed detail pages.
  final List<ScrollController> tabControllers =
      List.generate(5, (_) => ScrollController());

  ScrollController tabController(int tab) => tabControllers[tab];

  set setIndex(int val) {
    index = val;
    visible = true;
    notifyListeners();
  }

  /// Switches to [tab]; tapping the already-active tab scrolls it to the top.
  void selectTab(int tab) {
    if (tab == index) {
      scrollToTop(tab);
      return;
    }
    setIndex = tab;
  }

  void scrollToTop(int tab) {
    final controller = tabControllers[tab];
    for (final position in controller.positions) {
      final ms = (position.pixels / 6).clamp(250, 650).toInt();
      position.animateTo(0,
          duration: Duration(milliseconds: ms), curve: Curves.easeOutCubic);
    }
  }

  set setVisible(bool val) {
    if (visible != val) {
      visible = val;
      notifyListeners();
    }
  }

  Navigation();
}
