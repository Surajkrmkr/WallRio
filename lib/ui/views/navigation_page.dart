import 'dart:async';
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
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          height: provider.visible ? 80 : 0.0,
          child: Wrap(
            children: [
              NavigationBar(
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.trending_up_rounded),
                        label: 'Trending'),
                    NavigationDestination(
                        icon: Icon(Icons.grid_view_rounded), label: 'Category'),
                    NavigationDestination(
                        icon: Icon(Icons.diamond_rounded), label: 'Collection'),
                    NavigationDestination(
                        icon: Icon(Icons.favorite_rounded), label: 'Favourite')
                  ],
                  selectedIndex: provider.index,
                  onDestinationSelected: (value) => provider.setIndex = value),
            ],
          ),
        ),
      );
    });
  }
}
