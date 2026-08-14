import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';

class InlineBannerAdWidget extends StatefulWidget {
  final double verticalPadding;
  final String screenName;
  final String placementName;

  const InlineBannerAdWidget({
    super.key,
    this.verticalPadding = 18.0,
    this.screenName = 'Feed',
    this.placementName = 'InlineBanner',
  });

  @override
  State<InlineBannerAdWidget> createState() => _InlineBannerAdWidgetState();
}

class _InlineBannerAdWidgetState extends State<InlineBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    if (!UserProfile.plusMember) {
      _acquireBannerAd();
    }
  }

  void _acquireBannerAd() {
    if (_bannerAd != null) return;

    final ad = BannerAdManager.instance.acquireBanner(
      screen: widget.screenName,
      placement: widget.placementName,
    );

    setState(() {
      _bannerAd = ad;
      _isAdFailed = (ad == null);
    });
  }

  @override
  void dispose() {
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
    if (UserProfile.plusMember || _isAdFailed || _bannerAd == null) {
      return const IgnorePointer(child: SizedBox.shrink());
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final adWidth = _bannerAd!.size.width.toDouble();
    final adHeight = _bannerAd!.size.height.toDouble().clamp(48.0, 60.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
      child: Center(
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
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
    );
  }
}
