import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';

/// Sticky compact bottom banner ad positioned above the navigation bar.
class StickyBottomBannerWidget extends StatefulWidget {
  final String screenName;
  final String placementName;

  const StickyBottomBannerWidget({
    super.key,
    this.screenName = 'MainScreen',
    this.placementName = 'StickyBottomBanner',
  });

  @override
  State<StickyBottomBannerWidget> createState() => _StickyBottomBannerWidgetState();
}

class _StickyBottomBannerWidgetState extends State<StickyBottomBannerWidget> {
  BannerAd? _bannerAd;
  bool _isBannerFailed = false;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    if (!UserProfile.plusMember) {
      _acquireBanner();
    }
  }

  void _acquireBanner() {
    if (_bannerAd != null) return;

    final ad = BannerAdManager.instance.acquireBanner(
      screen: widget.screenName,
      placement: widget.placementName,
    );

    if (mounted) {
      setState(() {
        _bannerAd = ad;
        _isBannerFailed = (ad == null);
      });
    }

    if (ad == null && mounted && _retryAttempts < _maxRetries) {
      _retryAttempts++;
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && _bannerAd == null && !UserProfile.plusMember) {
          _acquireBanner();
        }
      });
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (_bannerAd != null) {
      BannerAdManager.instance.releaseBanner(
        _bannerAd,
        screen: widget.screenName,
        placement: widget.placementName,
      );
      _bannerAd = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (UserProfile.plusMember || _isBannerFailed || _bannerAd == null) {
      return const IgnorePointer(child: SizedBox.shrink());
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double adWidth = _bannerAd!.size.width.toDouble();
    final double adHeight = _bannerAd!.size.height.toDouble().clamp(50.0, 60.0);

    return Container(
      margin: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 8,
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xEE1E1E28)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.20 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              width: adWidth,
              height: adHeight,
              child: AdWidget(
                key: ValueKey(_bannerAd.hashCode),
                ad: _bannerAd!,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
