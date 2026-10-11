import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:wallrio/log.dart';

/// Schedules a single evening reminder to keep the daily streak alive.
class StreakReminder {
  StreakReminder._();

  static const int _id = 7001;
  static const int _hour = 20;
  static bool _tzReady = false;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// [checkedInToday] pushes the reminder to tomorrow evening.
  static Future<void> schedule({
    required bool checkedInToday,
    required int currentStreak,
  }) async {
    try {
      if (!_tzReady) {
        tz_data.initializeTimeZones();
        _tzReady = true;
      }
      await _plugin.cancel(id: _id);

      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, _hour);
      if (checkedInToday || !at.isAfter(now)) {
        at = at.add(const Duration(days: 1));
      }

      final body = currentStreak > 0
          ? "Don't lose your $currentStreak-day streak! Check in for today's 💎"
          : "Start a streak today — save a wallpaper and check in for 💎";

      // Local wall-clock time converted to an absolute UTC instant, so no
      // device time-zone name lookup is needed.
      await _plugin.zonedSchedule(
        id: _id,
        title: '🔥 Keep your streak going',
        body: body,
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminder',
            'Streak reminders',
            channelDescription: 'Daily reminder to keep your check-in streak',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'ic_notification',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      logger.w('Streak reminder scheduling failed: $e');
    }
  }

  static Future<void> cancel() async {
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
