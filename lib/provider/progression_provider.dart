import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/streak_reminder.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

enum ActionType {
  dailyOpen,
  download,
  apply,
  favorite,
  share,
  rewardedAd,
  rateApp,
  shareApp,
  followX,
}

class ProgressionProvider extends ChangeNotifier {
  static const String keyProgressionData = "local_progression_v2";
  static const String followXUrl = "https://x.com/4XDesigns";
  static const int followXReward = 20;

  ProgressionModel? _progression;
  ProgressionModel? get progression => _progression;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Purely local fetch.
  Future<void> fetchProgression() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString(keyProgressionData);

      if (localData != null) {
        _progression = ProgressionModel.fromJson(json.decode(localData));
      } else {
        _progression = ProgressionModel(
          lastActiveDate: DateTime.now().subtract(const Duration(days: 1)),
          lastCheckInDate: DateTime.now().subtract(const Duration(days: 1)),
          lastAdViewDate: DateTime.now().subtract(const Duration(days: 1)),
        );
      }

      _checkDailyReset();
      _rescheduleReminder();
      notifyListeners();
    } catch (e) {
      logger.e("Error fetching progression: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checks if a new day has started.
  Future<void> _checkDailyReset() async {
    if (_progression == null) return;

    final now = DateTime.now();
    final lastActive = _progression!.lastActiveDate;
    final lastAd = _progression!.lastAdViewDate;

    bool needsUpdate = false;

    if (!_isSameDay(now, lastActive)) {
      _progression!.lastActiveDate = now;
      needsUpdate = true;
    }

    // Streak advances on check-in; here we only detect missed days.
    final p = _progression!;
    final missedDays = _daysBetween(p.lastCheckInDate, now) - 1;
    if (p.currentStreak > 0 && missedDays > 0) {
      if (missedDays == 1 && p.streakFreezes > 0) {
        p.streakFreezes -= 1;
        p.lastCheckInDate = now.subtract(const Duration(days: 1));
        ToastWidget.showToast("❄️ Streak freeze used — your streak is safe!");
      } else {
        p.currentStreak = 0;
      }
      needsUpdate = true;
    }

    final refill = p.lastFreezeRefill;
    if (refill == null || _daysBetween(refill, now) >= 7) {
      p.streakFreezes = 1;
      p.lastFreezeRefill = now;
      needsUpdate = true;
    }

    if (!_isSameDay(now, lastAd)) {
      _progression!.dailyAdViews = 0;
      _progression!.dailyDownloads = 0;
      _progression!.dailyApplies = 0;
      _progression!.dailyShares = 0; // Reset daily shares
      _progression!.lastAdViewDate = now;
      needsUpdate = true;
    }

    if (needsUpdate) {
      await _persistLocal();
    }
  }

  bool isCheckedInToday() {
    if (_progression == null) return false;
    return _isSameDay(DateTime.now(), _progression!.lastCheckInDate);
  }

  /// Today's task: set or save at least one wallpaper (Pro members skip it).
  bool get dailyTaskDone {
    final p = _progression;
    if (p == null) return false;
    return UserProfile.plusMember || p.dailyDownloads + p.dailyApplies >= 1;
  }

  /// Day within the current 7-day cycle that today's check-in counts as (1-7).
  int get checkInDayOfCycle {
    final streak = _progression?.currentStreak ?? 0;
    final next = isCheckedInToday() ? streak : streak + 1;
    return ((next - 1) % 7) + 1;
  }

  /// Reward for today's check-in grows through the week: +1 … +7.
  int get todayCheckInReward => checkInDayOfCycle;

  int get streakFreezes => _progression?.streakFreezes ?? 0;

  bool get followedX =>
      _progression?.completedMilestones.contains('followed_x') ?? false;

  Future<void> manualCheckIn() async {
    if (_progression == null || isCheckedInToday() || !dailyTaskDone) return;
    final p = _progression!;
    final now = DateTime.now();

    p.currentStreak =
        _isYesterday(p.lastCheckInDate, now) ? p.currentStreak + 1 : 1;
    if (p.currentStreak > p.longestStreak) p.longestStreak = p.currentStreak;
    p.lastCheckInDate = now;

    _grantDiamonds(((p.currentStreak - 1) % 7) + 1,
        "Day ${((p.currentStreak - 1) % 7) + 1} Check-in",
        isCredit: true);
    _checkMilestones();
    await _persistLocal();
    _rescheduleReminder();
  }

  void _rescheduleReminder() {
    if (UserProfile.plusMember) {
      StreakReminder.cancel();
      return;
    }
    StreakReminder.schedule(
      checkedInToday: isCheckedInToday(),
      currentStreak: _progression?.currentStreak ?? 0,
    );
  }

  void _checkMilestones() {
    if (_progression == null) return;
    final streak = _progression!.currentStreak;
    final milestones = [7, 14, 30, 60, 90];
    for (int milestone in milestones) {
      final milestoneKey = "streak_$milestone";
      if (streak >= milestone &&
          !_progression!.completedMilestones.contains(milestoneKey)) {
        _progression!.completedMilestones.add(milestoneKey);
        _grantDiamonds(milestone * 10, "$milestone Day Streak Bonus!",
            isCredit: true);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isYesterday(DateTime last, DateTime current) {
    final yesterday = current.subtract(const Duration(days: 1));
    return _isSameDay(last, yesterday);
  }

  int _daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  Future<void> trackAction(ActionType type) async {
    if (_progression == null || UserProfile.plusMember) return;
    int reward = 0;
    String reason = "";

    switch (type) {
      case ActionType.apply:
        _progression!.dailyApplies += 1;
        if (_progression!.dailyApplies <= 2) {
          reward = 1;
          reason = "Wallpaper Applied";
        }
        break;
      case ActionType.download:
        _progression!.dailyDownloads += 1;
        if (_progression!.dailyDownloads <= 2) {
          reward = 1;
          reason = "Wallpaper Saved";
        }
        break;
      case ActionType.share:
        reward = 1;
        reason = "Wallpaper Shared";
        break;
      case ActionType.rewardedAd:
        _progression!.dailyAdViews += 1;
        if (_progression!.dailyAdViews <= 5) {
          reward = 10;
        } else if (_progression!.dailyAdViews <= 10) {
          reward = 5;
        }
        reason = "Ad Reward";
        break;
      case ActionType.rateApp:
        // Rewarding ratings violates Google Play policy; no diamonds here.
        break;
      case ActionType.followX:
        if (!_progression!.completedMilestones.contains('followed_x')) {
          _progression!.completedMilestones.add('followed_x');
          reward = followXReward;
          reason = "Followed us on X";
        }
        break;
      case ActionType.shareApp:
        _progression!.dailyShares += 1;
        if (_progression!.dailyShares <= 2) {
          reward = 5;
          reason = "App Shared";
        } else {
          ToastWidget.showToast(
              "You've reached today's sharing reward limit. Come back tomorrow to earn more Diamonds.");
        }
        break;
      default:
        break;
    }

    if (reward > 0) {
      _grantDiamonds(reward, reason, isCredit: true);
    }
    await _persistLocal();
  }

  void _grantDiamonds(int amount, String reason, {required bool isCredit}) {
    if (_progression == null) return;

    if (isCredit) {
      _progression!.diamondsBalance += amount;
      _progression!.lifetimeDiamondsEarned += amount;
    } else {
      _progression!.diamondsBalance -= amount;
    }

    // Add to history
    _progression!.transactionHistory.insert(
        0,
        RewardTransaction(
          timestamp: DateTime.now(),
          reason: reason,
          amount: amount,
          isCredit: isCredit,
        ));

    // Keep history manageable (last 50)
    if (_progression!.transactionHistory.length > 50) {
      _progression!.transactionHistory =
          _progression!.transactionHistory.sublist(0, 50);
    }

    if (isCredit) ToastWidget.showToast("+$amount 💎 $reason");
    notifyListeners();
  }

  Future<bool> redeemCollection(String collectionId, int cost) async {
    if (_progression == null || _progression!.diamondsBalance < cost)
      return false;

    if (!_progression!.redeemedCollections.contains("col_$collectionId")) {
      _progression!.redeemedCollections.add("col_$collectionId");
      _grantDiamonds(cost, "Unlocked Collection", isCredit: false);
      await _persistLocal();
      return true;
    }
    return false;
  }

  Future<void> unlockCollectionIAP(String collectionId) async {
    if (_progression == null) return;
    if (!_progression!.redeemedCollections.contains("col_$collectionId")) {
      _progression!.redeemedCollections.add("col_$collectionId");
      await _persistLocal();
      notifyListeners();
    }
  }

  Future<bool> redeemWallpaper(String wallId, int cost) async {
    if (_progression == null || _progression!.diamondsBalance < cost)
      return false;

    if (!_progression!.redeemedCollections.contains("wall_$wallId")) {
      _progression!.redeemedCollections.add("wall_$wallId");
      _grantDiamonds(cost, "Unlocked Wallpaper", isCredit: false);
      await _persistLocal();
      return true;
    }
    return false;
  }

  bool isWallpaperUnlocked(String wallId) {
    return _progression?.redeemedCollections.contains("wall_$wallId") ?? false;
  }

  Future<bool> redeemLiveWallpaper(String wallId, int cost) async {
    if (_progression == null || _progression!.diamondsBalance < cost)
      return false;

    if (!_progression!.redeemedCollections.contains("live_$wallId")) {
      _progression!.redeemedCollections.add("live_$wallId");
      _grantDiamonds(cost, "Unlocked Video Wallpaper", isCredit: false);
      await _persistLocal();
      return true;
    }
    return false;
  }

  bool isLiveWallpaperUnlocked(String wallId) {
    return _progression?.redeemedCollections.contains("live_$wallId") ?? false;
  }

  bool isCollectionUnlocked(String collectionId) {
    return _progression?.redeemedCollections.contains("col_$collectionId") ??
        false;
  }

  Future<bool> deductDiamonds(int amount, String reason) async {
    if (_progression == null || _progression!.diamondsBalance < amount)
      return false;
    _grantDiamonds(amount, reason, isCredit: false);
    await _persistLocal();
    return true;
  }

  Future<void> clearUnlockedCollections() async {
    if (_progression == null) return;
    _progression!.redeemedCollections.clear();
    await _persistLocal();
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    if (_progression == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          keyProgressionData, json.encode(_progression!.toJson()));
    } catch (e) {
      logger.e("Local persist error: $e");
    }
  }
}
