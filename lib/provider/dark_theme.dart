import 'package:flutter/material.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class DarkThemeProvider with ChangeNotifier {
  bool _darkTheme = true;

  GradientAccentType _gradType = GradientAccentType.defaultType;

  bool get darkTheme => _darkTheme;

  GradientAccentType get gradType => _gradType;

  set darkTheme(bool value) {
    _darkTheme = value;
    ThemeService().saveThemeMode(value);
    notifyListeners();
  }

  set gradType(GradientAccentType type) {
    _gradType = type;
    ThemeService().saveGradient(type);
    ToastWidget.showToast("Gradient Changed");
    notifyListeners();
  }

  DarkThemeProvider() {
    getData();
  }

  void getData() {
    _darkTheme = ThemeService.darkTheme;
    _gradType = ThemeService.gradType;
    notifyListeners();
  }
}
