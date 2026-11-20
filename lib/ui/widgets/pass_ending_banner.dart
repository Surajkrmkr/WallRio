import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallrio/model/user_profile_model.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/premium/pass_lifecycle.dart';
import 'package:wallrio/services/purchase_analytics.dart';

/// A quiet strip on the home screen for the last 3 days of a pass:
/// "Your Pro ends in 2 days". It only informs. Google will not sell the same
/// pass again while it is still active, so the offer to renew comes when the
/// pass ends. The user can close it; it then stays away for the rest of the
/// day.
class PassEndingBanner extends StatefulWidget {
  const PassEndingBanner({super.key});

  @override
  State<PassEndingBanner> createState() => _PassEndingBannerState();
}

class _PassEndingBannerState extends State<PassEndingBanner> {
  static const String _keyDismissedDay = 'pass_ending_dismissed_day';
  bool _closedToday = false;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
    // The pass may be loaded or recorded after this screen is first built, and
    // the 3-day mark can arrive while the app is open.
    PassLifecycle.load();
    PassLifecycle.changes.addListener(_onChanged);
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => _onChanged());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refresh?.cancel();
    PassLifecycle.changes.removeListener(_onChanged);
    super.dispose();
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  Future<void> _loadDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_keyDismissedDay) == _today() && mounted) {
        setState(() => _closedToday = true);
      }
    } catch (_) {}
  }

  Future<void> _close() async {
    setState(() => _closedToday = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDismissedDay, _today());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final expiry = PassLifecycle.expiresAt;
    final now = DateTime.now();
    if (_closedToday ||
        !UserProfile.plusMember ||
        PassLifecycle.stageAt(expiry, now) != PassStage.endingSoon) {
      return const SizedBox.shrink();
    }
    final days = PassLifecycle.daysLeftAt(expiry!, now);
    final headline = PassLifecycle.timeLeftText(expiry, now);
    PurchaseAnalytics.reminderShown(
      surface: 'banner',
      daysLeft: days,
      productId: PassLifecycle.productId,
    );
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_bottom_rounded, color: colors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Renew when it ends and keep your Pro wallpapers.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _close,
              icon: Icon(Icons.close_rounded,
                  size: 18, color: colors.textSecondary),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }
}
