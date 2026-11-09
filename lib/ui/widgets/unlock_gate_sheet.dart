import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/app_theme_tokens.dart';
import 'package:wallrio/services/economy.dart';
import 'package:wallrio/services/theme_data.dart';
import 'package:wallrio/ui/onboarding/screens/onboarding_screen4.dart';
import 'package:wallrio/ui/views/rewards_hub_page.dart';
import 'package:wallrio/ui/widgets/glass_sheet_background.dart';
import 'package:wallrio/ui/widgets/toast_widget.dart';

/// The one place a free user unlocks a Pro, desktop or live wallpaper.
///
/// Three ways in, always the same rules ([Economy]):
///  * spend Diamonds,
///  * watch rewarded ads (each pays Diamonds; the wallpaper unlocks by itself
///    as soon as the balance covers the cost, with no second reward),
///  * go Pro.
///
/// An unlock is remembered per wallpaper, so reopening it never charges again.
/// The sheet closes itself before [onUnlocked] runs.
Future<void> showUnlockGate(
  BuildContext context, {
  required UnlockKind kind,
  required int itemId,
  required VoidCallback onUnlocked,
  String? title,
  String? imageUrl,
}) {
  final progression = Provider.of<ProgressionProvider>(context, listen: false);
  final ads = Provider.of<AdsProvider>(context, listen: false);
  return CNBottomSheet.show(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: Platform.isIOS,
    builder: (sheetContext) => _UnlockGateSheet(
      hostContext: context,
      progression: progression,
      ads: ads,
      kind: kind,
      itemId: itemId,
      onUnlocked: onUnlocked,
      title: title,
      imageUrl: imageUrl,
    ),
  );
}

class _UnlockGateSheet extends StatefulWidget {
  final BuildContext hostContext;
  final ProgressionProvider progression;
  final AdsProvider ads;
  final UnlockKind kind;
  final int itemId;
  final VoidCallback onUnlocked;
  final String? title;
  final String? imageUrl;

  const _UnlockGateSheet({
    required this.hostContext,
    required this.progression,
    required this.ads,
    required this.kind,
    required this.itemId,
    required this.onUnlocked,
    this.title,
    this.imageUrl,
  });

  @override
  State<_UnlockGateSheet> createState() => _UnlockGateSheetState();
}

class _UnlockGateSheetState extends State<_UnlockGateSheet> {
  static const Color _gold = Color(0xFFE8A33D);
  bool _busy = false;
  late final int _adsNeededAtOpen =
      widget.progression.adsNeededFor(widget.kind) ?? 0;

  int get _cost => Economy.costFor(widget.kind);

  String get _kindLabel {
    switch (widget.kind) {
      case UnlockKind.pro:
        return 'Pro wallpaper';
      case UnlockKind.desktop:
        return 'Desktop wallpaper';
      case UnlockKind.live:
        return 'Live wallpaper';
    }
  }

  IconData get _kindIcon {
    switch (widget.kind) {
      case UnlockKind.pro:
        return Icons.wallpaper_rounded;
      case UnlockKind.desktop:
        return Icons.laptop_mac_rounded;
      case UnlockKind.live:
        return Icons.motion_photos_on_rounded;
    }
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await widget.progression.unlockWithDiamonds(
      widget.kind,
      widget.itemId,
    );
    if (!mounted) return;
    if (ok) {
      ToastWidget.showToast('Unlocked! 💎');
      Navigator.of(context).pop();
      widget.onUnlocked();
    } else {
      setState(() => _busy = false);
      ToastWidget.showToast('Not enough Diamonds yet.');
    }
  }

  void _watchAd() {
    if (_busy || widget.ads.isRewardedAdLoading) return;
    // The loader pays the Diamonds and only calls back once the reward was
    // actually earned. If that covers the cost, unlock straight away.
    widget.ads.loadRewardedAd(
      widget.hostContext,
      popOnDismiss: false,
      onRewarded: () {
        if (!mounted) return;
        if (widget.progression.diamondsBalance >= _cost) _unlock();
      },
    );
  }

  void _goPro() {
    final host = widget.hostContext;
    Navigator.of(context).pop();
    if (!host.mounted) return;
    Navigator.push(
      host,
      MaterialPageRoute(
        builder: (context) =>
            OnboardingScreen4(onComplete: () => Navigator.pop(context)),
      ),
    );
  }

  void _openRewardsHub() {
    final host = widget.hostContext;
    Navigator.of(context).pop();
    if (!host.mounted) return;
    Navigator.push(
      host,
      MaterialPageRoute(builder: (context) => const RewardsHubPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? bgDark2Color : Colors.white;

    return ListenableBuilder(
      listenable: Listenable.merge([widget.progression, widget.ads]),
      builder: (context, _) {
        final balance = widget.progression.diamondsBalance;
        final canAfford = balance >= _cost;
        final adsNeeded = widget.progression.adsNeededFor(widget.kind);
        final adsLeftToday = adsNeeded != null;
        final nextReward = Economy.adReward(widget.progression.dailyAdViews + 1);
        final adsRemainingToday =
            Economy.maxAdsPerDay - widget.progression.dailyAdViews;
        final loadingAd = widget.ads.isRewardedAdLoading;
        final missing = (_cost - balance).clamp(0, _cost);

        final total = _adsNeededAtOpen < 1 ? 1 : _adsNeededAtOpen;
        final done = adsNeeded == null
            ? 0
            : (_adsNeededAtOpen - adsNeeded).clamp(0, total);

        // Quickest route gets the big button: Diamonds if affordable, else an
        // ad, else Pro. The other two become small tiles.
        final primary = canAfford
            ? _Route.diamonds
            : (adsLeftToday ? _Route.ad : _Route.pro);

        final routes = <_Route, _RouteInfo>{
          _Route.ad: _RouteInfo(
            icon: Icons.play_circle_rounded,
            label: adsLeftToday
                ? (adsNeeded > 1 ? 'Watch $adsNeeded ads' : 'Watch an ad')
                : 'Ads used up',
            hint: adsLeftToday
                ? (total > 1 && done > 0
                    ? 'Ad ${done + 1} of $total  ·  +$nextReward 💎'
                    : '+$nextReward 💎 each')
                : 'Back tomorrow',
            enabled: adsLeftToday,
            loading: loadingAd || (!canAfford && _busy),
            onTap: _watchAd,
          ),
          _Route.diamonds: _RouteInfo(
            icon: Icons.diamond_rounded,
            label: 'Unlock for $_cost 💎',
            hint: canAfford ? 'You have $balance 💎' : 'Need $missing more',
            enabled: canAfford,
            loading: canAfford && _busy,
            onTap: _unlock,
          ),
          _Route.pro: _RouteInfo(
            icon: Icons.workspace_premium_rounded,
            label: 'Go Pro',
            hint: 'Everything, no ads',
            enabled: true,
            loading: false,
            onTap: _goPro,
          ),
        };
        final others = _Route.values.where((r) => r != primary).toList();

        return glassSheetBackground(
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: BoxDecoration(
              color: supportsGlassSheet ? Colors.transparent : sheetColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _hero(colors),
                  const SizedBox(height: 14),
                  _meter(colors, isDark, balance, missing),
                  const SizedBox(height: 14),
                  _PrimaryButton(
                    route: primary,
                    info: routes[primary]!,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < others.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _SmallTile(
                            route: others[i],
                            info: routes[others[i]]!,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _openRewardsHub,
                    child: Text(
                      adsLeftToday
                          ? '$adsRemainingToday reward ads left today  ·  More ways to earn'
                          : 'More ways to earn Diamonds',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          tint: sheetColor,
        );
      },
    );
  }

  /// Compact title row: what is locked, no preview image.
  Widget _hero(AppSemanticColors colors) {
    final title = (widget.title == null || widget.title!.isEmpty)
        ? 'Unlock this wallpaper'
        : widget.title!;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_kindIcon, color: _gold, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 13, color: _gold),
                  const SizedBox(width: 5),
                  Text(
                    _kindLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Balance against cost: how close the user is to unlocking.
  Widget _meter(AppSemanticColors colors, bool isDark, int balance, int missing) {
    final progress = _cost == 0 ? 1.0 : (balance / _cost).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('💎', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$balance',
                  key: ValueKey(balance),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                ' / $_cost',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                missing == 0 ? 'Ready to unlock' : '$missing more to go',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: missing == 0 ? colors.accent : colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 9,
                backgroundColor: colors.accent.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(
                  missing == 0 ? _gold : colors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Route { ad, diamonds, pro }

class _RouteInfo {
  final IconData icon;
  final String label;
  final String hint;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  const _RouteInfo({
    required this.icon,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });
}

/// The recommended route: one full-width button.
class _PrimaryButton extends StatelessWidget {
  final _Route route;
  final _RouteInfo info;
  const _PrimaryButton({required this.route, required this.info});

  @override
  Widget build(BuildContext context) {
    final isPro = route == _Route.pro;
    final colors = context.appColors;
    final gradient = isPro
        ? const [Color(0xFFF3C06A), Color(0xFFE8A33D)]
        : [colors.accent, colors.accent.withValues(alpha: 0.82)];
    return Opacity(
      opacity: info.enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: (!info.enabled || info.loading)
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  info.onTap();
                },
          child: Ink(
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: info.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(info.icon, color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              info.hint,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A secondary route: compact tile, two per row.
class _SmallTile extends StatelessWidget {
  final _Route route;
  final _RouteInfo info;
  const _SmallTile({required this.route, required this.info});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = route == _Route.pro;
    final tone = isPro ? const Color(0xFFE8A33D) : colors.accent;
    return Opacity(
      opacity: info.enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (!info.enabled || info.loading)
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  info.onTap();
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: isDark ? 0.10 : 0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tone.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                info.loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tone,
                        ),
                      )
                    : Icon(info.icon, size: 22, color: tone),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        info.hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
