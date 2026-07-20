import 'dart:io';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class SliverAppBarWidget extends StatelessWidget {
  final bool showLogo;
  final bool showSearchBtn;
  final String text;
  final String secondaryText;
  final bool showBackBtn;
  final bool clearSearchedData;
  final bool centeredTitle;
  final bool showUserProfileIcon;
  final bool userProfileIconRight;
  final bool showSaleChip;
  const SliverAppBarWidget(
      {super.key,
      required this.showLogo,
      required this.text,
      this.secondaryText = '',
      required this.showSearchBtn,
      this.showBackBtn = false,
      this.clearSearchedData = false,
      this.centeredTitle = true,
      this.showUserProfileIcon = false,
      this.userProfileIconRight = true,
      this.showSaleChip = false});

  void _onLongPressHandler(BuildContext context) {
    CNBottomSheet.show(
        context: context,
        enableDrag: true,
        isScrollControlled: true,
        isDismissible: true,
        showDragHandle: Platform.isIOS,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        backgroundColor: Colors.transparent,
        builder: (context) => const UserBottomSheet());
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      snap: false,
      pinned: false,
      floating: true,
      automaticallyImplyLeading: showBackBtn,
      leadingWidth: showBackBtn || !userProfileIconRight ? 60 : 0,
      leading: Row(
        children: [
          _buildUserProfileIcon(context, userProfileIconRight),
          Offstage(
              offstage: !showBackBtn,
              child: BackBtnWidget(
                  color: Theme.of(context).primaryColorLight,
                  isActionReset: clearSearchedData))
        ],
      ),
      toolbarHeight: MediaQuery.of(context).size.height * 0.08,
      centerTitle: true,
      title: Consumer<DarkThemeProvider>(
        builder: (context, provider, _) {
          final titleWidget = secondaryText.isEmpty
              ? Text(text, style: Theme.of(context).textTheme.displayLarge)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(text, style: Theme.of(context).textTheme.displayLarge),
                    Text(
                      secondaryText,
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          color: gradientColorMap[provider.gradType]!.first),
                    ),
                  ],
                );
          Widget content;
          if (!showSaleChip) {
            content = titleWidget;
          } else {
            content = Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                titleWidget,
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildSaleChip(context),
                ),
              ],
            );
          }
          return FittedBox(fit: BoxFit.scaleDown, child: content);
        },
      ),
      actions: [
        _buildSearchIcon(context),
      ],
    );
  }

  Widget _buildSaleChip(BuildContext context) {
    return Consumer2<WallRio, SubscriptionProvider>(
      builder: (context, wallRio, subProvider, _) {
        if (subProvider.subscriptionDaysLeft.isNotEmpty) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingScreen4(
                onComplete: () => Navigator.pop(context),
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFE8401A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_offer_rounded,
                    color: whiteColor, size: 13),
                const SizedBox(width: 4),
                Text(
                  'Get PRO',
                  style: const TextStyle(
                    color: whiteColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Material's ink-splash ripple has no iOS equivalent, so it's suppressed
  // there in favor of the instant dim iOS buttons normally use.
  Widget _iosAware(BuildContext context, Widget child) {
    if (!Platform.isIOS) return child;
    return Theme(
      data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory),
      child: child,
    );
  }

  void _hapticTap(VoidCallback action) {
    if (Platform.isIOS) HapticFeedback.lightImpact();
    action();
  }

  Offstage _buildSearchIcon(BuildContext context) {
    return Offstage(
      offstage: !showSearchBtn,
      child: _iosAware(
        context,
        IconButton(
            iconSize: 30,
            onPressed: () => _hapticTap(() => Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchPage()))),
            icon: const Icon(Icons.search_rounded)),
      ),
    );
  }

  Offstage _buildUserProfileIcon(BuildContext context, bool showRight) {
    return Offstage(
      offstage: showRight,
      child: Offstage(
          offstage: !showUserProfileIcon,
          child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _iosAware(
                context,
                IconButton(
                    iconSize: 30,
                    icon: Consumer<AuthProvider>(
                      builder: (context, provider, _) {
                        return PremiumAvatar(
                          imageUrl: provider.user.photoURL ?? '',
                          radius: 18,
                          onTap: () => _hapticTap(() => _onLongPressHandler(context)),
                        );
                      },
                    ),
                    onPressed: () => _hapticTap(() => _onLongPressHandler(context))),
              ))),
    );
  }
}
