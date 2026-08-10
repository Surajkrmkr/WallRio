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
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double navBarClearance = (widget.size == AdSize.banner && widget.clearNavBar) ? 80.0 : 0.0;

    final double adWidth = bannerAd!.size.width.toDouble();
    final double adHeight = bannerAd!.size.height.toDouble().clamp(48.0, 60.0);

    Widget adContent = ClipRRect(
      borderRadius: BorderRadius.circular(20),
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
              color: Colors.black.withValues(alpha: 0.12),
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
    );

    final double topMargin = widget.clearNavBar ? 0 : 8.0;
    final double bottomMargin = widget.bottomPadding + navBarClearance + (widget.clearNavBar ? 0 : 16.0);

    Widget adContainer = Container(
      margin: EdgeInsets.only(
        top: topMargin,
        bottom: bottomMargin,
        left: 16,
        right: 16,
      ),
      child: Center(
        heightFactor: 1.0,
        child: adContent,
      ),
    );

    if (widget.clearNavBar) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: adContainer,
        ),
      );
    }

    return adContainer;
  }
}
