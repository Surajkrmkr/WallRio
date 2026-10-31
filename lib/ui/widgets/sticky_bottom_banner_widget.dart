import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/ui/widgets/simple_banner_ad_widget.dart';

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
  State<StickyBottomBannerWidget> createState() =>
      _StickyBottomBannerWidgetState();
}

class _StickyBottomBannerWidgetState extends State<StickyBottomBannerWidget>
    with BannerAdLoader {
  @override
  AdSize get bannerAdSize => AdSize.banner;

  @override
  void initState() {
    super.initState();
    initBannerAd();
  }

  @override
  void dispose() {
    disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (UserProfile.plusMember || !isBannerLoaded || bannerAd == null) {
      return const IgnorePointer(child: SizedBox.shrink());
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double adWidth = bannerAd!.size.width.toDouble();
    final double adHeight = bannerAd!.size.height.toDouble();

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
                  color:
                      Colors.black.withValues(alpha: isDarkMode ? 0.20 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
        ),
      ),
    );
  }
}
