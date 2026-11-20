/// Decides whether to keep Pro when Google Play cannot be asked.
///
/// Only ever keeps access that Play itself granted on this phone earlier, so
/// it can never give Pro to a free user. A saved expiry that is long past is
/// not kept, so an expired subscriber does not stay Pro forever offline.
class EntitlementDecision {
  EntitlementDecision._();

  /// Covers renewal lag and Play's payment grace period.
  static const Duration grace = Duration(days: 3);

  static bool keepWhenStoreUnreachable({
    required bool wasPlusMember,
    required bool grantedByPlay,
    DateTime? savedExpiry,
    DateTime? now,
  }) {
    if (!wasPlusMember || !grantedByPlay) return false;
    // Lifetime purchases and unknown expiry have no end date: keep.
    if (savedExpiry == null) return true;
    return (now ?? DateTime.now()).isBefore(savedExpiry.add(grace));
  }
}
