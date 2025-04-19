import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';

class ThemeService {
  final darkKey = "isDarkMode";
  final gradientKey = "gradient";

  static bool darkTheme = true;
  static GradientAccentType gradType = GradientAccentType.defaultType;

  Future getData() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDarkMode = prefs.getBool(darkKey) ?? true;
    final GradientAccentType savedGradType = getGradType(prefs);
    darkTheme = isDarkMode;
    gradType = savedGradType;
  }

  void saveThemeMode(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkKey, val);
  }

  void saveGradient(GradientAccentType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(gradientKey, type.name);
  }

  GradientAccentType getGradType(prefs) {
    final val = prefs.getString(gradientKey);
    if (val == null) {
      return GradientAccentType.defaultType;
    }
    final GradientAccentType type =
        GradientAccentType.values.firstWhere((grad) => grad.name == val);
    return type;
  }
}
