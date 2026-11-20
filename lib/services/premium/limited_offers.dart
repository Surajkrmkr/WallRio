import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallrio/services/dropoff_offer.dart';
import 'package:wallrio/services/premium/pass_access.dart';
import 'package:wallrio/services/premium/pass_lifecycle.dart';

/// The limited-time offers the app can run. Each opens a real window the first
/// time it is shown, lasts a fixed time and is never restarted.
///
/// * [exit]: shown once when a free user closes the paywall (2 hours, 40% off
///   the 1-year plan).
/// * [comeback]: shown once after a pass has ended (48 hours, the same 40% off
///   the 1-year plan, for a returning customer).
/// * [nudge]: shown once, days after the exit offer went unclaimed (24 hours,
///   about a third off the 4-month plan: a different deal, not a repeat).
enum LimitedOfferKind { exit, comeback, nudge }

extension LimitedOfferKindInfo on LimitedOfferKind {
  /// Name used in analytics (`offer_kind`).
  String get analyticsName => name;

  Duration get window {
    switch (this) {
      case LimitedOfferKind.exit:
        return DropoffOffer.window;
      case LimitedOfferKind.comeback:
        return const Duration(hours: 48);
      case LimitedOfferKind.nudge:
        return const Duration(hours: 24);
    }
  }

  /// The discounted twin this offer sells.
  String get offerProductId => this == LimitedOfferKind.nudge
      ? PassAccess.quarterlyNudgeId
      : PassAccess.yearlyDropoffId;

  /// The regular pass the twin undercuts (hidden while the offer is open).
  String get regularProductId => this == LimitedOfferKind.nudge
      ? PassAccess.quarterlyId
      : PassAccess.yearlyId;
}

class LimitedOffers {
  LimitedOffers._();

  static const String keyComebackStartedAt = 'offer_comeback_started_at';
  static const String keyComebackForExpiry = 'offer_comeback_for_expiry';
  static const String keyNudgeStartedAt = 'offer_nudge_started_at';

  /// Minimum gap between two offers shown without the user asking for them.
  static const Duration cooldown = Duration(hours: 24);

  /// The nudge waits this long after the exit offer was shown...
  static const Duration nudgeDelay =
      Duration(days: LimitedOffersTiming.nudgeDelayDays);

  /// ...and is dropped if the user comes back later than this.
  static const Duration nudgeGiveUp = Duration(days: 30);

  /// A pass that ended longer ago than this no longer earns a comeback offer.
  static const Duration comebackGiveUp = Duration(days: 30);

  static int? _comebackStartedAt;
  static int? _comebackForExpiry;
  static int? _nudgeStartedAt;
  static bool _loaded = false;

  static Future<void> load() async {
    await DropoffOffer.load();
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _comebackStartedAt = prefs.getInt(keyComebackStartedAt);
      _comebackForExpiry = prefs.getInt(keyComebackForExpiry);
      _nudgeStartedAt = prefs.getInt(keyNudgeStartedAt);
    } catch (_) {
      // Missing prefs behave like "never shown".
    }
    _loaded = true;
  }

  /// When [kind]'s window opened, or null if it never has.
  static DateTime? startedAt(LimitedOfferKind kind) {
    final ms = _startedMs(kind);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static int? _startedMs(LimitedOfferKind kind) {
    switch (kind) {
      case LimitedOfferKind.exit:
        return DropoffOffer.startedAtMs;
      case LimitedOfferKind.comeback:
        return _comebackStartedAt;
      case LimitedOfferKind.nudge:
        return _nudgeStartedAt;
    }
  }

  /// The offer was shown before (open or over).
  static bool wasShown(LimitedOfferKind kind) => _startedMs(kind) != null;

  static bool isActive(LimitedOfferKind kind, {DateTime? now}) =>
      remaining(kind, now: now) > Duration.zero;

  static Duration remaining(LimitedOfferKind kind, {DateTime? now}) =>
      remainingAt(
          _startedMs(kind),
          kind.window,
          (now ?? DateTime.now()).millisecondsSinceEpoch);

  /// The offer that is open right now, or null. At most one is ever open: a
  /// returning customer's offer comes first, then the exit offer, then the
  /// nudge.
  static LimitedOfferKind? activeKind({DateTime? now}) {
    for (final kind in const [
      LimitedOfferKind.comeback,
      LimitedOfferKind.exit,
      LimitedOfferKind.nudge,
    ]) {
      if (isActive(kind, now: now)) return kind;
    }
    return null;
  }

  /// Opens [kind]'s window now. Does nothing if it was opened before, so a
  /// deadline can never be pushed back. [forExpiry] ties a comeback offer to
  /// the pass whose end triggered it.
  static Future<void> start(LimitedOfferKind kind,
      {DateTime? now, DateTime? forExpiry}) async {
    await load();
    if (wasShown(kind)) return;
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    switch (kind) {
      case LimitedOfferKind.exit:
        await DropoffOffer.start(now: now);
        return;
      case LimitedOfferKind.comeback:
        _comebackStartedAt = at;
        _comebackForExpiry = forExpiry?.millisecondsSinceEpoch;
      case LimitedOfferKind.nudge:
        _nudgeStartedAt = at;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kind == LimitedOfferKind.comeback) {
        await prefs.setInt(keyComebackStartedAt, at);
        if (_comebackForExpiry != null) {
          await prefs.setInt(keyComebackForExpiry, _comebackForExpiry!);
        }
      } else {
        await prefs.setInt(keyNudgeStartedAt, at);
      }
    } catch (_) {
      // Kept in memory for this session.
    }
  }

  /// The latest moment any offer was opened, or null if none ever was.
  static DateTime? get lastOfferAt {
    DateTime? latest;
    for (final kind in LimitedOfferKind.values) {
      final at = startedAt(kind);
      if (at != null && (latest == null || at.isAfter(latest))) latest = at;
    }
    return latest;
  }

  /// The pass end a comeback offer was already given for, if any.
  static DateTime? get comebackGivenFor => _comebackForExpiry == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_comebackForExpiry!);

  /// The offer to put in front of the user now without them asking for it, or
  /// null. Comeback beats nudge; both obey the 24 hour cooldown.
  static LimitedOfferKind? nextUnpromptedOffer({
    required bool isPro,
    required DateTime now,
    required DateTime? passExpiresAt,
    required bool hadPass,
  }) {
    if (comebackEligible(
      isPro: isPro,
      now: now,
      passExpiresAt: passExpiresAt,
      comebackGivenFor: comebackGivenFor,
      lastOfferAt: lastOfferAt,
    )) {
      return LimitedOfferKind.comeback;
    }
    if (nudgeEligible(
      isPro: isPro,
      hadPass: hadPass,
      exitStartedAt: startedAt(LimitedOfferKind.exit),
      nudgeStartedAt: startedAt(LimitedOfferKind.nudge),
      now: now,
      lastOfferAt: lastOfferAt,
    )) {
      return LimitedOfferKind.nudge;
    }
    return null;
  }

  // ---- Pure rules, used by the app and by tests ---------------------------

  /// Time left in a window that opened at [startedAtMs]. A clock set back
  /// before the start must not extend it.
  static Duration remainingAt(int? startedAtMs, Duration window, int nowMs) {
    if (startedAtMs == null) return Duration.zero;
    final left = startedAtMs + window.inMilliseconds - nowMs;
    if (left > window.inMilliseconds) return Duration.zero;
    return left > 0 ? Duration(milliseconds: left) : Duration.zero;
  }

  static bool _cooledDown(DateTime? lastOfferAt, DateTime now) =>
      lastOfferAt == null || now.difference(lastOfferAt) >= cooldown;

  /// A returning customer: their pass ended, they are not Pro now, they were
  /// never given a comeback offer for this pass, and it ended recently.
  static bool comebackEligible({
    required bool isPro,
    required DateTime now,
    required DateTime? passExpiresAt,
    required DateTime? comebackGivenFor,
    required DateTime? lastOfferAt,
  }) {
    if (isPro || passExpiresAt == null) return false;
    if (now.isBefore(passExpiresAt)) return false;
    if (now.difference(passExpiresAt) > comebackGiveUp) return false;
    if (comebackGivenFor != null &&
        comebackGivenFor.millisecondsSinceEpoch ==
            passExpiresAt.millisecondsSinceEpoch) {
      return false;
    }
    return _cooledDown(lastOfferAt, now);
  }

  /// A free user who never bought: the exit offer was shown at least 3 days
  /// ago (and not more than 30), they bought nothing, and the nudge was never
  /// shown. People who bought a pass get the comeback offer instead.
  static bool nudgeEligible({
    required bool isPro,
    required bool hadPass,
    required DateTime? exitStartedAt,
    required DateTime? nudgeStartedAt,
    required DateTime now,
    required DateTime? lastOfferAt,
  }) {
    if (isPro || hadPass) return false;
    if (exitStartedAt == null || nudgeStartedAt != null) return false;
    final since = now.difference(exitStartedAt);
    if (since < nudgeDelay || since > nudgeGiveUp) return false;
    return _cooledDown(lastOfferAt, now);
  }
}
