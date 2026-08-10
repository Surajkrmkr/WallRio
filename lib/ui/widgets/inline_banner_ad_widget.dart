import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';


class InlineBannerAdWidget extends StatefulWidget {
  final double verticalPadding;
  const InlineBannerAdWidget({
    super.key,
    this.verticalPadding = 18.0,
  });

  @override
  State<InlineBannerAdWidget> createState() => _InlineBannerAdWidgetState();
}

class _InlineBannerAdWidgetState extends State<InlineBannerAdWidget> {
  final String _adUnitId = Platform.isIOS
      ? 'ca-app-pub-4861691653340010/2292486372'
      : 'ca-app-pub-4861691653340010/8536832813';

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    if (!UserProfile.plusMember) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('InlineBannerAdWidget failed to load ($err)');
          ad.dispose();
          _bannerAd = null;
          if (mounted) {
            setState(() {
              _isAdFailed = true;
              _isAdLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (UserProfile.plusMember || _isAdFailed || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
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
