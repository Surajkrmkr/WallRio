import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/oauth/login_page.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class FavouritePage extends StatelessWidget {
  const FavouritePage({super.key});

  void _onLongPressHandler(BuildContext context, dynamic model) {
    CNBottomSheet.show(
        context: context,
        enableDrag: true,
        isScrollControlled: true,
        isDismissible: true,
        showDragHandle: Platform.isIOS,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => ImageBottomSheet(wallModel: model));
  }

  void _onTapHandler(BuildContext context, dynamic model) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FullImage(wallModel: model)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return CustomScrollView(
      primary: false,
      slivers: [
        const SliverAppBarWidget(
            showLogo: false,
            showSearchBtn: true,
            text: "Favourites",
            secondaryText: "",
            userProfileIconRight: false,
            showUserProfileIcon: true),
        if (!authProvider.isLoggedIn)
          _buildGuestUI(context)
        else
          _buildListUI(context)
      ],
    );
  }

  Widget _buildGuestUI(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: bgDarkAccentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: bgDarkAccentColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Sync Your Favorites",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Sign in to sync your favorite wallpapers across all your devices and back them up securely.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: (isDarkMode ? Colors.white : Colors.black)
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    backgroundColor: bgDarkAccentColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: bgDarkAccentColor.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    "SIGN IN TO SYNC",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<List<dynamic>> _buildItemList(List<Walls> walls, int columnsCount) {
    final allGridItems = <dynamic>[];
    int wallCounter = 0;

    for (int i = 0; i < walls.length; i++) {
      allGridItems.add(walls[i]);
      wallCounter++;

      if (!UserProfile.plusMember && wallCounter == 6 && (i + 1) < walls.length) {
        allGridItems.add('AD_TILE');
        wallCounter = 0;
      }
    }

    final rows = <List<dynamic>>[];
    for (int i = 0; i < allGridItems.length; i += columnsCount) {
      final end = (i + columnsCount).clamp(0, allGridItems.length);
      rows.add(allGridItems.sublist(i, end));
    }
    return rows;
  }

  List<dynamic> _buildFeedItems(List<Walls> walls, int columnsCount) {
    final rows = _buildItemList(walls, columnsCount);
    final feed = <dynamic>[];
    for (int i = 0; i < rows.length; i++) {
      feed.add(rows[i]);
      if (!UserProfile.plusMember && (i + 1) % 4 == 0 && (i + 1) < rows.length) {
        feed.add('INLINE_BANNER_AD');
      }
    }
    return feed;
  }

  Widget _buildListUI(BuildContext context) {
    return Consumer<FavouriteProvider>(builder: (context, provider, _) {
      final int columnsCount = ResponsiveHelper.getGridCrossAxisCount(context);
      if (provider.isLoading) {
        return SliverPadding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
            sliver: SliverGrid.count(
                crossAxisCount: columnsCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.55,
                children: List.generate(
                    columnsCount * 3,
                    (index) => const ShimmerWidget(
                          height: 100,
                          width: double.infinity,
                          radius: 25,
                        ))));
      }
      List<Walls> walls = provider.wallList;
      if (walls.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Lottie.asset('assets/lottie/empty.json',
                width: MediaQuery.of(context).size.width * 0.7),
          ),
        );
      }
      walls = walls.reversed.toList();
      final feedItems = _buildFeedItems(walls, columnsCount);

      return SliverPadding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: feedItems.length,
            (context, index) {
              final item = feedItems[index];
              if (item == 'INLINE_BANNER_AD') {
                return const InlineBannerAdWidget(
                  screenName: 'FavouritePage',
                  placementName: 'GridChunkBanner',
                );
              }
              final rowItems = item as List<dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < columnsCount; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: i < rowItems.length
                            ? AspectRatio(
                                aspectRatio: 0.55,
                                child: rowItems[i] is Walls
                                    ? Hero(
                                        tag: (rowItems[i] as Walls).url,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              CNImage(imageUrl: (rowItems[i] as Walls).thumbnail),
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _onTapHandler(context, rowItems[i] as Walls),
                                                  onLongPress: () => _onLongPressHandler(context, rowItems[i] as Walls),
                                                  splashColor: blackColor.withValues(alpha: 0.3),
                                                ),
                                              ),
                                              _buildImgDetailsUI(context, rowItems[i] as Walls),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const SponsoredAdCard(),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Align _buildImgDetailsUI(BuildContext context, Walls wall) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
          padding: const EdgeInsets.only(left: 15, right: 5),
          height: 65,
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      wall.name,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: whiteColor, fontSize: 12),
                    ),
                    Text(
                      "Designed by ${wall.author}",
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: whiteColor, fontSize: 10),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
