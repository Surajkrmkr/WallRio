import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/provider/progression_provider.dart';
import 'package:wallrio/services/consent_manager.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/ui/widgets/toast_widget.dart';

class AdsProvider extends ChangeNotifier {
  // AdMob ad units are registered per-platform, so Android and iOS use
  // separate ad unit IDs even though they share the same publisher account.
  final String rewardedId = Platform.isIOS
      ? "ca-app-pub-4861691653340010/5681635265"
      : "ca-app-pub-4861691653340010/4965253463";
  static final String interstitialId = Platform.isIOS
      ? "ca-app-pub-4861691653340010/9620880275"
      : "ca-app-pub-4861691653340010/1991520898";
  static const String keyDownloadCount = "download_count_for_interstitial";

  RewardedAd? rewardedAd;
  InterstitialAd? _interstitialAd;

  bool isRewardedAdLoading = false;
  bool _isInterstitialLoading = false;

  AdsProvider() {
    // Consent is gathered after the first frame, so it is usually not ready
    // yet here; preload as soon as UMP allows ad requests.
    ConsentManager.instance.addListener(loadInterstitialAd);
    loadInterstitialAd();
  }

  set setIsRewardedAdLoading(bool val) {
    isRewardedAdLoading = val;
    notifyListeners();
  }

  void loadInterstitialAd() {
    if (UserProfile.plusMember || !ConsentManager.instance.canRequestAds) return;
    if (_interstitialAd != null || _isInterstitialLoading) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          logger.i("InterstitialAd loaded successfully.");
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdImpression: (ad) {
              logger.i("[InterstitialTelemetry] InterstitialAd impression registered.");
            },
            onAdClicked: (ad) {
              logger.i("[InterstitialTelemetry] InterstitialAd clicked.");
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              logger.e("InterstitialAd failed to show: $error");
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Preload next
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          logger.e("InterstitialAd failed to load: $error");
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Loads a rewarded ad and shows it as soon as it is ready.
  ///
  /// [popOnDismiss] closes the route that asked for the ad (the unlock dialog)
  /// once the ad is dismissed. Pages that host the button themselves, like
  /// the Rewards Hub, pass false so they stay open.
  void loadRewardedAd(BuildContext context,
      {required Function() onRewarded, bool popOnDismiss = true}) {
    // A load can take a while; ignore repeat taps instead of stacking loads.
    if (isRewardedAdLoading) return;
    // Resolve the provider now: the page that started the ad may be gone by
    // the time the reward arrives.
    final progression =
        Provider.of<ProgressionProvider>(context, listen: false);
    // Don't show an ad that would pay nothing.
    if (!progression.adRewardAvailable) {
      ToastWidget.showToast(UserProfile.plusMember
          ? "Pro members don't need Diamonds."
          : "You've used today's reward ads. Come back tomorrow!");
      return;
    }
    if (!ConsentManager.instance.canRequestAds) {
      ToastWidget.showToast("Ads aren't ready yet. Please try again.");
      return;
    }
    setIsRewardedAdLoading = true;
    RewardedAd.load(
        adUnitId: rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            rewardedAd = ad;
            // Only a finished ad counts. Closing it early pays nothing and
            // must not run the unlock callback either.
            var earned = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdImpression: (ad) {
                logger.i("[RewardedTelemetry] RewardedAd impression registered.");
              },
              onAdClicked: (ad) {
                logger.i("[RewardedTelemetry] RewardedAd clicked.");
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                rewardedAd = null;
                setIsRewardedAdLoading = false;
                if (popOnDismiss && context.mounted) Navigator.pop(context);
                if (earned) onRewarded();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                logger.e("RewardedAd failed to show: $error");
                ad.dispose();
                rewardedAd = null;
                setIsRewardedAdLoading = false;
                ToastWidget.showToast("Couldn't show the ad. Please try again.");
              },
            );
            ad.show(onUserEarnedReward: (ad, reward) {
              earned = true;
              // One ad pays Economy.adReward Diamonds, once.
              progression.grantAdReward();
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            logger.e('RewardedAd failed to load: $error');
            setIsRewardedAdLoading = false;
            ToastWidget.showToast(
                "No ad available right now. Please try again later.");
          },
        ));
  }

  Future<void> handleSuccessfulDownload(BuildContext context) async {
    if (UserProfile.plusMember) return;

    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(keyDownloadCount) ?? 0;
    currentCount++;
    await prefs.setInt(keyDownloadCount, currentCount);

    logger.i("Wallpaper download successful. Count is now: $currentCount");

    if (currentCount >= 2) {
      await prefs.setInt(keyDownloadCount, 0); // Reset immediately

      if (_interstitialAd != null) {
        if (context.mounted) {
          _showInterstitial(context);
        }
      } else {
        logger.i("Interstitial ad is not loaded. Skipping ad show.");
        loadInterstitialAd(); // Try preloading again
      }
    }
  }

  void _showInterstitial(BuildContext context) {
    if (_interstitialAd == null || UserProfile.plusMember) {
      if (_interstitialAd != null) {
        _interstitialAd!.dispose();
        _interstitialAd = null;
      }
      return;
    }
    _interstitialAd!.show();
  }

  @override
  void dispose() {
    ConsentManager.instance.removeListener(loadInterstitialAd);
    _interstitialAd?.dispose();
    rewardedAd?.dispose();
    super.dispose();
  }
}
