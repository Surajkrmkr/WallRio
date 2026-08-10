import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';

class SponsoredAdCard extends StatefulWidget {
  const SponsoredAdCard({super.key});

  @override
  State<SponsoredAdCard> createState() => _SponsoredAdCardState();
}

class _SponsoredAdCardState extends State<SponsoredAdCard> {
  NativeAd? _nativeAd;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Native advanced ad unit specified for grid tiles
  static const String _adUnitId = 'ca-app-pub-4861691653340010/6870759126';

  @override
  void initState() {
    super.initState();
    if (!UserProfile.plusMember) {
      _loadAd();
    }
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('NativeAd failed to load ($err), trying fallback...');
          ad.dispose();
          _nativeAd = null;
          _loadBannerFallback();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 18.0,
      ),
    )..load();
  }

  void _loadBannerFallback() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
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
    if (!_isAdLoaded || UserProfile.plusMember || (_nativeAd == null && _bannerAd == null)) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
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
                  ? AdWidget(
                      key: ValueKey(_nativeAd.hashCode), ad: _nativeAd!)
                  : AdWidget(
                      key: ValueKey(_bannerAd.hashCode), ad: _bannerAd!),
            ),
          ),
        ),
      ),
    );
  }
}
