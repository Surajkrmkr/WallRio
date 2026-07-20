import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class AdsWidget extends StatefulWidget {
  final double bottomPadding;
  final AdSize size;
  final bool clearNavBar;
  const AdsWidget(
      {super.key,
      this.bottomPadding = 10,
      this.size = AdSize.banner,
      this.clearNavBar = true});

  @override
  State<AdsWidget> createState() => _AdsWidgetState();

  static Widget getPlusDialog(BuildContext context,
      {void Function()? onWatchAdClick,
      bool isExplorePlus = false,
      bool showAdButton = true}) {
    final title = isExplorePlus ? "Explore Plus" : "Unlock Wallpaper";
    final message = isExplorePlus
        ? "Upgrade to Plus to unlock exclusive features and take your experience to the next level!"
        : "Get access to the wallpapers by either watching an ad or purchasing the Plus Subscription.";
    final showWatchAd = !isExplorePlus && showAdButton;

    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          if (showWatchAd)
            Consumer<AdsProvider>(builder: (context, provider, _) {
              return CupertinoDialogAction(
                onPressed:
                    provider.isRewardedAdLoading ? null : (onWatchAdClick ?? () {}),
                child: provider.isRewardedAdLoading
                    ? const CupertinoActivityIndicator()
                    : const Text("Watch AD"),
              );
            }),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => _onPlusClick(context),
            child: const Text("Go Pro"),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text("Not Now"),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(title)),
          const CloseButton()
        ],
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      actions: [
        Offstage(
          offstage: !showWatchAd,
          child: Consumer<AdsProvider>(builder: (context, provider, _) {
            return provider.isRewardedAdLoading
                ? ShimmerWidget.withWidget(
                    _getWatchAdBtnUI(onWatchAdClick ?? () {}), context)
                : _getWatchAdBtnUI(onWatchAdClick ?? () {});
          }),
        ),
        Visibility(
          visible: !showWatchAd,
          replacement: OutlinedButton.icon(
              icon: const Icon(Icons.verified),
              onPressed: () => _onPlusClick(context),
              label: const Text("Go Pro")),
          child: FilledButton.icon(
              onPressed: () => _onPlusClick(context),
              icon: const Icon(Icons.verified),
              label: const Text("Go Pro")),
        )
      ],
    );
  }

  static Widget _getWatchAdBtnUI(void Function() onWatchAdClick) {
    return FilledButton(
        onPressed: onWatchAdClick, child: const Text("Watch AD"));
  }

  static void _onPlusClick(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OnboardingScreen4(onComplete: () => Navigator.pop(context)),
        ));
  }
}

class _AdsWidgetState extends State<AdsWidget> {
  // AdMob ad units are registered per-platform, so Android and iOS use
  // separate ad unit IDs even though they share the same publisher account.
  final String _bannerId = Platform.isIOS
      ? "ca-app-pub-4861691653340010/2292486372"
      : "ca-app-pub-4861691653340010/8536832813";
  bool _isBannerLoading = false;
  bool _isBannerFailed = false;
  BannerAd? bannerAd;

  @override
  void initState() {
    if (!UserProfile.plusMember) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) loadBannerAd();
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (!UserProfile.plusMember && bannerAd != null) bannerAd!.dispose();
    super.dispose();
  }

  set setBannerLoading(bool val) => setState(() => _isBannerLoading = val);

  void loadBannerAd() {
    setBannerLoading = true;
    bannerAd = BannerAd(
      adUnitId: _bannerId,
      request: const AdRequest(),
      size: widget.size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setBannerLoading = false;
        },
        onAdFailedToLoad: (ad, err) {
          logger.i('BannerAd failed to load (usually no fill): $err');
          _isBannerFailed = true;
          setBannerLoading = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBannerLoading || UserProfile.plusMember || _isBannerFailed || bannerAd == null) {
      return Container();
    }

    // Increased padding to clear the custom floating navigation bar
    // Height: 61 (bar) + 16 (bottom margin) + 16 (safe area approx)
    final double navBarClearance = (widget.size == AdSize.banner && widget.clearNavBar) ? 85.0 : 0.0;

    Widget adContainer = Container(
      margin: EdgeInsets.only(
        bottom: widget.bottomPadding + navBarClearance,
        top: 10,
      ),
      width: bannerAd!.size.width.toDouble(),
      height: bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: bannerAd!),
    );

    if (widget.size == AdSize.banner && !widget.clearNavBar) {
      adContainer = SafeArea(
        top: false,
        child: adContainer,
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: adContainer,
    );
  }
}
