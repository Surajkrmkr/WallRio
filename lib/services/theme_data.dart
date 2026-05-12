import 'package:flutter/material.dart';

class WallRioThemeData {
  static getLightThemeData(
          {required bool isDarkTheme, required BuildContext context}) =>
      ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: isDarkTheme ? bgDarkColor : whiteColor,
          fontFamily: 'POCOTech',
          canvasColor: Colors.transparent,
          appBarTheme: AppBarTheme(
              color: isDarkTheme ? bgDarkColor : whiteColor,
              surfaceTintColor: isDarkTheme ? bgDarkColor : whiteColor),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: isDarkTheme ? bgDark2Color : whiteColor,
            indicatorColor:
                isDarkTheme ? whiteColor.withOpacity(0.19) : blackColor,
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(color: bgDarkAccentColor, fontSize: 12);
                }
                return TextStyle(
                    color: isDarkTheme ? whiteColor : blackColor, fontSize: 12);
              },
            ),
            // labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            iconTheme: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: whiteColor);
                }
                return IconThemeData(
                    color: isDarkTheme ? whiteColor : blackColor);
              },
            ),
            elevation: 0,
          ),
          switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.all(
                  isDarkTheme ? whiteColor : blackColor),
              trackColor: WidgetStateProperty.all(
                  isDarkTheme ? bgDarkAccentColor : whiteColor)),
          dialogTheme: DialogThemeData(
              backgroundColor: isDarkTheme ? bgDarkColor : whiteColor,
              surfaceTintColor: Colors.transparent),
          listTileTheme: ListTileThemeData(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20))),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: isDarkTheme ? bgDarkAccentColor : blackColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15))),
          ),
          primaryColor: isDarkTheme ? bgDarkColor : whiteColor,
          primaryColorLight: isDarkTheme ? whiteColor : blackColor,
          bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: isDarkTheme ? bgDarkColor : whiteColor,
              surfaceTintColor: Colors.transparent),
          filledButtonTheme: FilledButtonThemeData(
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                      isDarkTheme ? bgDarkAccentColor : blackColor),
                  foregroundColor: WidgetStateProperty.all(whiteColor))),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(isDarkTheme
                      ? whiteColor.withOpacity(0.1)
                      : blackColor.withOpacity(0.1)),
                  foregroundColor: WidgetStateProperty.all(
                      isDarkTheme ? whiteColor : blackColor),
                  overlayColor: WidgetStateProperty.all(isDarkTheme
                      ? blackColor.withOpacity(0.1)
                      : whiteColor.withOpacity(0.4)))),
          textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty.all(isDarkTheme ? whiteColor : blackColor),
          )),
          chipTheme: ChipThemeData(
              backgroundColor: isDarkTheme
                  ? whiteColor.withOpacity(0.05)
                  : blackColor.withOpacity(0.05),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              selectedColor: isDarkTheme ? whiteColor : blackColor,
              surfaceTintColor: isDarkTheme ? blackColor : whiteColor,
              showCheckmark: false),
          textTheme: TextTheme(
              displayLarge:
                  TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: isDarkTheme ? whiteColor : const Color(0xFF2E2E2E)),
              displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDarkTheme ? whiteColor : const Color(0xFF2E2E2E)),
              bodyLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              bodyMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          colorScheme: isDarkTheme ? const ColorScheme.dark() : const ColorScheme.light());

  static getDarkThemeData() =>
      ThemeData(brightness: Brightness.dark, useMaterial3: true);
}

const Color whiteColor = Colors.white;
const Color blackColor = Colors.black;
const Color bgDarkColor = Colors.black;
const Color bgDark2Color = Color.fromARGB(255, 23, 25, 32);
const Color bgDarkAccentColor = Color(0xFF37C3A3);

const Map<GradientAccentType, List<Color>> gradientColorMap = {
  GradientAccentType.defaultType: [Color(0xFF37C3A3), Color(0xFF37C3A3)],
  // GradientAccentType.mild: [Color(0xFF67B26F), Color(0xFF4ca2cd)],
  // GradientAccentType.sunset: [Color(0xFFee0979), Color(0xFFff6a00)],
  // GradientAccentType.radar: [
  //   Color(0xFFA770EF),
  //   Color(0xFFCF8BF3),
  //   Color(0xFFFDB99B)
  // ],
  // GradientAccentType.viceCity: [Color(0xFF3494E6), Color(0xFFEC6EAD)],
  // GradientAccentType.bradyFun: [Color(0xFF00c3ff), Color(0xFFffff1c)],
  // GradientAccentType.bloodRed: [Color(0xFFf85032), Color(0xFFe73827)],
  // GradientAccentType.sherbert: [Color(0xFFf79d00), Color(0xFF64f38c)],
  // GradientAccentType.grapeFruit: [Color(0xFFe96443), Color(0xFF64f38c)],
  // GradientAccentType.sweetMorning: [Color(0xFFff5f6d), Color(0xFFffc371)],
};

enum GradientAccentType {
  defaultType,
  // viceCity,
  // mild,
  // sunset,
  // radar,
  // bradyFun,
  // bloodRed,
  // sherbert,
  // grapeFruit,
  // sweetMorning
}

extension ColorExtensions on String {
  Color toColor() {
    if (contains("black")) {
      return Colors.black;
    } else if (contains("red")) {
      return Colors.redAccent;
    } else if (contains("orange")) {
      return Colors.orangeAccent;
    } else if (contains("blue")) {
      return Colors.blueAccent;
    } else if (contains("cyan")) {
      return Colors.cyanAccent;
    } else if (contains("indigo")) {
      return Colors.indigoAccent;
    } else if (contains("green")) {
      return Colors.greenAccent;
    } else if (contains("pink")) {
      return Colors.pinkAccent;
    } else if (contains("purple")) {
      return Colors.deepPurpleAccent;
    } else if (contains("teal")) {
      return Colors.tealAccent;
    } else if (contains("brown")) {
      return Colors.brown;
    } else if (contains("yellow")) {
      return Colors.deepOrangeAccent;
    }
    return Colors.black;
  }
}
