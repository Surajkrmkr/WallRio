import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/shimmer_widget.dart';

class SponsoredAdCard extends StatefulWidget {
  final double borderRadius;
  final String adUnitId;

  // Homepage Grid Ad Unit ID
  static const String homepageGridNativeAdUnitId =
      'ca-app-pub-4861691653340010/6870759126';
  // Default Native Ad Unit ID for other screens / carousels
  static const String defaultNativeAdUnitId =
      'ca-app-pub-4861691653340010/7683720298';

  const SponsoredAdCard({
    super.key,
    this.borderRadius = 18.0,
    this.adUnitId = defaultNativeAdUnitId,
  });

  @override
  State<SponsoredAdCard> createState() => _SponsoredAdCardState();
}

class _SponsoredAdCardState extends State<SponsoredAdCard>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _nativeAd;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive =>
      _isAdLoaded || _nativeAd != null || _bannerAd != null;

  @override
  void initState() {
    super.initState();
    if (!UserProfile.plusMember) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (UserProfile.plusMember ||
        !ConsentManager.instance.canRequestAds ||
        _isLoading ||
        _isAdLoaded ||
        _nativeAd != null ||
        _bannerAd != null) {
      return;
    }
    _isLoading = true;
    debugPrint(
        '[NativeTelemetry][LOAD_CALL] ts=${DateTime.now().toIso8601String()} '
        'type=NativeAd unitId=${widget.adUnitId} source=SponsoredAdCard.initState');
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isLoading = false;
          debugPrint('[NativeTelemetry] NativeAd Loaded');
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdImpression: (ad) {
          debugPrint('[NativeTelemetry] NativeAd Impression recorded');
        },
        onAdFailedToLoad: (ad, err) {
          _isLoading = false;
          debugPrint(
              '[NativeTelemetry] NativeAd failed to load ($err), trying fallback...');
          ad.dispose();
          _nativeAd = null;
          _loadBannerFallback();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: widget.borderRadius,
      ),
    )..load();
  }

  void _loadBannerFallback() {
    if (UserProfile.plusMember ||
        !ConsentManager.instance.canRequestAds ||
        _isLoading ||
        _isAdLoaded ||
        _bannerAd != null) {
      return;
    }
    _isLoading = true;
    // DIAGNOSTIC ONLY: fallback ad load, also independent of BannerAdManager.
    debugPrint(
        '[NativeTelemetry][LOAD_CALL] ts=${DateTime.now().toIso8601String()} '
        'type=BannerFallback unitId=${widget.adUnitId} source=SponsoredAdCard.onNativeAdFailed');
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isLoading = false;
          debugPrint('[NativeTelemetry] BannerFallback Loaded');
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdImpression: (ad) {
          debugPrint('[NativeTelemetry] BannerFallback Impression recorded');
        },
        onAdFailedToLoad: (ad, err) {
          _isLoading = false;
          debugPrint('[NativeTelemetry] BannerFallback failed to load ($err)');
          ad.dispose();
          _bannerAd = null;
          if (mounted) setState(() => _isAdLoaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!AdsConfig.enabled || UserProfile.plusMember) {
      return const IgnorePointer(child: SizedBox.shrink());
    }

    if (!_isAdLoaded || (_nativeAd == null && _bannerAd == null)) {
      return ShimmerWidget(
        height: double.infinity,
        width: double.infinity,
        radius: widget.borderRadius,
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 300,
              height: 250,
              child: _nativeAd != null
                  ? AdWidget(key: ValueKey(_nativeAd.hashCode), ad: _nativeAd!)
                  : AdWidget(key: ValueKey(_bannerAd.hashCode), ad: _bannerAd!),
            ),
          ),
        ),
      ),
    );
  }
}
