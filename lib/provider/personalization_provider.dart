import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class PersonalizationProvider extends ChangeNotifier {
  final String personalizationCollection = "personalization";
  static const _iconChannel = MethodChannel('com.shadowteam.wallrio/app_icon');
  
  PersonalizationModel? _personalization;
  PersonalizationModel? get personalization => _personalization;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int _monthsSubscribed = 0;
  int get monthsSubscribed => _monthsSubscribed;

  // Unlocks Map
  // Duration in months -> List of items (icons/frames/badges)
  final Map<int, List<String>> unlocks = {
    1: ['badge_premium'],
    3: ['icon_dark'],
    6: ['icon_gold', 'badge_elite'],
    12: ['icon_diamond', 'badge_diamond'],
    24: ['badge_founder'],
  };

  bool isItemUnlocked(String itemKey) {
    // UNLOCKED FOR TESTING: All items are temporarily available.
    return true;
    
    /* Original Logic:
    if (!UserProfile.plusMember) return false;
    for (int duration in _unlocks.keys) {
      if (_monthsSubscribed >= duration && _unlocks[duration]!.contains(itemKey)) {
        return true;
      }
    }
    // Items that are unlocked instantly for premium:
    if (itemKey == 'icon_default' || itemKey == 'frame_none' || itemKey == 'badge_none') return true;
    if (itemKey == 'icon_black' || itemKey == 'badge_pro') return true; // basic premium
    if (itemKey.startsWith('frame_')) return true; // All new premium image frames
    return false;
    */
  }

  Future<void> fetchPersonalization() async {
    final email = UserProfile.email.isNotEmpty 
        ? UserProfile.email 
        : FirebaseAuth.instance.currentUser?.email ?? '';
        
    if (email.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('local_personalization_$email');
      
      if (dataStr != null) {
        _personalization = PersonalizationModel.fromJson(json.decode(dataStr));
        await _calculateSubscriptionDuration();
      } else {
        _personalization = PersonalizationModel(
          activeAppIcon: 'icon_default',
          activeBadge: UserProfile.plusMember ? 'badge_pro' : 'none',
        );
        await _calculateSubscriptionDuration();
      }
      // Migrate legacy 'default' key to 'icon_default'
      if (_personalization != null && _personalization!.activeAppIcon == 'default') {
        _personalization!.activeAppIcon = 'icon_default';
      }
      // Sync Android launcher icon with stored preference
      await _syncIconWithSystem();
    } catch (e) {
      logger.e("Error fetching personalization: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Applies the stored app icon preference to the Android system.
  /// This ensures the launcher icon stays in sync after reinstalls or updates.
  Future<void> _syncIconWithSystem() async {
    if (_personalization == null || !Platform.isAndroid) return;
    try {
      await _iconChannel.invokeMethod('setIcon', {
        'iconKey': _personalization!.activeAppIcon,
      });
    } catch (e) {
      logger.e("Error syncing icon with system: $e");
    }
  }

  Future<void> _calculateSubscriptionDuration() async {
    DateTime? start = _personalization?.subscriptionStartDate;
    if (start == null) {
      final prefs = await SharedPreferences.getInstance();
      final startStr = prefs.getString('user_subscription_start');
      if (startStr != null) {
        start = DateTime.parse(startStr);
        await updateSubscriptionStart(start);
      } else {
        _monthsSubscribed = 0;
        return;
      }
    }
    final now = DateTime.now();
    _monthsSubscribed = (now.year - start.year) * 12 + now.month - start.month;
  }

  Future<void> updateSubscriptionStart(DateTime start) async {
    if (_personalization == null) return;
    if (_personalization!.subscriptionStartDate == null) {
      _personalization!.subscriptionStartDate = start;
      await _syncWithLocal();
      _calculateSubscriptionDuration();
      notifyListeners();
    }
  }

  Future<bool> setAppIcon(String iconKey) async {
    if (!isItemUnlocked(iconKey)) {
      ToastWidget.showToast("Unlocks at a higher tier!");
      return false;
    }

    try {
      _personalization!.activeAppIcon = iconKey;
      await _syncWithLocal();
      notifyListeners();
      if (Platform.isAndroid) {
        await _iconChannel.invokeMethod('setIcon', {'iconKey': iconKey});
      }
      ToastWidget.showToast("App Icon updated!");
      return true;
    } catch (e) {
      logger.e("Failed to update app icon: $e");
      ToastWidget.showToast("Failed to update icon.");
      return false;
    }
  }

  Future<void> setProfileFrame(String frameKey) async {
    if (!isItemUnlocked(frameKey)) {
      ToastWidget.showToast("Unlocks at a higher tier!");
      return;
    }
    _personalization!.activeProfileFrame = frameKey;
    await _syncWithLocal();
    notifyListeners();
    ToastWidget.showToast("Profile Frame updated!");
  }

  Future<void> setBadge(String badgeKey) async {
    if (!isItemUnlocked(badgeKey)) {
      ToastWidget.showToast("Unlocks at a higher tier!");
      return;
    }
    _personalization!.activeBadge = badgeKey;
    await _syncWithLocal();
    notifyListeners();
    ToastWidget.showToast("Badge updated!");
  }

  Future<void> _syncWithLocal() async {
    final email = UserProfile.email;
    if (email.isEmpty || _personalization == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_personalization_$email', json.encode(_personalization!.toJson()));
    } catch (e) {
      logger.e("Error syncing personalization locally: $e");
    }
  }
}
