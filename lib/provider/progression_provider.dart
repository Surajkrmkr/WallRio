import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
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
}

class ProgressionProvider extends ChangeNotifier {
  static const String keyProgressionData = "local_progression_v2";
  
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
      if (_isYesterday(lastActive, now)) {
        _progression!.currentStreak += 1;
      } else {
        _progression!.currentStreak = 1;
      }
      
      if (_progression!.currentStreak > _progression!.longestStreak) {
        _progression!.longestStreak = _progression!.currentStreak;
      }
      
      _progression!.lastActiveDate = now;
      needsUpdate = true;
      
      _checkMilestones();
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

  Future<void> manualCheckIn() async {
    if (_progression == null || isCheckedInToday()) return;
    
    _progression!.lastCheckInDate = DateTime.now();
    _grantDiamonds(5, "Daily Check-in", isCredit: true);
    await _persistLocal();
  }

  void _checkMilestones() {
    if (_progression == null) return;
    final streak = _progression!.currentStreak;
    final milestones = [7, 14, 30, 60, 90];
    for (int milestone in milestones) {
      final milestoneKey = "streak_$milestone";
      if (streak >= milestone && !_progression!.completedMilestones.contains(milestoneKey)) {
        _progression!.completedMilestones.add(milestoneKey);
        _grantDiamonds(milestone * 10, "$milestone Day Streak Bonus!", isCredit: true);
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
        if (!_progression!.completedMilestones.contains('rated_5_stars')) {
          _progression!.completedMilestones.add('rated_5_stars');
          reward = 20;
          reason = "5-Star Rating Bonus";
        }
        break;
      case ActionType.shareApp:
        _progression!.dailyShares += 1;
        if (_progression!.dailyShares <= 2) {
          reward = 5;
          reason = "App Shared";
        } else {
          ToastWidget.showToast("You've reached today's sharing reward limit. Come back tomorrow to earn more Diamonds.");
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
    _progression!.transactionHistory.insert(0, RewardTransaction(
      timestamp: DateTime.now(),
      reason: reason,
      amount: amount,
      isCredit: isCredit,
    ));

    // Keep history manageable (last 50)
    if (_progression!.transactionHistory.length > 50) {
      _progression!.transactionHistory = _progression!.transactionHistory.sublist(0, 50);
    }

    if (isCredit) ToastWidget.showToast("+$amount 💎 $reason");
    notifyListeners();
  }

  Future<bool> redeemCollection(String collectionId, int cost) async {
    if (_progression == null || _progression!.diamondsBalance < cost) return false;
    
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
    if (_progression == null || _progression!.diamondsBalance < cost) return false;
    
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
    if (_progression == null || _progression!.diamondsBalance < cost) return false;

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
    return _progression?.redeemedCollections.contains("col_$collectionId") ?? false;
  }

  Future<bool> deductDiamonds(int amount, String reason) async {
    if (_progression == null || _progression!.diamondsBalance < amount) return false;
    _grantDiamonds(amount, reason, isCredit: false);
    await _persistLocal();
    return true;
  }

  Future<void> _persistLocal() async {
    if (_progression == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyProgressionData, json.encode(_progression!.toJson()));
    } catch (e) {
      logger.e("Local persist error: $e");
    }
  }
}
