import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';

class AdsWidget extends StatefulWidget {
  final double bottomPadding;
  final AdSize size;
  final bool clearNavBar;
  final String screenName;
  final String placementName;

  const AdsWidget({
    super.key,
    this.bottomPadding = 10,
    this.size = AdSize.banner,
    this.clearNavBar = true,
    this.screenName = 'General',
    this.placementName = 'AdsWidget',
  });

  @override
  State<AdsWidget> createState() => _AdsWidgetState();

  static Widget getPlusDialog(
    BuildContext context, {
    void Function()? onWatchAdClick,
    bool isExplorePlus = false,
    bool showAdButton = true,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final title = isExplorePlus ? "Explore PRO" : "Unlock Wallpaper";
    final message = isExplorePlus
        ? "Upgrade to PRO to unlock premium wallpapers, live wallpapers, collections, auto wallpaper change, and an ad-free experience."
        : "Get access to premium wallpapers by watching an ad or upgrading to PRO for an ad-free experience.";
    final showWatchAd = !isExplorePlus && showAdButton;

    final dialogBg = isDarkMode ? const Color(0xFF161822) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.5 : 0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Icon, Title, and Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.diamond_rounded,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isDarkMode ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: subtextColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (showWatchAd) ...[
                Consumer<AdsProvider>(builder: (context, provider, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: provider.isRewardedAdLoading
                          ? null
                          : (onWatchAdClick ?? () {}),
                      icon: provider.isRewardedAdLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_circle_outline_rounded, size: 20),
                      label: Text(
                        provider.isRewardedAdLoading
                            ? "Loading Ad..."
                            : "Watch Ad to Unlock",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],

              // Primary "Go PRO" Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: bgDarkAccentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _onPlusClick(context),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                  label: const Text(
                    "Go PRO",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _onPlusClick(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OnboardingScreen4(onComplete: () => Navigator.pop(context)),
      ),
    );
  }
}

class _AdsWidgetState extends State<AdsWidget>
    with AutomaticKeepAliveClientMixin {
  bool _isBannerFailed = false;
  BannerAd? bannerAd;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int _maxRetries = 2;

  @override
  bool get wantKeepAlive => bannerAd != null;

  @override
  void initState() {
    super.initState();
    if (!UserProfile.plusMember) {
      _acquireBannerAd();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (bannerAd != null) {
      BannerAdManager.instance.releaseBanner(
        bannerAd,
        screen: widget.screenName,
        placement: widget.placementName,
      );
      bannerAd = null;
    }
    super.dispose();
  }

  void _acquireBannerAd() {
    if (bannerAd != null) return;

    final ad = BannerAdManager.instance.acquireBanner(
      screen: widget.screenName,
      placement: widget.placementName,
    );

    if (mounted) {
      setState(() {
        bannerAd = ad;
        _isBannerFailed = (ad == null);
      });
    }

    if (ad == null && mounted && _retryAttempts < _maxRetries) {
      _retryAttempts++;
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && bannerAd == null && !UserProfile.plusMember) {
          _acquireBannerAd();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (UserProfile.plusMember || _isBannerFailed || bannerAd == null) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double navBarClearance = (widget.size == AdSize.banner && widget.clearNavBar) ? 80.0 : 0.0;

    final double adWidth = bannerAd!.size.width.toDouble();
    final double adHeight = bannerAd!.size.height.toDouble().clamp(48.0, 60.0);

    Widget adContent = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xDD1E1E28)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: adWidth,
          height: adHeight,
          child: AdWidget(
            key: ValueKey(bannerAd.hashCode),
            ad: bannerAd!,
          ),
        ),
      ),
    );

    final double topMargin = widget.clearNavBar ? 0 : 8.0;
    final double bottomMargin = widget.bottomPadding + navBarClearance + (widget.clearNavBar ? 0 : 16.0);

    Widget adContainer = Container(
      margin: EdgeInsets.only(
        top: topMargin,
        bottom: bottomMargin,
        left: 16,
        right: 16,
      ),
      child: Center(
        heightFactor: 1.0,
        child: adContent,
      ),
    );

    if (widget.clearNavBar) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: adContainer,
        ),
      );
    }

    return adContainer;
  }
}
