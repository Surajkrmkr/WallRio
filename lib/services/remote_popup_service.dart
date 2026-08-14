import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/ui/widgets/remote_popup_dialog.dart';

class RemotePopupService {
  static const String _keyLastShown = 'last_remote_popup_shown_time_ms';
  static bool _isShowing = false;

  /// Checks if the popup should be displayed according to the 24-hour rate limit and status flag.
  static Future<bool> shouldShowPopup(PopupConfig? config) async {
    if (config == null || !config.status) return false;
    if (config.url.isEmpty && config.description.isEmpty && config.buttonText.isEmpty) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final int lastShownMs = prefs.getInt(_keyLastShown) ?? 0;
      final int nowMs = DateTime.now().millisecondsSinceEpoch;

      // 24 hours in milliseconds (86,400,000 ms)
      const int twentyFourHoursMs = 24 * 60 * 60 * 1000;

      if (lastShownMs == 0 || (nowMs - lastShownMs) >= twentyFourHoursMs) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[RemotePopupService] Error checking cooldown: $e');
      return false;
    }
  }

  /// Updates the timestamp of when the popup was last shown.
  static Future<void> markPopupShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastShown, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[RemotePopupService] Error saving last shown timestamp: $e');
    }
  }

  /// Evaluates and shows the promotional popup dialog if eligible.
  static Future<void> checkAndShowPopup(
    BuildContext context,
    PopupConfig? config,
  ) async {
    if (_isShowing) return;
    if (config == null || !config.status) return;

    final bool canShow = await shouldShowPopup(config);
    if (!canShow) return;
    if (!context.mounted) return;

    _isShowing = true;
    await markPopupShown();

    if (!context.mounted) {
      _isShowing = false;
      return;
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        builder: (ctx) => RemotePopupDialog(config: config),
      );
    } catch (e) {
      debugPrint('[RemotePopupService] Error displaying popup dialog: $e');
    } finally {
      _isShowing = false;
    }
  }
}
