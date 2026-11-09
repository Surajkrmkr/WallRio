import 'package:shared_preferences/shared_preferences.dart';

/// The limited-time "drop-off" offer shown once to a free user who closes the
/// paywall without buying.
///
/// The window is real: it starts the first time the offer is shown, lasts
/// [window], and is never restarted. After it ends the offer never returns.
/// While it is open the paywall also shows the discounted price, so a user who
/// reopens the paywall sees the same offer and the same countdown.
class DropoffOffer {
  DropoffOffer._();

  static const String keyStartedAt = 'dropoff_offer_started_at';
  static const Duration window = Duration(hours: 2);

  /// Milliseconds since epoch of when the window opened, or null if the offer
  /// was never shown.
  static int? _startedAt;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _startedAt = prefs.getInt(keyStartedAt);
    } catch (_) {
      _startedAt = null;
    }
    _loaded = true;
  }

  /// The offer has been shown before (open or expired).
  static bool get wasShown => _startedAt != null;

  static bool isActive({DateTime? now}) =>
      isActiveAt(_startedAt, (now ?? DateTime.now()).millisecondsSinceEpoch);

  static Duration remaining({DateTime? now}) =>
      remainingAt(_startedAt, (now ?? DateTime.now()).millisecondsSinceEpoch);

  /// Opens the window now. Does nothing if it was already opened, so the
  /// deadline can never be pushed back.
  static Future<void> start({DateTime? now}) async {
    await load();
    if (_startedAt != null) return;
    _startedAt = (now ?? DateTime.now()).millisecondsSinceEpoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyStartedAt, _startedAt!);
    } catch (_) {
      // Kept in memory for this session; worst case the window reopens once.
    }
  }

  // Pure helpers, used by tests.

  static bool isActiveAt(int? startedAtMs, int nowMs) =>
      remainingAt(startedAtMs, nowMs) > Duration.zero;

  static Duration remainingAt(int? startedAtMs, int nowMs) {
    if (startedAtMs == null) return Duration.zero;
    final left = startedAtMs + window.inMilliseconds - nowMs;
    // A clock set back before the start must not extend the window.
    if (left > window.inMilliseconds) return Duration.zero;
    return left > 0 ? Duration(milliseconds: left) : Duration.zero;
  }

  /// "23:59:41" style text for a countdown.
  static String format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    return '${two(h)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}
