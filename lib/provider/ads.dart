import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/provider/progression_provider.dart';
import 'package:wallrio/services/packages/export.dart';

class AdsProvider extends ChangeNotifier {
  final String rewardedId = "ca-app-pub-4861691653340010/4965253463";

  RewardedAd? rewardedAd;

  bool isRewardedAdLoading = false;

  set setIsRewardedAdLoading(bool val) {
    isRewardedAdLoading = val;
    notifyListeners();
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
}
