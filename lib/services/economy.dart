/// The rules of WallRio's Diamonds economy in one place, free of Flutter and
/// storage, so the UI, the provider and the tests all read the same numbers.
///
/// Design (agreed 2026-11-05):
///  * One rewarded ad always pays [adRewardFull] Diamonds (never a second,
///    separate "unlock" reward on top).
///  * A Pro wallpaper costs one ad, desktop and live wallpapers cost two.
///  * Ads pay full value for the first [fullValueAdsPerDay] views of the day,
///    half value for the next [reducedValueAdsPerDay], then nothing.
///  * Collections are never bought with Diamonds: they stay for yearly,
///    lifetime and the one-time collection packs.
library;

enum UnlockKind { pro, desktop, live }

class Economy {
  Economy._();

  // Earning from rewarded ads.
  static const int adRewardFull = 10;
  static const int adRewardReduced = 5;
  static const int fullValueAdsPerDay = 4;
  static const int reducedValueAdsPerDay = 4;
  static const int maxAdsPerDay = fullValueAdsPerDay + reducedValueAdsPerDay;

  // Spending on a single wallpaper.
  static const int costPro = 10;
  static const int costDesktop = 20;
  static const int costLive = 20;

  /// Streak bonuses, scaled to the new costs (a 30 day streak used to pay 300).
  static const Map<int, int> streakBonus = {
    7: 30,
    14: 50,
    30: 100,
    60: 150,
    90: 200,
  };

  static int costFor(UnlockKind kind) {
    switch (kind) {
      case UnlockKind.pro:
        return costPro;
      case UnlockKind.desktop:
        return costDesktop;
      case UnlockKind.live:
        return costLive;
    }
  }

  /// Prefix used when an unlock is stored, so ids from different catalogues
  /// can never collide. `wall_` and `live_` match what was already persisted.
  static String keyPrefix(UnlockKind kind) {
    switch (kind) {
      case UnlockKind.pro:
        return 'wall_';
      case UnlockKind.desktop:
        return 'desk_';
      case UnlockKind.live:
        return 'live_';
    }
  }

  static String unlockKey(UnlockKind kind, int id) => '${keyPrefix(kind)}$id';

  /// Diamonds paid for the ad watched as view number [viewNumber] today
  /// (1-based).
  static int adReward(int viewNumber) {
    if (viewNumber < 1) return 0;
    if (viewNumber <= fullValueAdsPerDay) return adRewardFull;
    if (viewNumber <= maxAdsPerDay) return adRewardReduced;
    return 0;
  }

  /// Whether another ad would still pay anything today.
  static bool adsAvailable(int adsWatchedToday) =>
      adsWatchedToday < maxAdsPerDay;

  /// How many more ads are needed to afford [cost] from [balance], starting
  /// after [adsWatchedToday] views. Returns 0 if already affordable and null
  /// if today's cap runs out first.
  static int? adsNeeded({
    required int cost,
    required int balance,
    required int adsWatchedToday,
  }) {
    var have = balance;
    var watched = adsWatchedToday;
    var ads = 0;
    while (have < cost) {
      if (!adsAvailable(watched)) return null;
      watched += 1;
      have += adReward(watched);
      ads += 1;
    }
    return ads;
  }
}
