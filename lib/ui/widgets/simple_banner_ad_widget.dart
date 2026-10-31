import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/consent_manager.dart';

/// Centralized Banner Ad Unit IDs.
///
/// Production ad unit IDs configured per banner placement.
/// In debug/test mode, fallback or test IDs can be used if desired.
class BannerAdUnits {
  BannerAdUnits._();

  /// 1. Global Sticky Navbar Banner
  static const String navbarBanner = 'ca-app-pub-4861691653340010/7977409939';

  /// 2. Homepage Grid Banner
  static const String homepageGridBanner =
      'ca-app-pub-4861691653340010/8536832813';

  /// 3. Static Wallpaper Detail Page Banner
  static const String staticDetailBanner =
      'ca-app-pub-4861691653340010/8360553312';

  /// 4. Live Wallpaper Detail Page & Dynamic Tab Banner
  static const String liveWallpaperBanner =
      'ca-app-pub-4861691653340010/3317099877';

  /// 5. Desktop Wallpaper Detail + Desktop Page Banner
  static const String desktopWallpaperBanner =
      'ca-app-pub-4861691653340010/8689680209';

  /// 6. Categories View All Banner
  static const String categoriesViewAllBanner =
      'ca-app-pub-4861691653340010/8833150437';

  /// Fallback banner ID for iOS or unspecified placements
  static const String iosBannerDefault =
      'ca-app-pub-4861691653340010/2292486372';

  static String resolveAdUnitId(String placementId) {
    if (Platform.isIOS) {
      return iosBannerDefault;
    }
    return placementId;
  }
}

/// Gives a [State] its own [BannerAd], loaded once when the widget mounts and
/// disposed with it — the per-widget model 2.0.2 used. There is no shared
/// preload queue: banners are only requested for slots that are actually
/// built, which keeps the show rate (and therefore eCPM) up.
///
/// If UMP consent isn't resolved yet when the widget mounts, the load waits
/// for [ConsentManager] to report that ads can be requested.
mixin BannerAdLoader<T extends StatefulWidget> on State<T> {
  BannerAd? bannerAd;
  bool isBannerLoaded = false;

  AdSize get bannerAdSize;
  String get bannerAdUnitId => BannerAdUnits.homepageGridBanner;

  void initBannerAd() {
    if (UserProfile.plusMember) return;
    ConsentManager.instance.addListener(_loadBannerAd);
    _loadBannerAd();
  }

  void disposeBannerAd() {
    ConsentManager.instance.removeListener(_loadBannerAd);
    bannerAd?.dispose();
    bannerAd = null;
  }

  void _loadBannerAd() {
    if (!mounted ||
        bannerAd != null ||
        UserProfile.plusMember ||
        !ConsentManager.instance.canRequestAds) {
      return;
    }

    bannerAd = BannerAd(
      adUnitId: BannerAdUnits.resolveAdUnitId(bannerAdUnitId),
      size: bannerAdSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('[BannerAd] Failed to load: ${error.message}');
          }
          ad.dispose();
          bannerAd = null;
          if (mounted) setState(() => isBannerLoaded = false);
        },
      ),
    )..load();
  }
}

/// Simple, direct banner ad widget.
///
/// Direct Google Mobile Ads implementation:
/// - Create BannerAd in initState
/// - Load BannerAd
/// - If loaded, render AdWidget
/// - If loading, failed, or no fill, render nothing (no placeholders or reserved space)
/// - Dispose BannerAd in dispose()
/// - Rebuild protection: setState / parent rebuilds do NOT recreate or reload the ad
/// - Plus/Premium users never create or load ads
class SimpleBannerAdWidget extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const SimpleBannerAdWidget({
    super.key,
    required this.adUnitId,
    this.adSize = AdSize.banner,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<SimpleBannerAdWidget> createState() => _SimpleBannerAdWidgetState();
}

class _SimpleBannerAdWidgetState extends State<SimpleBannerAdWidget>
    with AutomaticKeepAliveClientMixin, BannerAdLoader {
  @override
  AdSize get bannerAdSize => widget.adSize;

  @override
  String get bannerAdUnitId => widget.adUnitId;

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
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double width = bannerAd!.size.width.toDouble();
    final double height = bannerAd!.size.height.toDouble();

    return Container(
      margin: widget.margin,
      padding: widget.padding,
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
              width: width,
              height: height,
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
