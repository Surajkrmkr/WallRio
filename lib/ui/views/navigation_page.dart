import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:wallrio/model/export.dart';
import 'package:wallrio/pages.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  Timer _timer = Timer(Duration.zero, () {});

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      _checkUserIsDisable(_timer);
      Provider.of<WallRio>(context, listen: false).getListFromAPI(context);
      if (UserProfile.plusMember) {
        Provider.of<FavouriteProvider>(context, listen: false)
            .getFavouritesFromFirebase();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 30), _checkUserIsDisable);

    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _checkUserIsDisable(Timer timer) {
    try {
      FirebaseAuth.instance.currentUser!.reload();
    } catch (error) {
      logger.e(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Navigation>(builder: (context, provider, _) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: SafeArea(
          child: PageTransitionSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (
              Widget child,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) =>
                FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
            child: pages[provider.index],
          ),
        ),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Wrap(
              children: [
                NavigationBar(
                  backgroundColor:
                      Colors.white.withOpacity(0.0), // Adjust opacity
                  destinations: [
                    NavigationDestination(
                        icon: _getSvgIcon(
                            'Explore', context, provider.index == 0),
                        label: 'Explore'),
                    NavigationDestination(
                        icon: _getSvgIcon(
                            'Categories', context, provider.index == 1),
                        label: 'Categories'),
                    NavigationDestination(
                        icon: _getSvgIcon(
                            'Collections', context, provider.index == 2),
                        label: 'Collections'),
                    NavigationDestination(
                        icon: _getSvgIcon(
                            'Favorites', context, provider.index == 3),
                        label: 'Favorites'),
                  ],
                  selectedIndex: provider.index,
                  onDestinationSelected: (value) => provider.setIndex = value,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _getSvgIcon(String name, BuildContext context, bool isSelected) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      semanticsLabel: 'Explore',
      height: 18,
      colorFilter: ColorFilter.mode(
          isSelected ? Colors.white : Theme.of(context).primaryColorLight,
          BlendMode.srcIn),
    );
  }
}
