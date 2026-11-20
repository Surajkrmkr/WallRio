/// Rules for the one-time "passes": one payment buys 28, 84 or 365 days of
/// Pro and nothing renews.
///
/// A pass is an ordinary Google Play one-time product. Play keeps it as
/// "owned" until the app consumes it, so the purchase time plus the pass
/// length is the only record of when access ends. After that moment the app
/// consumes the purchase, which lets the user buy a pass again, and stops
/// granting Pro for it.
///
/// Android only. iOS sells its own products through RevenueCat.
class PassAccess {
  PassAccess._();

  static const String monthlyId = 'com.wallrio.monthly_28';
  static const String quarterlyId = 'com.wallrio.quaterly_84';
  static const String yearlyId = 'com.wallrio.yearly_365';

  /// The 1-year pass at the limited-time price. It is only for sale while the
  /// drop-off window is open; it grants exactly what [yearlyId] grants.
  static const String yearlyDropoffId = 'com.wallrio.yearly_365_dropoff';

  /// The 4-month pass at the second-chance price, sold only while the nudge
  /// offer window is open. It grants exactly what [quarterlyId] grants.
  static const String quarterlyNudgeId = 'com.wallrio.quaterly_84_nudge';

  /// The discounted twins. Each is sold only inside an offer window.
  static const Set<String> offerIds = {yearlyDropoffId, quarterlyNudgeId};

  /// The regular pass an offer twin undercuts, or null for any other id.
  static String? regularIdFor(String offerId) {
    if (offerId == yearlyDropoffId) return yearlyId;
    if (offerId == quarterlyNudgeId) return quarterlyId;
    return null;
  }

  static bool isOfferId(String productId) => offerIds.contains(productId);

  /// The passes the paywall sells: all three lengths.
  static const Set<String> offeredIds = {monthlyId, quarterlyId, yearlyId};

  /// Every pass the app understands. One of these that Play still reports as
  /// owned (for example restored on a new phone) is honoured while it lasts.
  static const Set<String> allIds = {
    monthlyId,
    quarterlyId,
    yearlyId,
    yearlyDropoffId,
    quarterlyNudgeId,
  };

  /// When true, new Android buyers see only one-time options (Lifetime and the
  /// passes). The subscription plans stay in Play and keep working for people
  /// who already have one; set this to false to show them again.
  static const bool passesOnly = true;

  static bool isPass(String productId) => allIds.contains(productId);

  /// Lengths that differ from the number in the product id. The mid pass keeps
  /// its original Play id (`quaterly_84`) but sells 4 months (120 days), the
  /// same length the old quarterly plan had, for the same price.
  static const Map<String, int> _lengthOverride = {
    quarterlyId: 120,
    quarterlyNudgeId: 120,
  };

  /// Length of the pass in days, read from the product id (`..._28` is 28).
  static int? days(String productId) {
    if (!isPass(productId)) return null;
    final fixed = _lengthOverride[productId];
    if (fixed != null) return fixed;
    // `..._28` is 28 days; `..._365_dropoff` is 365 days.
    final match = RegExp(r'_(\d+)(?:_|$)').firstMatch(productId);
    final n = match == null ? null : int.tryParse(match.group(1)!);
    return (n == null || n <= 0) ? null : n;
  }

  /// When access ends, or null if it cannot be worked out.
  static DateTime? expiry(String productId, DateTime? purchasedAt) {
    final length = days(productId);
    if (length == null || purchasedAt == null) return null;
    return purchasedAt.add(Duration(days: length));
  }

  /// Whether this owned purchase should still grant Pro.
  ///
  /// Anything that is not a pass is left alone (true). A pass with an unknown
  /// purchase time is also treated as active: taking away access someone paid
  /// for on a guess is worse than leaving it on.
  static bool isActive(String productId, DateTime? purchasedAt,
      {DateTime? now}) {
    if (!isPass(productId)) return true;
    final end = expiry(productId, purchasedAt);
    if (end == null) return true;
    return (now ?? DateTime.now()).isBefore(end);
  }

  /// "28-day Pro", "4-month Pro" or "1-year Pro".
  static String title(String productId) {
    final length = days(productId);
    if (length == null) return 'Pro';
    if (length >= 360) return '1-year Pro';
    if (length == 120) return '4-month Pro';
    return '$length-day Pro';
  }

  static String subtitle(String productId) => 'One payment. No auto-renew.';

  static String terms(String productId) {
    final length = days(productId);
    final span = length == null ? 'a fixed period' : '$length days';
    return 'One-time payment for $span of Pro. It does not renew, so you are '
        'never billed again. Buy again after it ends.';
  }
}
