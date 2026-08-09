import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Returns true if the device is a tablet/iPad (shortest side >= 600dp).
  /// Phone devices (Android & iOS phones) return false.
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  /// Calculates the grid cross-axis count.
  /// On smartphones: returns [defaultPhone] (usually 3).
  /// On iPads/Tablets: returns 4, 5, or 6 based on current screen width.
  static int getGridCrossAxisCount(BuildContext context, {int defaultPhone = 3}) {
    if (!isTablet(context)) return defaultPhone;
    final width = MediaQuery.of(context).size.width;
    if (width >= 1100) return 6;
    if (width >= 850) return 5;
    return 4;
  }

  /// Maximum content width for iPad pages to keep clean layout.
  static double getMaxContentWidth(BuildContext context) {
    if (!isTablet(context)) return double.infinity;
    return 760.0;
  }

  /// Maximum sheet width for bottom sheets on iPad.
  static double getMaxSheetWidth(BuildContext context) {
    if (!isTablet(context)) return double.infinity;
    return 540.0;
  }
}
