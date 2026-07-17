import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/provider/progression_provider.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/model/export.dart';

class AdsProvider extends ChangeNotifier {
  final String rewardedId = "ca-app-pub-4861691653340010/4965253463";
  static const String interstitialId = "ca-app-pub-4861691653340010/1991520898";
  static const String keyDownloadCount = "download_count_for_interstitial";

  RewardedAd? rewardedAd;
  InterstitialAd? _interstitialAd;

  bool isRewardedAdLoading = false;
  bool _isInterstitialLoading = false;

  AdsProvider() {
    // Preload interstitial on startup for Free users
    loadInterstitialAd();
  }

  set setIsRewardedAdLoading(bool val) {
    isRewardedAdLoading = val;
    notifyListeners();
  }

  void loadInterstitialAd() {
    if (UserProfile.plusMember) return;
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

  void loadRewardedAd(BuildContext context, {required Function() onRewarded}) {
    setIsRewardedAdLoading = true;
    RewardedAd.load(
        adUnitId: rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            rewardedAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                Navigator.pop(context);
                onRewarded();
              },
            );
            ad.show(onUserEarnedReward: (ad, reward) {
              logger.i(reward.amount);
              // Track rewarded ad progression
              Provider.of<ProgressionProvider>(context, listen: false).trackAction(ActionType.rewardedAd);
              setIsRewardedAdLoading = false;
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            logger.e('RewardedAd failed to load: $error');
            setIsRewardedAdLoading = false;
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

    if (currentCount >= 3) {
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
    _interstitialAd?.dispose();
    rewardedAd?.dispose();
    super.dispose();
  }
}
