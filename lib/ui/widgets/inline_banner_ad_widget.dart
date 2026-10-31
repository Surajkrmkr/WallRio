import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/ui/widgets/simple_banner_ad_widget.dart';

/// In-feed banner placed between grid rows. Defaults to a 300x250 MREC, the
/// format 2.0.2 used in its grids (every 3 rows).
class InlineBannerAdWidget extends StatefulWidget {
  final double verticalPadding;
  final AdSize size;
  final String screenName;
  final String placementName;

  const InlineBannerAdWidget({
    super.key,
    this.verticalPadding = 18.0,
    this.size = AdSize.mediumRectangle,
    this.screenName = 'Feed',
    this.placementName = 'InlineBanner',
  });

  @override
  State<InlineBannerAdWidget> createState() => _InlineBannerAdWidgetState();
}

class _InlineBannerAdWidgetState extends State<InlineBannerAdWidget>
    with AutomaticKeepAliveClientMixin, BannerAdLoader {
  @override
  AdSize get bannerAdSize => widget.size;

  @override
  bool get wantKeepAlive => isBannerLoaded;

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
    super.build(context);
    if (UserProfile.plusMember || !isBannerLoaded || bannerAd == null) {
      return const IgnorePointer(child: SizedBox.shrink());
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final adWidth = bannerAd!.size.width.toDouble();
    final adHeight = bannerAd!.size.height.toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
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
              key: ValueKey(bannerAd.hashCode),
              ad: bannerAd!,
            ),
          ),
        ),
      ),
    );
  }
}
