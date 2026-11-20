import 'package:flutter/foundation.dart'
    show ValueNotifier, kDebugMode, visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:wallrio/log.dart';
import 'package:wallrio/services/purchase_analytics.dart';

/// Where a user's pass stands relative to its end.
enum PassStage {
  /// Never had a pass.
  none,

  /// A pass with more than [PassLifecycle.reminderLead] left.
  active,

  /// A pass that ends within [PassLifecycle.reminderLead].
  endingSoon,

  /// The pass has run out.
  ended,
}

/// Remembers when the user's pass ends so the app can remind them before it
/// does and welcome them back after.
///
/// Google will not sell the same pass again while it is still owned, so there
/// is nothing to buy early: the reminder says so honestly, and the offer to
/// renew appears once the pass has ended (see `LimitedOffers`).
class PassLifecycle {
  PassLifecycle._();

  static const String keyProduct = 'pass_product_id';
  static const String keyExpires = 'pass_expires_at';

  /// How long before the end the reminder starts.
  static const Duration reminderLead = Duration(days: 3);

  /// Debug builds only (compiled out of release): `--dart-define=
  /// PASS_TEST_MINUTES=3` makes every pass end 3 minutes from now, so the
  /// reminder strip and notifications can be seen on a phone whose tester
  /// account owns a pass that really lasts a year.
  static const String _testMinutes = String.fromEnvironment('PASS_TEST_MINUTES');
  static bool get _testMode => kDebugMode && _testMinutes.isNotEmpty;

  static String? _productId;
  static int? _expiresMs;
  static bool _loaded = false;

  /// Bumped whenever the remembered pass changes (loaded, recorded or
  /// cleared), so the home screen strip can update without a restart.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _productId = prefs.getString(keyProduct);
      _expiresMs = prefs.getInt(keyExpires);
    } catch (_) {
      // Treated as "never had a pass".
    }
    _loaded = true;
    changes.value++;
  }

  /// Forgets what was loaded, so tests can start from a clean slate.
  @visibleForTesting
  static void resetForTest() {
    _productId = null;
    _expiresMs = null;
    _loaded = false;
  }

  static String? get productId => _productId;

  static DateTime? get expiresAt => _expiresMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_expiresMs!);

  /// The user has bought a pass at some point.
  static bool get hadPass => _productId != null;

  /// Remembers a pass and when it ends. Only a later end replaces what is
  /// stored, so restoring an older purchase can never shorten access. Then
  /// schedules the reminders for it.
  static Future<void> record(String productId, DateTime expiresAt,
      {DateTime? now}) async {
    await load();
    if (_testMode) {
      expiresAt = (now ?? DateTime.now())
          .add(Duration(minutes: int.tryParse(_testMinutes) ?? 3));
    }
    final ms = expiresAt.millisecondsSinceEpoch;
    if (_testMode || _expiresMs == null || ms >= _expiresMs!) {
      _productId = productId;
      _expiresMs = ms;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyProduct, productId);
        await prefs.setInt(keyExpires, ms);
      } catch (_) {}
    }
    changes.value++;
    // A pass that has already run out was just noticed: report it once.
    if (!expiresAt.isAfter(now ?? DateTime.now())) {
      PurchaseAnalytics.passExpired(productId);
    }
    await syncNotifications(now: now);
  }

  /// The user is Pro some other way (lifetime or a subscription): there is
  /// nothing left to remind them about or win back.
  static Future<void> clear() async {
    await load();
    _productId = null;
    _expiresMs = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyProduct);
      await prefs.remove(keyExpires);
    } catch (_) {}
    changes.value++;
    await OfferNotifications.cancelPassNotifications();
  }

  /// Re-schedules the "ending" and "ended" notifications from what is stored.
  /// Safe to call on every app start.
  static Future<void> syncNotifications({DateTime? now}) async {
    await load();
    final expiry = expiresAt;
    final at = now ?? DateTime.now();
    if (expiry == null || !expiry.isAfter(at)) {
      await OfferNotifications.cancelPassNotifications();
      return;
    }
    await OfferNotifications.schedulePassNotifications(expiry, now: at);
  }

  // ---- Pure rules, used by the app and by tests ---------------------------

  static PassStage stageAt(DateTime? expiresAt, DateTime now) {
    if (expiresAt == null) return PassStage.none;
    if (!now.isBefore(expiresAt)) return PassStage.ended;
    return expiresAt.difference(now) <= reminderLead
        ? PassStage.endingSoon
        : PassStage.active;
  }

  /// "Your Pro ends in 2 days" / "...in 5 hours" / "...in under an hour": the
  /// time left in the unit that is honest at that point.
  static String timeLeftText(DateTime expiresAt, DateTime now) {
    final left = expiresAt.difference(now);
    if (left < const Duration(hours: 1)) return 'Your Pro ends in under an hour';
    if (left < const Duration(hours: 24)) {
      final hours = (left.inMinutes / 60).ceil();
      return 'Your Pro ends in $hours ${hours == 1 ? 'hour' : 'hours'}';
    }
    final days = daysLeftAt(expiresAt, now);
    return 'Your Pro ends in $days ${days == 1 ? 'day' : 'days'}';
  }

  /// Whole days left, rounded up: 2 days 3 hours left reads "3 days".
  static int daysLeftAt(DateTime expiresAt, DateTime now) {
    final left = expiresAt.difference(now);
    if (left <= Duration.zero) return 0;
    return (left.inMinutes / (24 * 60)).ceil();
  }
}

/// Local notifications for pass reminders and the second-chance nudge. They
/// are scheduled on the phone, so they need no server and work offline.
class OfferNotifications {
  OfferNotifications._();

  static const int _endingId = 7101;
  static const int _endedId = 7102;
  static const int _nudgeId = 7103;

  static bool _tzReady = false;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Moves a time that would wake someone up into waking hours: before 10:00
  /// becomes 10:00, after 21:00 becomes 20:00 that day.
  static DateTime comfortableTime(DateTime t) {
    if (t.hour < 10) return DateTime(t.year, t.month, t.day, 10);
    if (t.hour >= 21) return DateTime(t.year, t.month, t.day, 20);
    return t;
  }

  /// The ending reminder goes out [PassLifecycle.reminderLead] before the end.
  static DateTime endingReminderAt(DateTime expiry) =>
      comfortableTime(expiry.subtract(PassLifecycle.reminderLead));

  /// The "welcome back" notification goes out when the pass ends.
  static DateTime endedNoticeAt(DateTime expiry) => comfortableTime(expiry);

  /// The nudge goes out [LimitedOffersTiming.nudgeDelayDays] after the exit
  /// offer was shown.
  static DateTime nudgeAt(DateTime exitStartedAt) => comfortableTime(
      exitStartedAt.add(const Duration(days: LimitedOffersTiming.nudgeDelayDays)));

  static Future<void> schedulePassNotifications(DateTime expiry,
      {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final ending = endingReminderAt(expiry);
    if (ending.isAfter(at)) {
      await _schedule(
        id: _endingId,
        at: ending,
        title: 'Your WallRio Pro ends soon',
        body: 'Pro ends in ${PassLifecycle.reminderLead.inDays} days. '
            'Renew when it ends and keep your Pro wallpapers.',
      );
      PurchaseAnalytics.notificationScheduled('ending');
    } else {
      await _cancel(_endingId);
    }
    final ended = endedNoticeAt(expiry);
    if (ended.isAfter(at)) {
      await _schedule(
        id: _endedId,
        at: ended,
        title: 'Your WallRio Pro has ended',
        body: 'A welcome-back offer is waiting for you.',
      );
      PurchaseAnalytics.notificationScheduled('ended');
    } else {
      await _cancel(_endedId);
    }
  }

  static Future<void> cancelPassNotifications() async {
    await _cancel(_endingId);
    await _cancel(_endedId);
  }

  /// Schedules the second-chance notification for a user who saw the exit
  /// offer and bought nothing.
  static Future<void> scheduleNudge(DateTime exitStartedAt,
      {DateTime? now}) async {
    final at = nudgeAt(exitStartedAt);
    if (!at.isAfter(now ?? DateTime.now())) return;
    await _schedule(
      id: _nudgeId,
      at: at,
      title: 'Still thinking about Pro?',
      body: 'The Pro wallpapers you looked at are still locked. '
          'A special offer is waiting.',
    );
    PurchaseAnalytics.notificationScheduled('nudge');
  }

  static Future<void> cancelNudge() => _cancel(_nudgeId);

  static Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  static Future<void> _schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    try {
      if (!_tzReady) {
        tz_data.initializeTimeZones();
        _tzReady = true;
      }
      await _plugin.cancel(id: id);
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        // Local wall-clock time as an absolute instant, so no time-zone name
        // lookup is needed.
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pro_offers',
            'Pro reminders and offers',
            channelDescription:
                'Reminders about your Pro plan and occasional offers',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'ic_notification',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      logger.w('Offer notification scheduling failed: $e');
    }
  }
}

/// Constants shared by the notification timing and the offer rules, kept in
/// one place so the notification and the in-app nudge agree.
class LimitedOffersTiming {
  LimitedOffersTiming._();
  static const int nudgeDelayDays = 3;
}
